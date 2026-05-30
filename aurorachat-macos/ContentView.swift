import SwiftUI

struct ContentView: View {
    @Environment(AuroraClient.self) private var client
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        Group {
            switch client.currentScreen {
            case .login:
                loginView
                    .transition(.opacity)
            case .rooms:
                RoomListView()
                    .transition(.opacity)
            case .chat:
                chatView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: client.currentScreen)
    }

    // route to the right login view based on theme
    @ViewBuilder
    private var loginView: some View {
        switch theme.currentTheme {
        case .liquidGlass:
            LiquidGlassLoginView()
        case .aqua:
            AquaLoginView()
        case .sonoma:
            LoginView()
        }
    }

    @ViewBuilder
    private var chatView: some View {
        switch theme.currentTheme {
        case .liquidGlass:
            LiquidGlassChatView()
        case .aqua:
            AquaChatView()
        case .sonoma:
            ChatView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AuroraClient())
        .environment(ThemeManager())
}
