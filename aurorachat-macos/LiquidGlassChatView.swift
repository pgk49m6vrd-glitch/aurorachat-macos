import SwiftUI

struct LiquidGlassChatView: View {
    @Environment(AuroraClient.self) private var client
    @Environment(ThemeManager.self) private var theme
    @State private var messageText: String = ""

    var body: some View {
        NavigationSplitView {
            liquidGlassSidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
        } detail: {
            liquidGlassChatArea
        }
    }

    // MARK: - Sidebar
    // this whole sidebar could probably be extracted into its own view

    private var liquidGlassSidebar: some View {
        VStack(spacing: 0) {
            // Logo header
            HStack(spacing: 8) {
                Image("AuroraChatLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 26)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Rooms
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("ROOMS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Button(action: { client.currentScreen = .rooms }) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)

                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(client.rooms) { room in
                            glassRoomRow(room: room)
                                .onTapGesture {
                                    withAnimation(.smooth(duration: 0.2)) {
                                        client.switchRoom(to: room.name)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .padding(.top, 4)

            Spacer()

            // User bar
            HStack(spacing: 10) {
                Circle()
                    .fill(connectionColor)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 1) {
                    Text(client.currentUsername)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    Text(client.connectionState.label)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Menu {
                    Button("Browse Rooms") { client.currentScreen = .rooms }
                    Divider()
                    Button("Log Out", role: .destructive) { client.logout() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 24)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private func glassRoomRow(room: Room) -> some View {
        let isSelected = room.name == client.currentRoom
        HStack(spacing: 8) {
            Text("#")
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundStyle(isSelected ? theme.colors.accent : .secondary)
            Text(room.name)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? theme.colors.accent.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
    }

    // chat area w/ floating input

    private var liquidGlassChatArea: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(
                colors: [
                    theme.colors.accent.opacity(0.03),
                    Color.clear,
                    theme.colors.accent.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Channel header
                HStack(spacing: 8) {
                    Image(systemName: "number")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                    Text(client.currentRoom)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Spacer()
                    HStack(spacing: 5) {
                        Circle().fill(connectionColor).frame(width: 6, height: 6)
                        Text(client.connectionState.label)
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(client.currentMessages) { msg in
                                MessageBubbleView(message: msg).id(msg.id)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.bottom, 80) // Space for floating input
                    }
                    .onChange(of: client.messages.count) {
                        if let last = client.currentMessages.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            // Gradient glow behind input bar (Gemini-style)
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [
                        Color.clear,
                        theme.colors.accent.opacity(0.04),
                        theme.colors.accent.opacity(0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
                .allowsHitTesting(false)
            }
            .ignoresSafeArea()

            // Floating glass input bar
            VStack(spacing: 0) {
                floatingInputBar
                    .shadow(color: theme.colors.accent.opacity(0.15), radius: 20, y: -4)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    // floating input - inspired by gemini app

    private var floatingInputBar: some View {
        HStack(spacing: 8) {
            // + Attachment button
            Button(action: {}) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            // Text field
            TextField("Message #\(client.currentRoom)...", text: $messageText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .onSubmit { sendMessage() }

            // Send button
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        messageText.isEmpty
                            ? Color.secondary.opacity(0.4)
                            : theme.colors.accent
                    )
            }
            .buttonStyle(.plain)
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            glassInputBackground
        }
    }

    @ViewBuilder
    private var glassInputBackground: some View {
        if #available(macOS 26, *) {
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .glassEffect(in: .capsule)
        } else {
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
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
        let txt = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !txt.isEmpty else { return }
        let room = client.currentRoom
        messageText = ""
        Task { await client.sendMessage(txt, in: room) }
    }
}
