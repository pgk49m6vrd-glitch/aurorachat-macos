//
//  Models.swift
//  aurorachat-macos
//

import Foundation

// MARK: - App Navigation

// TODO: add a .settings screen later?
enum AppScreen {
    case login
    case rooms
    case chat
}

// MARK: - Chat Message

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let username: String
    let message: String
    let room: String
    let timestamp: Date
    let isSystem: Bool

    init(username: String, message: String, room: String, isSystem: Bool = false) {
        self.username = username
        self.message = message
        self.room = room
        self.timestamp = Date()
        self.isSystem = isSystem
    }
}

// MARK: - Room

struct Room: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String

    var displayName: String {
        name.prefix(1).uppercased() + name.dropFirst()
    }

    var iconLetter: String {
        String(name.prefix(1)).uppercased()
    }
}

// errors from the server
// see server.js for the full list

enum AuroraError: LocalizedError {
    case wrongPassword
    case banned
    case userAlreadyUsed
    case missingInput
    case invalidToken
    case noRights
    case fakeRoom
    case serverUnreachable
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .wrongPassword:
            return "Incorrect username or password."
        case .banned:
            return "Your account has been banned."
        case .userAlreadyUsed:
            return "This username is already taken."
        case .missingInput:
            return "Please fill in both username and password."
        case .invalidToken:
            return "Session expired. Please log in again."
        case .noRights:
            return "You don't have permission to do that."
        case .fakeRoom:
            return "That room doesn't exist."
        case .serverUnreachable:
            return "Could not reach the server. Check your connection."
        case .unknownError(let msg):
            return "Error: \(msg)"
        }
    }

    static func from(serverResponse: String) -> AuroraError? {
        let trimmed = serverResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        switch trimmed {
        case "ERR_WRONG_PASS":
            return .wrongPassword
        case "ERR_BANNED":
            return .banned
        case "ERR_USER_USED":
            return .userAlreadyUsed
        case "ERR_MISSING_INPUT":
            return .missingInput
        case "ERR_INVALID_TOKEN":
            return .invalidToken
        case "ERR_NO_RIGHTS":
            return .noRights
        case "ERR_FAKE_ROOM_YOU_MORON":
            return .fakeRoom
        case "ERR_WHAT_THE_HECK":
            return .unknownError("Unknown server error")
        case "ERR_FAKE_USER":
            return .unknownError("Invalid user account")
        default:
            if trimmed.hasPrefix("ERR_") {
                return .unknownError(trimmed)
            }
            return nil
        }
    }
}

// connection status

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting

    var color: String {
        switch self {
        case .connected: return "green"
        case .connecting, .reconnecting: return "orange"
        case .disconnected: return "red"
        }
    }

    var label: String {
        switch self {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .reconnecting: return "Reconnecting..."
        case .disconnected: return "Disconnected"
        }
    }
}
