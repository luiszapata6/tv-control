import Foundation
import Network
import Security

public enum TVError: LocalizedError {
    case noTV, unreachable, notPaired, timeout, closed, protocolError

    public var errorDescription: String? {
        switch self {
        case .noTV: return "Abre TV Control y vincula tu TV primero."
        case .unreachable: return "La TV no responde. ¿Está encendida y en la misma Wi-Fi?"
        case .notPaired: return "La TV ya no reconoce este iPhone. Vuelve a vincularla en la app."
        case .timeout: return "La TV tardó demasiado en responder."
        case .closed: return "La TV cerró la conexión."
        case .protocolError: return "La TV respondió algo inesperado."
        }
    }
}

public struct TVVolume: Sendable, Equatable {
    public var level: Int
    public var max: Int
    public var muted: Bool
}

/// A short-lived command connection on the remote port (6466): handshake,
/// send, close. Mirrors packages/atv_remote/lib/src/remote.dart.
final class TVConnection: @unchecked Sendable {
    static let defaultFeatures = 615 // ping | key | ime | power | volume | app link

    private let connection: NWConnection
    private let queue = DispatchQueue(label: "com.luiszapata.tvcontrol.tvkit")
    private let requestedFeatures: Int
    private var framer = MessageFramer()
    private var agreedFeatures = 0
    private var startContinuation: CheckedContinuation<Void, Error>?
    private var started = false
    private(set) var volume: TVVolume?
    private(set) var isOn: Bool?

    init(host: String, port: UInt16 = 6466, identity: SecIdentity, features: Int = TVConnection.defaultFeatures) {
        let tls = NWProtocolTLS.Options()
        let sec = tls.securityProtocolOptions
        if let id = sec_identity_create(identity) { sec_protocol_options_set_local_identity(sec, id) }
        // The TV's certificate is self-signed; pairing, not a CA, identifies it.
        sec_protocol_options_set_verify_block(sec, { _, _, complete in complete(true) }, DispatchQueue.global())
        sec_protocol_options_set_min_tls_protocol_version(sec, .TLSv12)
        let tcp = NWProtocolTCP.Options()
        tcp.connectionTimeout = 5
        tcp.noDelay = true
        let params = NWParameters(tls: tls, tcp: tcp)
        connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: params)
        requestedFeatures = features
    }

    /// Connects and waits for remote_start (the TV accepts commands).
    func open(timeout: TimeInterval = 6) async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            queue.async {
                self.startContinuation = c
                self.connection.stateUpdateHandler = { [weak self] state in self?.onState(state) }
                self.connection.start(queue: self.queue)
                self.receive()
                self.queue.asyncAfter(deadline: .now() + timeout) { [weak self] in self?.resolveStart(TVError.timeout) }
            }
        }
    }

    func send(_ actions: [TVAction]) async throws {
        for action in actions {
            switch action {
            case let .key(key):
                try await send { w in
                    w.message(10) { k in
                        k.int(1, key.rawValue)
                        k.int(2, shortPress)
                    }
                }
            case .open:
                guard let link = action.appLink else { continue }
                try await send { w in w.message(90) { $0.string(1, link) } }
            case let .setPower(on):
                // isOn arrives with remote_start, before open() returns.
                guard isOn != on else { continue }
                try await send { w in
                    w.message(10) { k in
                        k.int(1, TVKey.power.rawValue)
                        k.int(2, shortPress)
                    }
                }
            }
        }
    }

    func close() {
        queue.async { self.connection.cancel() }
    }

    // MARK: - internals (on `queue`)

    private func onState(_ state: NWConnection.State) {
        switch state {
        case let .failed(error), let .waiting(error):
            resolveStart(Self.classify(error))
            connection.cancel()
        case .cancelled:
            resolveStart(TVError.closed)
        default:
            break
        }
    }

    static func classify(_ error: NWError) -> TVError {
        switch error {
        case .tls: return .notPaired
        case let .posix(code) where code == .ECONNRESET || code == .EPIPE: return .closed
        default: return .unreachable
        }
    }

    private func resolveStart(_ error: Error?) {
        guard let c = startContinuation else { return }
        startContinuation = nil
        if let error { c.resume(throwing: error) } else { c.resume() }
    }

    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            if let data, !data.isEmpty {
                do {
                    for message in try self.framer.append(data) { self.handle(message) }
                } catch {
                    self.resolveStart(TVError.protocolError)
                    self.connection.cancel()
                    return
                }
            }
            if let error {
                // With TLS 1.3 a refused client certificate shows up here.
                self.resolveStart(Self.classify(error))
                return
            }
            if isComplete {
                self.resolveStart(self.started ? nil : TVError.notPaired)
                return
            }
            self.receive()
        }
    }

    private func handle(_ message: Data) {
        var r = ProtoReader(message)
        while let f = try? r.field() {
            guard f.wire == 2, let body = try? r.lengthDelimited() else {
                if (try? r.skip(f.wire)) == nil { return }
                continue
            }
            switch f.number {
            case 1: // remote_configure: answer with the features both support
                agreedFeatures = requestedFeatures & (ProtoReader.int(in: body, field: 1) ?? 0)
                let agreed = agreedFeatures
                enqueue { w in
                    w.message(1) { c in
                        c.int(1, agreed)
                        c.message(2) { d in
                            d.int(3, 1)
                            d.string(4, "1")
                            d.string(5, "atvremote")
                            d.string(6, "1.0.0")
                        }
                    }
                }
            case 2: // remote_set_active
                let agreed = agreedFeatures
                enqueue { w in w.message(2) { $0.int(1, agreed) } }
            case 8: // remote_ping_request -> response echoes val1
                let v = ProtoReader.int(in: body, field: 1) ?? 0
                enqueue { w in w.message(9) { $0.int(1, v) } }
            case 40: // remote_start
                isOn = (ProtoReader.int(in: body, field: 1) ?? 0) != 0
                started = true
                resolveStart(nil)
            case 50: // remote_set_volume_level
                volume = TVVolume(
                    level: ProtoReader.int(in: body, field: 7) ?? 0,
                    max: ProtoReader.int(in: body, field: 6) ?? 0,
                    muted: (ProtoReader.int(in: body, field: 8) ?? 0) != 0
                )
            default:
                break
            }
        }
    }

    private func enqueue(_ build: (inout ProtoWriter) -> Void) {
        var w = ProtoWriter()
        build(&w)
        connection.send(content: MessageFramer.frame(w.data), completion: .contentProcessed { _ in })
    }

    private func send(_ build: (inout ProtoWriter) -> Void) async throws {
        var w = ProtoWriter()
        build(&w)
        let framed = MessageFramer.frame(w.data)
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            connection.send(content: framed, completion: .contentProcessed { error in
                if let error { c.resume(throwing: Self.classify(error)) } else { c.resume() }
            })
        }
    }
}

/// Entry point for widgets, controls and shortcuts.
public enum TVRemote {
    /// Connects to the selected TV, performs [actions] and disconnects.
    @discardableResult
    public static func perform(_ actions: [TVAction]) async throws -> TVVolume? {
        guard let tv = SharedStore.tv else { throw TVError.noTV }
        let identity = try TVIdentity.identity(for: tv)
        let connection = TVConnection(host: tv.host, identity: identity)
        defer { connection.close() }
        try await connection.open()
        try await connection.send(actions)
        // Give the TV a moment to act and report the new volume.
        try? await Task.sleep(nanoseconds: 250_000_000)
        if let v = connection.volume {
            var status = SharedStore.status
            status.volume = v.level
            status.volumeMax = v.max
            status.muted = v.muted
            status.updatedAt = Date()
            SharedStore.status = status
        }
        return connection.volume
    }
}
