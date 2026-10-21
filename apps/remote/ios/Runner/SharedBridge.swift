import ActivityKit
import Flutter
import Foundation
import WidgetKit

/// Method channel `tvcontrol/shared`: the Flutter app hands the selected TV,
/// its pinned apps and live state to the widgets, controls, Siri and the
/// Live Activity (see lib/src/services/shared_bridge.dart).
final class SharedBridge: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "tvcontrol/shared", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(SharedBridge(), channel: channel)
    }

    private var lastReload = Date.distantPast

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "isAvailable":
            result(SharedStore.isAvailable)
        case "setTv":
            guard let id = args["id"] as? String, let name = args["name"] as? String,
                  let host = args["host"] as? String, let cert = args["certificatePem"] as? String,
                  let key = args["privateKeyPem"] as? String else {
                return result(FlutterError(code: "bad_args", message: "missing fields", details: nil))
            }
            let next = SharedTV(id: id, name: name, host: host, mac: args["mac"] as? String, certificatePem: cert, privateKeyPem: key)
            if SharedStore.tv != next {
                SharedStore.tv = next
                reload(force: true)
            }
            result(SharedStore.isAvailable)
        case "clearTv":
            SharedStore.tv = nil
            SharedStore.apps = []
            SharedStore.status = SharedStatus()
            endActivity()
            reload(force: true)
            result(nil)
        case "setApps":
            let list = (args["apps"] as? [[String: Any]] ?? []).compactMap { a -> SharedApp? in
                guard let p = a["package"] as? String, let l = a["label"] as? String else { return nil }
                return SharedApp(package: p, label: l, link: a["link"] as? String)
            }
            if SharedStore.apps != list {
                SharedStore.apps = list
                reload(force: true)
            }
            result(nil)
        case "updateStatus":
            var s = SharedStatus()
            s.connected = args["connected"] as? Bool ?? false
            s.appLabel = args["appLabel"] as? String ?? ""
            s.title = args["title"] as? String
            s.volume = args["volume"] as? Int
            s.volumeMax = args["volumeMax"] as? Int
            s.muted = args["muted"] as? Bool ?? false
            s.updatedAt = Date()
            let old = SharedStore.status
            SharedStore.status = s
            let changed = old.connected != s.connected || old.appLabel != s.appLabel || old.muted != s.muted
            reload(force: changed)
            updateActivity(s)
            result(nil)
        case "setLiveActivity":
            let on = args["enabled"] as? Bool ?? false
            if on { startActivity() } else { endActivity() }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// WidgetKit budgets reloads; volume ticks only reload every few seconds.
    private func reload(force: Bool) {
        guard force || Date().timeIntervalSince(lastReload) > 5 else { return }
        lastReload = Date()
        WidgetCenter.shared.reloadAllTimelines()
        if #available(iOS 18.0, *) { ControlCenter.shared.reloadAllControls() }
    }

    // MARK: Live Activity

    private func state(_ s: SharedStatus) -> TVActivityAttributes.ContentState {
        .init(appLabel: s.appLabel.isEmpty ? "TV" : s.appLabel, title: s.title, volume: s.volume,
              volumeMax: s.volumeMax, muted: s.muted, connected: s.connected)
    }

    private func startActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, let tv = SharedStore.tv else { return }
        if !Activity<TVActivityAttributes>.activities.isEmpty { return updateActivity(SharedStore.status) }
        _ = try? Activity.request(
            attributes: TVActivityAttributes(tvName: tv.name),
            content: .init(state: state(SharedStore.status), staleDate: nil)
        )
    }

    private func updateActivity(_ s: SharedStatus) {
        let content = ActivityContent(state: state(s), staleDate: nil)
        for activity in Activity<TVActivityAttributes>.activities {
            Task { await activity.update(content) }
        }
    }

    private func endActivity() {
        for activity in Activity<TVActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
