//
//  TCPConnection.swift
//  aurorachat-macos
//
//  TCP socket connection using Network.framework for real-time message reception.
//  Messages arrive as: username|message|room|\n
//

import Foundation
import Network

@MainActor
final class TCPConnection: Sendable {
    private var connection: NWConnection?
    private var pendingBuffer: String = ""
    private let queue = DispatchQueue(label: "org.unitendo.aurorachat.tcp", qos: .userInitiated)

    var onMessageReceived: (@MainActor (String, String, String) -> Void)?
    var onStateChanged: (@MainActor (ConnectionState) -> Void)?

    private var shouldReconnect = false
    private var host: String = ""
    private var port: UInt16 = 0

    // MARK: - Connect

    func connect(host: String, port: UInt16) {
        self.host = host
        self.port = port
        self.shouldReconnect = true

        let nwHost = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(rawValue: port)!

        connection = NWConnection(host: nwHost, port: nwPort, using: .tcp)

        connection?.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                guard let self else { return }
                switch state {
                case .ready:
                    self.onStateChanged?(.connected)
                    self.startReceiving()
                case .waiting:
                    self.onStateChanged?(.reconnecting)
                case .failed:
                    self.onStateChanged?(.disconnected)
                    self.attemptReconnect()
                case .cancelled:
                    self.onStateChanged?(.disconnected)
                case .preparing:
                    self.onStateChanged?(.connecting)
                default:
                    break
                }
            }
        }

        onStateChanged?(.connecting)
        connection?.start(queue: queue)
    }

    // MARK: - Disconnect

    func disconnect() {
        shouldReconnect = false
        connection?.cancel()
        connection = nil
        pendingBuffer = ""
    }

    // MARK: - Receive Loop

    private func startReceiving() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, error in
            Task { @MainActor in
                guard let self else { return }

                if let data, !data.isEmpty, let text = String(data: data, encoding: .utf8) {
                    self.pendingBuffer += text
                    self.processBuffer()
                }

                if isComplete {
                    self.onStateChanged?(.disconnected)
                    self.attemptReconnect()
                    return
                }

                if error != nil {
                    self.onStateChanged?(.disconnected)
                    self.attemptReconnect()
                    return
                }

                // Continue receiving
                self.startReceiving()
            }
        }
    }

    // MARK: - Parse Messages

    private func processBuffer() {
        while let newlineIndex = pendingBuffer.firstIndex(of: "\n") {
            let line = String(pendingBuffer[pendingBuffer.startIndex..<newlineIndex])
            pendingBuffer = String(pendingBuffer[pendingBuffer.index(after: newlineIndex)...])

            let parts = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)

            // Format: username|message|room|
            if parts.count >= 3 {
                let username = parts[0]
                let message = parts[1]
                let room = parts[2]
                onMessageReceived?(username, message, room)
            }
        }
    }

    // MARK: - Reconnect

    private func attemptReconnect() {
        guard shouldReconnect else { return }

        onStateChanged?(.reconnecting)

        Task {
            try? await Task.sleep(for: .seconds(3))
            guard self.shouldReconnect else { return }
            self.connection?.cancel()
            self.connection = nil
            self.pendingBuffer = ""
            self.connect(host: self.host, port: self.port)
        }
    }
}
