import Foundation

/// The TV the app last selected, written by the Flutter app for the widgets,
/// controls and Siri (they run outside the app and cannot read its storage).
public struct SharedTV: Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var host: String
    public var mac: String?
    /// Client certificate and RSA key (PKCS#1) the TV knows from pairing.
    public var certificatePem: String
    public var privateKeyPem: String
}

/// An app shortcut shown in the widget (the launcher's pinned apps).
public struct SharedApp: Codable, Equatable, Hashable, Sendable {
    public var package: String
    public var label: String
    public var link: String?
}

/// Last state the app saw, so widgets and the Live Activity show something
/// sensible without connecting.
public struct SharedStatus: Codable, Equatable, Sendable {
    public var connected: Bool = false
    public var appLabel: String = ""
    public var title: String?
    public var volume: Int?
    public var volumeMax: Int?
    public var muted: Bool = false
    public var updatedAt: Date = .distantPast
}

public enum SharedStore {
    /// The App Group in the entitlements. SideStore/AltStore rename groups to
    /// "<group>.<TEAMID>" when re-signing, so the real name is looked up.
    static let baseGroup = "group.com.luiszapata.tvcontrol"

    public static let groupIdentifier: String? = {
        var candidates: [String] = []
        if let alt = Bundle.main.object(forInfoDictionaryKey: "ALTAppGroups") as? [String] { candidates += alt }
        if let team = TeamID.current { candidates.append("\(baseGroup).\(team)") }
        candidates.append(baseGroup)
        return candidates.first { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) != nil }
    }()

    static var directory: URL? {
        guard let g = groupIdentifier else { return nil }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: g)
    }

    public static var isAvailable: Bool { directory != nil }

    private static func url(_ name: String) -> URL? { directory?.appendingPathComponent(name) }

    private static func read<T: Decodable>(_ name: String, as: T.Type) -> T? {
        guard let u = url(name), let data = try? Data(contentsOf: u) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func write<T: Encodable>(_ value: T?, to name: String) {
        guard let u = url(name) else { return }
        guard let value, let data = try? JSONEncoder().encode(value) else {
            try? FileManager.default.removeItem(at: u)
            return
        }
        try? data.write(to: u, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    public static var tv: SharedTV? {
        get { read("tv.json", as: SharedTV.self) }
        set { write(newValue, to: "tv.json") }
    }

    public static var apps: [SharedApp] {
        get { read("apps.json", as: [SharedApp].self) ?? [] }
        set { write(newValue, to: "apps.json") }
    }

    public static var status: SharedStatus {
        get { read("status.json", as: SharedStatus.self) ?? SharedStatus() }
        set { write(newValue, to: "status.json") }
    }
}

/// The signing team, read from the access group of a throwaway keychain item
/// ("<TEAMID>.<bundle id>").
enum TeamID {
    static let current: String? = {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "tvkit.team-probe",
            kSecAttrService as String: "tvkit",
            kSecReturnAttributes as String: true,
        ]
        var result: CFTypeRef?
        var status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            var add = query
            add.removeValue(forKey: kSecReturnAttributes as String)
            add[kSecValueData as String] = Data()
            add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(add as CFDictionary, nil)
            status = SecItemCopyMatching(query as CFDictionary, &result)
        }
        guard status == errSecSuccess,
              let attrs = result as? [String: Any],
              let group = attrs[kSecAttrAccessGroup as String] as? String,
              let dot = group.firstIndex(of: ".") else { return nil }
        return String(group[..<dot])
    }()
}
