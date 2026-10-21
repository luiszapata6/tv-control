import AppIntents

/// Siri and Shortcuts phrases ("Oye Siri, apaga la TV con TV Control").
/// Lives in the app target only: an app has exactly one provider.
struct TVShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TVSleepIntent(),
            phrases: ["Apaga la TV con \(.applicationName)"],
            shortTitle: "Apagar",
            systemImageName: "power"
        )
        AppShortcut(
            intent: TVWakeIntent(),
            phrases: [
                "Enciende la TV con \(.applicationName)",
                "Prende la TV con \(.applicationName)",
            ],
            shortTitle: "Encender",
            systemImageName: "power"
        )
        AppShortcut(
            intent: OpenTVAppIntent(),
            phrases: [
                "Abre \(\.$app) en la TV con \(.applicationName)",
                "Pon \(\.$app) en \(.applicationName)",
            ],
            shortTitle: "Abrir app en la TV",
            systemImageName: "play.tv"
        )
        AppShortcut(
            intent: TVMuteIntent(),
            phrases: ["Silencia la TV con \(.applicationName)"],
            shortTitle: "Silenciar",
            systemImageName: "speaker.slash"
        )
        AppShortcut(
            intent: TVVolumeIntent(),
            phrases: ["Cambia el volumen de la TV con \(.applicationName)"],
            shortTitle: "Volumen",
            systemImageName: "speaker.wave.2"
        )
        AppShortcut(
            intent: PressTVButtonIntent(),
            phrases: ["Pulsa un botón de la TV con \(.applicationName)"],
            shortTitle: "Pulsar botón",
            systemImageName: "av.remote"
        )
    }
}
