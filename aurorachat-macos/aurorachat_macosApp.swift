//
//  aurorachat_macosApp.swift
//  aurorachat-macos
//
//  Created by Clovis de Sena on 29/05/2026.
//

import SwiftUI

@main
struct aurorachat_macosApp: App {
    @State private var client = AuroraClient()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(client)
        }
        .defaultSize(width: 900, height: 650)
    }
}
