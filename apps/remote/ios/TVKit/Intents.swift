import AppIntents
import Foundation

/// Buttons a widget, control or shortcut can press.
public enum TVButton: String, AppEnum {
    case power, home, back, center, up, down, left, right
    case volumeUp, volumeDown, mute, playPause, next, previous, menu

    public static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Botón")
    public static var caseDisplayRepresentations: [TVButton: DisplayRepresentation] = [
        .power: "Encender/apagar", .home: "Inicio", .back: "Atrás", .center: "OK",
        .up: "Arriba", .down: "Abajo", .left: "Izquierda", .right: "Derecha",
        .volumeUp: "Subir volumen", .volumeDown: "Bajar volumen", .mute: "Silenciar",
        .playPause: "Reproducir/pausar", .next: "Siguiente", .previous: "Anterior", .menu: "Menú",
    ]

    var key: TVKey {
        switch self {
        case .power: return .power
        case .home: return .home
        case .back: return .back
        case .center: return .center
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .volumeUp: return .volumeUp
        case .volumeDown: return .volumeDown
        case .mute: return .mute
        case .playPause: return .playPause
        case .next: return .next
        case .previous: return .previous
        case .menu: return .menu
        }
    }
}

public struct PressTVButtonIntent: AppIntent {
    public static var title: LocalizedStringResource = "Pulsar un botón de la TV"
    public static var description = IntentDescription("Envía un botón del control a tu TV.")
    public static var openAppWhenRun = false

    @Parameter(title: "Botón") public var button: TVButton

    public init() {}
    public init(_ button: TVButton) { self.button = button }

    public func perform() async throws -> some IntentResult {
        try await TVRemote.perform([.key(button.key)])
        return .result()
    }
}

public struct TVPowerIntent: AppIntent {
    public static var title: LocalizedStringResource = "Encender o apagar la TV"
    public static var openAppWhenRun = false
    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        try await TVRemote.perform([.key(.power)])
        return .result(dialog: "Listo")
    }
}

public struct TVMuteIntent: AppIntent {
    public static var title: LocalizedStringResource = "Silenciar la TV"
    public static var openAppWhenRun = false
    public init() {}

    public func perform() async throws -> some IntentResult {
        try await TVRemote.perform([.key(.mute)])
        return .result()
    }
}

public struct TVVolumeIntent: AppIntent {
    public static var title: LocalizedStringResource = "Cambiar el volumen de la TV"
    public static var openAppWhenRun = false

    @Parameter(title: "Subir", default: true) public var up: Bool
    @Parameter(title: "Pasos", default: 2, inclusiveRange: (1, 20)) public var steps: Int

    public init() {}
    public init(up: Bool, steps: Int = 2) {
        self.up = up
        self.steps = steps
    }

    public func perform() async throws -> some IntentResult {
        let key: TVKey = up ? .volumeUp : .volumeDown
        try await TVRemote.perform(Array(repeating: .key(key), count: max(1, min(steps, 20))))
        return .result()
    }
}

// MARK: - apps

public struct TVAppEntity: AppEntity, Hashable {
    public static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "App de la TV")
    public static var defaultQuery = TVAppQuery()

    public var id: String // package name
    public var label: String
    public var link: String?

    public init(id: String, label: String, link: String? = nil) {
        self.id = id
        self.label = label
        self.link = link
    }

    public var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(label)") }

    /// The launcher's pinned apps when known, else well-known TV apps.
    static var all: [TVAppEntity] {
        let shared = SharedStore.apps.map { TVAppEntity(id: $0.package, label: $0.label, link: $0.link) }
        let known = [
            TVAppEntity(id: "com.google.android.youtube.tv", label: "YouTube", link: "https://www.youtube.com"),
            TVAppEntity(id: "com.netflix.ninja", label: "Netflix"),
            TVAppEntity(id: "com.disney.disneyplus", label: "Disney+"),
            TVAppEntity(id: "com.amazon.amazonvideo.livingroom", label: "Prime Video"),
            TVAppEntity(id: "com.wbd.stream", label: "Max"),
            TVAppEntity(id: "com.spotify.tv.android", label: "Spotify"),
            TVAppEntity(id: "com.plexapp.android", label: "Plex"),
        ]
        var seen = Set<String>()
        return (shared + known).filter { seen.insert($0.id).inserted }
    }
}

public struct TVAppQuery: EntityQuery, EntityStringQuery {
    public init() {}

    public func entities(for identifiers: [String]) async throws -> [TVAppEntity] {
        let all = TVAppEntity.all
        return identifiers.compactMap { id in all.first { $0.id == id } ?? TVAppEntity(id: id, label: id) }
    }

    public func entities(matching string: String) async throws -> [TVAppEntity] {
        TVAppEntity.all.filter { $0.label.localizedCaseInsensitiveContains(string) }
    }

    public func suggestedEntities() async throws -> [TVAppEntity] { TVAppEntity.all }
}

public struct OpenTVAppIntent: AppIntent {
    public static var title: LocalizedStringResource = "Abrir una app en la TV"
    public static var openAppWhenRun = false

    @Parameter(title: "App") public var app: TVAppEntity

    public init() {}
    public init(_ app: TVAppEntity) { self.app = app }

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        try await TVRemote.perform([.open(app.link ?? app.id)])
        return .result(dialog: "Abriendo \(app.label)")
    }
}
