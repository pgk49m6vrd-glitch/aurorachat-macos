import SwiftUI

struct AquaChatView: View {
    @Environment(AuroraClient.self) private var client
    @Environment(ThemeManager.self) private var theme
    @State private var messageText: String = ""

    var body: some View {
        NavigationSplitView {
            aquaSidebar
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 260)
        } detail: {
            aquaChatArea
        }
    }

    // MARK: - Aqua Sidebar

    private var aquaSidebar: some View {
        VStack(spacing: 0) {
            // Aqua header bar
            HStack {
                Image("AuroraChatLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.88, green: 0.91, blue: 0.96),
                        Color(red: 0.78, green: 0.82, blue: 0.88)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            Divider()

            // Rooms
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Rooms")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(action: { client.currentScreen = .rooms }) {
                        Image(systemName: "square.grid.2x2")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)

                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(client.rooms) { room in
                            aquaRoomRow(room: room)
                                .onTapGesture {
                                    client.switchRoom(to: room.name)
                                }
                        }
                    }
                    .padding(.horizontal, 6)
                }
            }

            Spacer()

            Divider()

            // User info
            HStack(spacing: 6) {
                Circle()
                    .fill(connectionColor)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 1) {
                    Text(client.currentUsername)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                    Text(client.connectionState.label)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    Button("Browse Rooms") { client.currentScreen = .rooms }
                    Divider()
                    Button("Log Out", role: .destructive) { client.logout() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 20)
            }
            .padding(10)
            .background(Color(red: 0.85, green: 0.88, blue: 0.93))
        }
        .background(AquaPinstripeBackground())
    }

    @ViewBuilder
    private func aquaRoomRow(room: Room) -> some View {
        let isSelected = room.name == client.currentRoom
        HStack(spacing: 6) {
            Text("#")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(isSelected ? .white : theme.colors.accent)
            Text(room.name)
                .font(.system(size: 12))
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected
                      ? LinearGradient(colors: theme.colors.accentGradient, startPoint: .top, endPoint: .bottom)
                      : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom))
        )
        .contentShape(Rectangle())
    }

    // MARK: - Chat Area

    private var aquaChatArea: some View {
        VStack(spacing: 0) {
            // Aqua-style header
            HStack(spacing: 6) {
                Image(systemName: "number")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text(client.currentRoom)
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(connectionColor).frame(width: 6, height: 6)
                    Text(client.connectionState.label)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.88, green: 0.91, blue: 0.96),
                        Color(red: 0.78, green: 0.82, blue: 0.88)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(client.currentMessages) { msg in
                            MessageBubbleView(message: msg).id(msg.id)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .background(Color.white)
                .onChange(of: client.messages.count) {
                    if let last = client.currentMessages.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Aqua input bar
            HStack(spacing: 8) {
                TextField("Message #\(client.currentRoom)...", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
                    .onSubmit { sendMessage() }

                Button(action: sendMessage) {
                    Text("Send")
                        .font(.system(size: 12))
                }
                .buttonStyle(AquaButtonStyle(isPrimary: true))
                .disabled(messageText.isEmpty)
            }
            .padding(10)
            .background(AquaPinstripeBackground())
        }
    }

    // MARK: - Helpers

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
