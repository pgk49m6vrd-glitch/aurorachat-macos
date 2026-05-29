//
//  ServerConfigView.swift
//  aurorachat-macos
//
//  Server IP and port configuration sheet.
//

import SwiftUI

struct ServerConfigView: View {
    @Environment(AuroraClient.self) private var client
    @Environment(\.dismiss) private var dismiss

    @State private var ip: String = ""
    @State private var httpPort: String = ""
    @State private var tcpPort: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Server Configuration")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                LabeledContent("Server IP") {
                    TextField("104.236.25.60", text: $ip)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                }
                LabeledContent("HTTP Port") {
                    TextField("6767", text: $httpPort)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                }
                LabeledContent("TCP Port") {
                    TextField("3033", text: $tcpPort)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                }
            }

            HStack {
                Button("Reset to Default") {
                    ip = "104.236.25.60"
                    httpPort = "6767"
                    tcpPort = "3033"
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)

                Button("Save") {
                    client.serverIP = ip
                    client.httpPort = Int(httpPort) ?? 6767
                    client.tcpPort = Int(tcpPort) ?? 3033
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.5, green: 0.3, blue: 0.9))
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear {
            ip = client.serverIP
            httpPort = String(client.httpPort)
            tcpPort = String(client.tcpPort)
        }
    }
}
