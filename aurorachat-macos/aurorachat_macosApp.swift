
// Point d'entrée de l'application AuroraChat pour macOS.
// Initialise le client réseau et le gestionnaire de thèmes, les injecte dans l'arbre de vues.

import SwiftUI

@main
struct aurorachat_macosApp: App {
    /// Instance unique du client AuroraChat, partagée avec toutes les vues.
    @State private var client = AuroraClient()
    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(client)
                .environment(themeManager)
                .onAppear {
                    HotkeyManager.shared.start()
                }
        }
        .defaultSize(width: 900, height: 650)

        Settings {
            SettingsView()
                .environment(client)
                .environment(themeManager)
        }
    }
}
