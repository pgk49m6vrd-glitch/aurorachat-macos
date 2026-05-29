//
//  MessageBubbleView.swift
//  aurorachat-macos
//
//  Reusable message display component, styled like Discord/other AuC clients.
//

import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        if message.isSystem {
            systemMessage
        } else {
            userMessage
        }
    }

    // MARK: - User Message

    private var userMessage: some View {
        HStack(alignment: .top, spacing: 10) {
            // Avatar
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.2))
                    .frame(width: 36, height: 36)

                if message.username == "auroracross" {
                    // Discord bridge bot
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(red: 0.35, green: 0.4, blue: 0.95))
                } else {
                    Text(String(message.username.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(avatarColor)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(message.username)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(avatarColor)

                    // Platform badge
                    Text("macOS")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())

                    Text(timeString)
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                }

                Text(message.message)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    // MARK: - System Message

    private var systemMessage: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(systemBarColor)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 2) {
                Text(message.username)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(systemBarColor)
                Text(message.message)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    // MARK: - Helpers

    private var avatarColor: Color {
        let colors: [Color] = [
            Color(red: 0.5, green: 0.3, blue: 0.9),
            Color(red: 0.2, green: 0.7, blue: 0.9),
            Color(red: 0.9, green: 0.4, blue: 0.3),
            Color(red: 0.3, green: 0.8, blue: 0.4),
            Color(red: 0.9, green: 0.6, blue: 0.2),
            Color(red: 0.8, green: 0.3, blue: 0.6),
            Color(red: 0.3, green: 0.6, blue: 0.8),
        ]
        let index = abs(message.username.hashValue) % colors.count
        return colors[index]
    }

    private var systemBarColor: Color {
        if message.message.lowercased().contains("error") ||
           message.message.lowercased().contains("lost") ||
           message.message.lowercased().contains("failed") {
            return .red
        } else if message.message.lowercased().contains("reconnect") {
            return .orange
        } else {
            return .green
        }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: message.timestamp)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 0) {
        MessageBubbleView(message: ChatMessage(
            username: "System",
            message: "Welcome to AuroraChat!",
            room: "general",
            isSystem: true
        ))
        MessageBubbleView(message: ChatMessage(
            username: "JakubKwantowy",
            message: "Hello from 3DS!",
            room: "general"
        ))
        MessageBubbleView(message: ChatMessage(
            username: "auroracross",
            message: "Bridged message from Discord",
            room: "general"
        ))
        MessageBubbleView(message: ChatMessage(
            username: "Clovis",
            message: "Testing the macOS client 🎉",
            room: "general"
        ))
    }
    .frame(width: 600)
    .padding()
}
