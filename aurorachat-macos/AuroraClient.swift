//
//  AuroraClient.swift
//  aurorachat-macos
//
//  Networking client for AuroraChat v6
//  handles HTTP + TCP stuff
//

import Foundation
import Observation

@Observable
@MainActor
final class AuroraClient {
    // MARK: - Server Configuration

    var serverIP: String {
        didSet { UserDefaults.standard.set(serverIP, forKey: "serverIP") }
    }
    var httpPort: Int {
        didSet { UserDefaults.standard.set(httpPort, forKey: "httpPort") }
    }
    var tcpPort: Int {
        didSet { UserDefaults.standard.set(tcpPort, forKey: "tcpPort") }
    }

    // MARK: - State

    var authToken: String = ""
    var currentUsername: String = ""
    var rooms: [Room] = []
    var messages: [ChatMessage] = []
    var currentRoom: String = "general"
    var connectionState: ConnectionState = .disconnected
    var currentScreen: AppScreen = .login
    var errorMessage: String? = nil

    // MARK: - Private

    private let tcp = TCPConnection()
    private let userAgent = "aurorachat macOS"
    private let clientVersion = "macOS v0.1.0"

    // MARK: - Init

    init() {
        self.serverIP = UserDefaults.standard.string(forKey: "serverIP") ?? "104.236.25.60"
        self.httpPort = UserDefaults.standard.object(forKey: "httpPort") as? Int ?? 6767
        self.tcpPort = UserDefaults.standard.object(forKey: "tcpPort") as? Int ?? 3033

        tcp.onMessageReceived = { [weak self] username, message, room in
            guard let self else { return }
            let msg = ChatMessage(username: username, message: message, room: room)
            self.messages.append(msg)
        }

        tcp.onStateChanged = { [weak self] state in
            guard let self else { return }
            self.connectionState = state

            if state == .disconnected {
                let sysMsg = ChatMessage(
                    username: "System",
                    message: "Connection lost. Attempting to reconnect...",
                    room: self.currentRoom,
                    isSystem: true
                )
                self.messages.append(sysMsg)
            } else if state == .connected {
                let sysMsg = ChatMessage(
                    username: "System",
                    message: "Connected to server.",
                    room: self.currentRoom,
                    isSystem: true
                )
                self.messages.append(sysMsg)
            }
        }
    }

    // -- http helpers --

    private var baseURL: String {
        "http://\(serverIP):\(httpPort)"
    }

    private func postRequest(endpoint: String, body: String, auth: String? = nil) async throws -> String {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw AuroraError.serverUnreachable
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        if let auth {
            request.setValue(auth, forHTTPHeaderField: "auth")
        }

        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        // print("[DEBUG] response: \(String(data: data, encoding: .utf8) ?? "nil"))")

        guard let response = String(data: data, encoding: .utf8) else {
            throw AuroraError.serverUnreachable
        }

        return response
    }

    // FIXME: should probably add rate limiting at some point

    func login(username: String, password: String) async throws {
        errorMessage = nil

        guard !username.isEmpty, !password.isEmpty else {
            throw AuroraError.missingInput
        }

        let body = "\(username)|\(password)"

        let response: String
        do {
            response = try await postRequest(endpoint: "/api/login", body: body)
        } catch {
            throw AuroraError.serverUnreachable
        }

        // Check for error responses
        if let error = AuroraError.from(serverResponse: response) {
            throw error
        }

        // token is first part before the pipe
        let token = response
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "|")
            .first ?? ""

        guard !token.isEmpty else {
            throw AuroraError.unknownError("Invalid server response")
        }

        self.authToken = token
        self.currentUsername = username

        // Save last user
        UserDefaults.standard.set(username, forKey: "lastUsername")

        // Fetch rooms and connect
        await postLogin()
    }

    func signup(username: String, password: String) async throws {
        errorMessage = nil

        guard !username.isEmpty, !password.isEmpty else {
            throw AuroraError.missingInput
        }

        let body = "\(username)|\(password)"

        let response: String
        do {
            response = try await postRequest(endpoint: "/api/signup", body: body)
        } catch {
            throw AuroraError.serverUnreachable
        }

        if let error = AuroraError.from(serverResponse: response) {
            throw error
        }

        let token = response
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "|")
            .first ?? ""

        guard !token.isEmpty else {
            throw AuroraError.unknownError("Invalid server response")
        }

        self.authToken = token
        self.currentUsername = username
        UserDefaults.standard.set(username, forKey: "lastUsername")

        await postLogin()
    }

    // TODO: maybe add a "remember me" checkbox later

    private func postLogin() async {
        do {
            try await fetchRooms()
        } catch {
            // Non-fatal: proceed with default room
        }

        // Connect TCP for real-time messages
        tcp.connect(host: serverIP, port: UInt16(tcpPort))

        // Add welcome message
        let welcome = ChatMessage(
            username: "System",
            message: "Welcome to AuroraChat, \(currentUsername)! You joined #\(currentRoom).",
            room: currentRoom,
            isSystem: true
        )
        messages.append(welcome)

        currentScreen = .chat
    }

    // fetch available rooms from server

    func fetchRooms() async throws {
        let response: String
        do {
            response = try await postRequest(endpoint: "/api/rooms", body: "")
        } catch {
            throw AuroraError.serverUnreachable
        }

        let parts = response.components(separatedBy: "|").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard let countStr = parts.first, let count = Int(countStr), count > 0 else {
            return
        }

        var fetchedRooms: [Room] = []
        for i in 1...min(count, parts.count - 1) {
            let name = parts[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                fetchedRooms.append(Room(name: name))
            }
        }

        self.rooms = fetchedRooms
    }

    // MARK: - Send Message
    // TODO: add typing indicator support

    func sendMessage(_ txt: String, in room: String) async {
        guard !txt.isEmpty else { return }

        let body = "\(txt)|\(room)|"
        print("[send] \(room): \(txt.prefix(50))")

        do {
            let response = try await postRequest(endpoint: "/api/chat", body: body, auth: authToken)

            if let error = AuroraError.from(serverResponse: response) {
                let sysMsg = ChatMessage(
                    username: "System",
                    message: error.localizedDescription,
                    room: room,
                    isSystem: true
                )
                messages.append(sysMsg)
            }
        } catch {
            let sysMsg = ChatMessage(
                username: "System",
                message: "Failed to send message: \(error.localizedDescription)",
                room: room,
                isSystem: true
            )
            messages.append(sysMsg)
        }
    }

    // MARK: - Switch Room

    func switchRoom(to roomName: String) {
        currentRoom = roomName
        let sysMsg = ChatMessage(
            username: "System",
            message: "Switched to #\(roomName)",
            room: roomName,
            isSystem: true
        )
        messages.append(sysMsg)
    }

    // MARK: - Filtered Messages

    var currentMessages: [ChatMessage] {
        messages.filter { $0.room == currentRoom }
    }

    // MARK: - Logout

    func logout() {
        tcp.disconnect()
        authToken = ""
        currentUsername = ""
        messages.removeAll()
        rooms.removeAll()
        connectionState = .disconnected
        currentRoom = "general"
        currentScreen = .login
    }

    // MARK: - Saved Username

    var lastUsername: String {
        UserDefaults.standard.string(forKey: "lastUsername") ?? ""
    }
}
