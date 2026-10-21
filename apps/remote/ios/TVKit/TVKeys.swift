import Foundation

/// Android key codes (RemoteKeyCode in remotemessage.proto).
public enum TVKey: Int, CaseIterable, Sendable {
    case home = 3, back = 4
    case up = 19, down = 20, left = 21, right = 22, center = 23
    case volumeUp = 24, volumeDown = 25, power = 26
    case menu = 82, playPause = 85, next = 87, previous = 88
    case mute = 164
}

/// RemoteDirection: SHORT = 3.
let shortPress = 3

/// What a widget, control or shortcut asks the TV to do.
public enum TVAction: Sendable {
    case key(TVKey)
    /// Package name or URL; packages become market://launch?id=<package>.
    case open(String)

    var appLink: String? {
        guard case let .open(value) = self else { return nil }
        return TVAction.appLink(for: value)
    }

    static func appLink(for value: String) -> String {
        let v = value.trimmingCharacters(in: .whitespaces)
        if let scheme = URL(string: v)?.scheme, !scheme.isEmpty { return v }
        return "market://launch?id=\(v)"
    }
}
