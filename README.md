<h1 align="center">Welcome to the aurorachat repository!</h1>
This is the macOS client for Aurorachat.<br>
For more clients and stuff, see the <a href="https://github.com/Unitendo/aurorachat">main repo</a>.
The license, code of conduct, and security/contributing guidelines in the main repo also apply here.

<br>This repository is <b>open</b> for contributions! If you'd like to, you may open a PR or an issue, contributing helps us as we develop aurorachat!

<h1 align="center">How to build aurorachat</h1>

### Requirements

- macOS 14+ (Sonoma or later)
- Xcode 15+ (or Xcode 26+ for the full macOS Tahoe experience)
- Apple Developer account (optional, for code signing)

### Building

```sh
git clone https://github.com/Unitendo/aurorachat-macos
cd aurorachat-macos
open aurorachat-macos.xcodeproj
```

Then press **⌘R** to build and run in Xcode.

Or from the command line:
```sh
xcodebuild -project aurorachat-macos.xcodeproj -scheme aurorachat-macos -destination 'platform=macOS' build
```

## Features
- [x] Login screen
- [x] Sign Up screen
- [x] Server IP configuration
- [x] Room list view
- [x] Room selection
- [x] Real-time chat via TCP
- [x] Message sending via HTTP API
- [x] Auto-reconnect on connection loss
- [x] Connection status indicator
- [x] System messages (join, disconnect, errors)
- [x] Platform badge ("macOS") on messages

## Architecture

| File | Purpose |
|------|---------|
| `Models.swift` | Data models (ChatMessage, Room, AuroraError, ConnectionState) |
| `AuroraClient.swift` | HTTP API client + state management |
| `TCPConnection.swift` | Real-time TCP connection (Network.framework) |
| `LoginView.swift` | Login/Signup screen |
| `RoomListView.swift` | Room selection grid |
| `ChatView.swift` | Main chat interface with sidebar |
| `MessageBubbleView.swift` | Reusable message display |
| `ServerConfigView.swift` | Server IP/port configuration |
| `ContentView.swift` | Screen navigation |

Built with SwiftUI and Network.framework — no external dependencies!
