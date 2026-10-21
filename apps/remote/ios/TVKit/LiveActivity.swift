#if canImport(ActivityKit)
import ActivityKit
import Foundation

/// Live Activity / Dynamic Island while the remote is connected.
public struct TVActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var appLabel: String
        public var title: String?
        public var volume: Int?
        public var volumeMax: Int?
        public var muted: Bool
        public var connected: Bool

        public init(appLabel: String, title: String?, volume: Int?, volumeMax: Int?, muted: Bool, connected: Bool) {
            self.appLabel = appLabel
            self.title = title
            self.volume = volume
            self.volumeMax = volumeMax
            self.muted = muted
            self.connected = connected
        }
    }

    public var tvName: String

    public init(tvName: String) { self.tvName = tvName }
}
#endif
