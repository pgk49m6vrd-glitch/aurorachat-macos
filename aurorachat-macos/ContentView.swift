//
//  ContentView.swift
//  aurorachat-macos
//
//  Created by Clovis de Sena on 29/05/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuroraClient.self) private var client

    var body: some View {
        Group {
            switch client.currentScreen {
            case .login:
                LoginView()
                    .transition(.opacity)
            case .rooms:
                RoomListView()
                    .transition(.opacity)
            case .chat:
                ChatView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: client.currentScreen)
    }
}

#Preview {
    ContentView()
        .environment(AuroraClient())
}
