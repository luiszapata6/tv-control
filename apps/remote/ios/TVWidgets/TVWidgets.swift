import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

// Palette from the app (Tokens in lib/src/theme/tokens.dart).
private enum Palette {
    static let bg = Color(red: 0.043, green: 0.047, blue: 0.063)
    static let card = Color(red: 0.086, green: 0.094, blue: 0.122)
    static let ink = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let muted = Color(red: 0.6, green: 0.62, blue: 0.68)
    static let accent = Color(red: 0.44, green: 0.47, blue: 1.0)
    static let danger = Color(red: 1.0, green: 0.36, blue: 0.4)
}

@main
struct TVWidgetsBundle: WidgetBundle {
    var body: some Widget {
        RemoteWidget()
        TVLiveActivity()
        if #available(iOSApplicationExtension 18.0, *) {
            PowerControl()
            MuteControl()
            VolumeUpControl()
            VolumeDownControl()
        }
    }
}

// MARK: - Home screen widget

struct RemoteEntry: TimelineEntry {
    let date: Date
    let tvName: String?
    let status: SharedStatus
    let apps: [SharedApp]
}

struct RemoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> RemoteEntry {
        RemoteEntry(date: Date(), tvName: "Sala", status: SharedStatus(connected: true, appLabel: "YouTube"), apps: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (RemoteEntry) -> Void) {
        completion(current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RemoteEntry>) -> Void) {
        // The app reloads timelines when the TV state changes.
        completion(Timeline(entries: [current()], policy: .never))
    }

    private func current() -> RemoteEntry {
        RemoteEntry(date: Date(), tvName: SharedStore.tv?.name, status: SharedStore.status, apps: Array(SharedStore.apps.prefix(4)))
    }
}

struct RemoteWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RemoteWidget", provider: RemoteProvider()) { entry in
            RemoteWidgetView(entry: entry)
                .containerBackground(Palette.bg, for: .widget)
        }
        .configurationDisplayName("Control de la TV")
        .description("Encender, volumen y tus apps sin abrir la app.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct CircleButton<I: AppIntent>: View {
    let intent: I
    let symbol: String
    var tint: Color = Palette.ink

    var body: some View {
        Button(intent: intent) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct RemoteWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RemoteEntry

    var body: some View {
        if entry.tvName == nil {
            VStack(spacing: 6) {
                Image(systemName: "tv").font(.title2).foregroundStyle(Palette.muted)
                Text("Vincula tu TV en la app").font(.caption).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
            }
        } else if family == .systemSmall {
            VStack(alignment: .leading, spacing: 8) {
                header
                Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                    GridRow {
                        CircleButton(intent: TVPowerIntent(), symbol: "power", tint: Palette.danger)
                        CircleButton(intent: TVMuteIntent(), symbol: entry.status.muted ? "speaker.slash.fill" : "speaker.fill")
                    }
                    GridRow {
                        CircleButton(intent: TVVolumeIntent(up: false), symbol: "minus")
                        CircleButton(intent: TVVolumeIntent(up: true), symbol: "plus")
                    }
                }
            }
        } else {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    header
                    Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                        GridRow {
                            CircleButton(intent: TVPowerIntent(), symbol: "power", tint: Palette.danger)
                            CircleButton(intent: PressTVButtonIntent(.playPause), symbol: "playpause.fill")
                        }
                        GridRow {
                            CircleButton(intent: TVVolumeIntent(up: false), symbol: "minus")
                            CircleButton(intent: TVVolumeIntent(up: true), symbol: "plus")
                        }
                    }
                }
                VStack(spacing: 8) {
                    ForEach(appsToShow, id: \.package) { app in
                        Button(intent: OpenTVAppIntent(TVAppEntity(id: app.package, label: app.label, link: app.link))) {
                            Text(app.label)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                                .foregroundStyle(Palette.ink)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Palette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 120)
            }
        }
    }

    private var appsToShow: [SharedApp] {
        if !entry.apps.isEmpty { return entry.apps }
        return [
            SharedApp(package: "com.google.android.youtube.tv", label: "YouTube", link: "https://www.youtube.com"),
            SharedApp(package: "com.netflix.ninja", label: "Netflix"),
            SharedApp(package: "com.disney.disneyplus", label: "Disney+"),
        ]
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(entry.tvName ?? "")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Palette.muted)
                .lineLimit(1)
        }
    }

    private var subtitle: String {
        if let v = entry.status.volume { return entry.status.muted ? "Silenciada" : "Volumen \(v)" }
        return entry.status.appLabel.isEmpty ? "TV Control" : entry.status.appLabel
    }
}

// MARK: - Live Activity

struct TVLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TVActivityAttributes.self) { context in
            HStack(spacing: 12) {
                Image(systemName: "tv.fill").font(.title3).foregroundStyle(Palette.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.title ?? context.state.appLabel)
                        .font(.headline).foregroundStyle(Palette.ink).lineLimit(1)
                    Text(context.attributes.tvName + (context.state.connected ? "" : " · desconectada"))
                        .font(.caption).foregroundStyle(Palette.muted)
                }
                Spacer()
                HStack(spacing: 8) {
                    LiveButton(intent: TVVolumeIntent(up: false), symbol: "minus")
                    LiveButton(intent: TVMuteIntent(), symbol: context.state.muted ? "speaker.slash.fill" : "speaker.fill")
                    LiveButton(intent: TVVolumeIntent(up: true), symbol: "plus")
                }
            }
            .padding(16)
            .activityBackgroundTint(Palette.bg)
            .activitySystemActionForegroundColor(Palette.ink)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.tvName, systemImage: "tv.fill")
                        .font(.caption).foregroundStyle(Palette.muted)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let v = context.state.volume {
                        Text(context.state.muted ? "Mute" : "\(v)")
                            .font(.caption.monospacedDigit()).foregroundStyle(Palette.ink)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.title ?? context.state.appLabel)
                        .font(.headline).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        LiveButton(intent: PressTVButtonIntent(.playPause), symbol: "playpause.fill")
                        LiveButton(intent: TVVolumeIntent(up: false), symbol: "minus")
                        LiveButton(intent: TVMuteIntent(), symbol: "speaker.slash.fill")
                        LiveButton(intent: TVVolumeIntent(up: true), symbol: "plus")
                        LiveButton(intent: TVPowerIntent(), symbol: "power")
                    }
                }
            } compactLeading: {
                Image(systemName: "tv.fill").foregroundStyle(Palette.accent)
            } compactTrailing: {
                if let v = context.state.volume {
                    Text(context.state.muted ? "M" : "\(v)").font(.caption2.monospacedDigit())
                }
            } minimal: {
                Image(systemName: "tv.fill").foregroundStyle(Palette.accent)
            }
        }
    }
}

private struct LiveButton<I: AppIntent>: View {
    let intent: I
    let symbol: String

    var body: some View {
        Button(intent: intent) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 40, height: 36)
                .background(Palette.card, in: Capsule())
                .foregroundStyle(Palette.ink)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Control Center (iOS 18)

@available(iOSApplicationExtension 18.0, *)
struct PowerControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.luiszapata.tvcontrol.power") {
            ControlWidgetButton(action: TVPowerIntent()) {
                Label("TV", systemImage: "power")
            }
        }
        .displayName("Encender/apagar TV")
    }
}

@available(iOSApplicationExtension 18.0, *)
struct MuteControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.luiszapata.tvcontrol.mute") {
            ControlWidgetButton(action: TVMuteIntent()) {
                Label("Silenciar TV", systemImage: "speaker.slash.fill")
            }
        }
        .displayName("Silenciar TV")
    }
}

@available(iOSApplicationExtension 18.0, *)
struct VolumeUpControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.luiszapata.tvcontrol.volume-up") {
            ControlWidgetButton(action: TVVolumeIntent(up: true)) {
                Label("Subir volumen TV", systemImage: "speaker.plus.fill")
            }
        }
        .displayName("Subir volumen TV")
    }
}

@available(iOSApplicationExtension 18.0, *)
struct VolumeDownControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.luiszapata.tvcontrol.volume-down") {
            ControlWidgetButton(action: TVVolumeIntent(up: false)) {
                Label("Bajar volumen TV", systemImage: "speaker.minus.fill")
            }
        }
        .displayName("Bajar volumen TV")
    }
}
