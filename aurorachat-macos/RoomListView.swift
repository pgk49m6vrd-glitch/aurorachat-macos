//
//  RoomListView.swift
//  aurorachat-macos
//
//  Room selection grid, matching the web client's rooms page.
//

import SwiftUI

struct RoomListView: View {
    @Environment(AuroraClient.self) private var client
    @Environment(ThemeManager.self) private var theme
    @State private var isRefreshing = false

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 250), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rooms")
                        .font(.title.bold())
                    Text("Choose a room to join")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: refreshRooms) {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
                .buttonStyle(.bordered)
                .disabled(isRefreshing)

                Button("Back to Chat") {
                    client.currentScreen = .chat
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.colors.accent)
            }
            .padding(20)

            Divider()

            // Room Grid
            ScrollView {
                if client.rooms.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No rooms available")
                            .foregroundStyle(.secondary)
                        Button("Refresh") { refreshRooms() }
                            .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 80)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(client.rooms) { room in
                            RoomCard(room: room, isSelected: room.name == client.currentRoom)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        client.switchRoom(to: room.name)
                                        client.currentScreen = .chat
                                    }
                                }
                        }
                    }
                    .padding(20)
                }
            }
        }
    }

    private func refreshRooms() {
        isRefreshing = true
        Task {
            try? await client.fetchRooms()
            isRefreshing = false
        }
    }
}

// MARK: - Room Card

struct RoomCard: View {
    let room: Room
    let isSelected: Bool

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 12) {
            // Room Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(roomColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Text(room.iconLetter)
                    .font(.title2.bold())
                    .foregroundStyle(roomColor)
            }

            // Room Name
            Text("#\(room.name)")
                .font(.headline)
                .lineLimit(1)

            // Enter button
            Text(isSelected ? "Current" : "Enter")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .green : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.green.opacity(0.5) : Color.primary.opacity(isHovered ? 0.15 : 0.05), lineWidth: isSelected ? 2 : 1)
                )
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var roomColor: Color {
        let colors: [Color] = [
            Color(red: 0.5, green: 0.3, blue: 0.9),
            Color(red: 0.2, green: 0.6, blue: 0.9),
            Color(red: 0.9, green: 0.4, blue: 0.3),
            Color(red: 0.3, green: 0.8, blue: 0.5),
            Color(red: 0.9, green: 0.6, blue: 0.2),
        ]
        let index = abs(room.name.hashValue) % colors.count
        return colors[index]
    }
}

#Preview {
    RoomListView()
        .environment(AuroraClient())
        .frame(width: 800, height: 600)
}
