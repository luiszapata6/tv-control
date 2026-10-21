import Foundation

/// Minimal protobuf wire codec for the few Android TV Remote v2 messages the
/// widgets and Siri need. Field numbers come from remotemessage.proto (see
/// packages/atv_remote, generated from the reference implementation).
struct ProtoWriter {
    var data = Data()

    mutating func varint(_ value: UInt64) {
        var v = value
        while v >= 0x80 {
            data.append(UInt8(truncatingIfNeeded: v) | 0x80)
            v >>= 7
        }
        data.append(UInt8(v))
    }

    mutating func tag(_ field: Int, _ wire: Int) { varint(UInt64(field << 3 | wire)) }

    /// proto3 scalar: default (0) values are not written.
    mutating func int(_ field: Int, _ value: Int) {
        guard value != 0 else { return }
        tag(field, 0)
        varint(UInt64(bitPattern: Int64(value)))
    }

    mutating func string(_ field: Int, _ value: String) {
        guard !value.isEmpty else { return }
        bytes(field, Data(value.utf8))
    }

    mutating func bytes(_ field: Int, _ value: Data) {
        tag(field, 2)
        varint(UInt64(value.count))
        data.append(value)
    }

    /// Sub-messages are always written, even when empty (presence matters).
    mutating func message(_ field: Int, _ build: (inout ProtoWriter) -> Void) {
        var inner = ProtoWriter()
        build(&inner)
        bytes(field, inner.data)
    }
}

enum ProtoError: Error { case truncated, malformed }

struct ProtoReader {
    private let data: [UInt8]
    private(set) var offset = 0

    init(_ data: Data) { self.data = [UInt8](data) }

    var isAtEnd: Bool { offset >= data.count }

    mutating func varint() throws -> UInt64 {
        var result: UInt64 = 0
        var shift: UInt64 = 0
        while true {
            guard offset < data.count else { throw ProtoError.truncated }
            let byte = data[offset]
            offset += 1
            result |= UInt64(byte & 0x7F) << shift
            if byte < 0x80 { return result }
            shift += 7
            if shift > 63 { throw ProtoError.malformed }
        }
    }

    mutating func field() throws -> (number: Int, wire: Int)? {
        if isAtEnd { return nil }
        let key = try varint()
        return (Int(key >> 3), Int(key & 7))
    }

    mutating func lengthDelimited() throws -> Data {
        let n = Int(try varint())
        guard n >= 0, offset + n <= data.count else { throw ProtoError.truncated }
        defer { offset += n }
        return Data(data[offset ..< offset + n])
    }

    mutating func skip(_ wire: Int) throws {
        switch wire {
        case 0: _ = try varint()
        case 1: offset += 8
        case 2: _ = try lengthDelimited()
        case 5: offset += 4
        default: throw ProtoError.malformed
        }
        if offset > data.count { throw ProtoError.truncated }
    }

    /// First varint value of [field] in a message body, if present.
    static func int(in body: Data, field: Int) -> Int? {
        var r = ProtoReader(body)
        while let f = try? r.field() {
            if f.number == field, f.wire == 0 {
                return (try? r.varint()).map { Int(truncatingIfNeeded: $0) }
            }
            guard (try? r.skip(f.wire)) != nil else { return nil }
        }
        return nil
    }

    /// First length-delimited value of [field] in a message body.
    static func bytes(in body: Data, field: Int) -> Data? {
        var r = ProtoReader(body)
        while let f = try? r.field() {
            if f.number == field, f.wire == 2 { return try? r.lengthDelimited() }
            guard (try? r.skip(f.wire)) != nil else { return nil }
        }
        return nil
    }
}

/// Splits a byte stream into varint-length-prefixed messages.
struct MessageFramer {
    private var buffer = Data()
    static let maxMessage = 1 << 20

    mutating func append(_ chunk: Data) throws -> [Data] {
        buffer.append(chunk)
        var out: [Data] = []
        while !buffer.isEmpty {
            var r = ProtoReader(buffer)
            guard let length = try? r.varint() else { break } // incomplete prefix
            guard length <= UInt64(Self.maxMessage) else { throw ProtoError.malformed }
            let start = r.offset
            let end = start + Int(length)
            guard buffer.count >= end else { break }
            out.append(buffer.subdata(in: start ..< end))
            buffer = buffer.subdata(in: end ..< buffer.count)
        }
        return out
    }

    static func frame(_ message: Data) -> Data {
        var w = ProtoWriter()
        w.varint(UInt64(message.count))
        w.data.append(message)
        return w.data
    }
}
