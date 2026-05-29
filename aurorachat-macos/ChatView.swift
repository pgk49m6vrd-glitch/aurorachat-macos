//
//  ChatView.swift
//  aurorachat-macos
//
//  Main chat interface with sidebar room navigation and message area.
//

import SwiftUI

struct ChatView: View {
    @Environment(AuroraClient.self) private var client
    @State private var messageText: String = ""

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } detail: {
            chatArea
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundStyle(Color(red: 0.5, green: 0.3, blue: 0.9))
                Text("AuroraChat")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("ROOMS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(action: { client.currentScreen = .rooms }) {
                        Image(systemName: "square.grid.2x2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)

                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(client.rooms) { room in
                            RoomRow(room: room, isSelected: room.name == client.currentRoom)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        client.switchRoom(to: room.name)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }

            Spacer()
            Divider()

            HStack(spacing: 8) {
                Circle()
                    .fill(connectionColor)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 1) {
                    Text(client.currentUsername)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    Text(client.connectionState.label)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    Button("Browse Rooms") { client.currentScreen = .rooms }
                    Divider()
                    Button("Log Out", role: .destructive) { client.logout() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 24)
            }
            .padding(12)
        }
    }

    // MARK: - Chat Area

    private var chatArea: some View {
        VStack(spacing: 0) {
            // Channel Header
            HStack(spacing: 8) {
                Image(systemName: "number")
                    .foregroundStyle(.secondary)
                Text(client.currentRoom)
                    .font(.title3.bold())
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(connectionColor).frame(width: 6, height: 6)
                    Text(client.connectionState.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(client.currentMessages) { msg in
                            MessageBubbleView(message: msg).id(msg.id)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: client.messages.count) {
                    if let last = client.currentMessages.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            HStack(spacing: 8) {
                TextField("Message #\(client.currentRoom)...", text: $messageText)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onSubmit { sendMessage() }

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(messageText.isEmpty ? .secondary : Color(red: 0.5, green: 0.3, blue: 0.9))
                }
                .buttonStyle(.plain)
                .disabled(messageText.isEmpty)
            }
            .padding(12)
        }
    }

    private var connectionColor: Color {
        switch client.connectionState {
        case .connected: return .green
        case .connecting, .reconnecting: return .orange
        case .disconnected: return .red
        }
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let room = client.currentRoom
        messageText = ""
        Task { await client.sendMessage(text, in: room) }
    }
}

struct RoomRow: View {
    let room: Room
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Text("#")
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundStyle(isSelected ? .primary : .secondary)
            Text(room.name)
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.primary.opacity(0.08) : (isHovered ? Color.primary.opacity(0.04) : Color.clear))
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}
