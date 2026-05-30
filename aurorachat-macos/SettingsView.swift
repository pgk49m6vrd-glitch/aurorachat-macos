import SwiftUI

struct SettingsView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(AuroraClient.self) private var client

    var body: some View {
        TabView {
            Tab("Appearance", systemImage: "paintbrush.fill") {
                appearanceTab
            }
            Tab("Shortcuts", systemImage: "keyboard") {
                shortcutsTab
            }
            Tab("Server", systemImage: "server.rack") {
                serverTab
            }
        }
        .frame(width: 520, height: 420)
    }

    // MARK: - Appearance Tab

    private var appearanceTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Theme")
                .font(.headline)

            Text("Choose your AuroraChat look. Some themes require a specific macOS version.")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 12)], spacing: 12) {
                ForEach(AppTheme.allCases) { t in
                    themeCard(t)
                }
            }

            Spacer()
        }
        .padding(24)
    }

    @ViewBuilder
    private func themeCard(_ t: AppTheme) -> some View {
        let isSelected = theme.currentTheme == t
        let isAvailable = t.isAvailable

        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(t.colors.accent.opacity(isAvailable ? 0.12 : 0.05))
                    .frame(height: 60)

                Image(systemName: t.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isAvailable ? t.colors.accent : .secondary.opacity(0.4))
            }

            Text(t.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isAvailable ? .primary : .secondary)

            if isAvailable {
                Text(t.subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            } else {
                HStack(spacing: 2) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8))
                    Text("Requires \(t.minimumOS)")
                        .font(.system(size: 9))
                }
                .foregroundStyle(.secondary.opacity(0.6))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? t.colors.accent.opacity(0.06) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? t.colors.accent.opacity(0.5) : Color.primary.opacity(0.06), lineWidth: isSelected ? 2 : 1)
                )
        )
        .opacity(isAvailable ? 1 : 0.6)
        .onTapGesture {
            if isAvailable {
                withAnimation(.spring(response: 0.25)) {
                    theme.selectTheme(t)
                }
            }
        }
    }

    // MARK: - Shortcuts Tab

    @State private var isRecordingHotkey = false
    @State private var hotkeyEnabled: Bool = HotkeyManager.shared.isEnabled
    @State private var accessibilityGranted: Bool = AXIsProcessTrusted()

    private var shortcutsTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Keyboard Shortcuts")
                .font(.headline)

            // Summon shortcut
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $hotkeyEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Summon AuroraChat")
                            .font(.system(size: 13, weight: .medium))
                        Text("Bring AuroraChat to the front from any application.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: hotkeyEnabled) { _, newValue in
                    HotkeyManager.shared.isEnabled = newValue
                }

                HStack(spacing: 12) {
                    Text("Shortcut:")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Button(action: {
                        isRecordingHotkey.toggle()
                    }) {
                        HStack(spacing: 6) {
                            if isRecordingHotkey {
                                Text("Press keys...")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.orange)
                            } else {
                                Text(HotkeyManager.shared.shortcutLabel)
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isRecordingHotkey ? Color.orange.opacity(0.1) : Color.primary.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isRecordingHotkey ? Color.orange.opacity(0.4) : Color.primary.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)

                    if isRecordingHotkey {
                        Button("Cancel") {
                            isRecordingHotkey = false
                        }
                        .font(.system(size: 11))
                        .buttonStyle(.bordered)
                    }
                }
                .disabled(!hotkeyEnabled)
                .opacity(hotkeyEnabled ? 1 : 0.5)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
            )

            // Preset shortcuts
            if isRecordingHotkey {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Presets")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        presetButton("⌥Space", modifier: .option, keyCode: 49)
                        presetButton("⌃Space", modifier: .control, keyCode: 49)
                        presetButton("⌘⇧A", modifier: [.command, .shift], keyCode: 0)
                        presetButton("⌥A", modifier: .option, keyCode: 0)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Accessibility permission card
            accessibilityPermissionCard

            Spacer()
        }
        .padding(24)
        .onKeyPress { press in
            guard isRecordingHotkey else { return .ignored }
            let modifiers = press.modifiers
            guard !modifiers.isEmpty else { return .ignored }

            // Map SwiftUI EventModifiers to NSEvent.ModifierFlags
            var nsFlags: NSEvent.ModifierFlags = []
            if modifiers.contains(.option) { nsFlags.insert(.option) }
            if modifiers.contains(.command) { nsFlags.insert(.command) }
            if modifiers.contains(.control) { nsFlags.insert(.control) }
            if modifiers.contains(.shift) { nsFlags.insert(.shift) }

            // We use the character to determine key code approximately
            if let char = press.characters.first {
                let code = approximateKeyCode(for: char)
                HotkeyManager.shared.modifierFlags = nsFlags
                HotkeyManager.shared.keyCode = code
            }

            isRecordingHotkey = false
            return .handled
        }
    }

    @ViewBuilder
    private func presetButton(_ label: String, modifier: NSEvent.ModifierFlags, keyCode: UInt16) -> some View {
        Button(label) {
            HotkeyManager.shared.modifierFlags = modifier
            HotkeyManager.shared.keyCode = keyCode
            isRecordingHotkey = false
        }
        .font(.system(size: 11, design: .monospaced))
        .buttonStyle(.bordered)
    }

    // MARK: - Accessibility Permission

    private var accessibilityPermissionCard: some View {
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                Circle()
                    .fill(accessibilityGranted ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: accessibilityGranted ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(accessibilityGranted ? .green : .red)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Accessibility Permission")
                    .font(.system(size: 12, weight: .medium))

                if accessibilityGranted {
                    Text("AuroraChat can capture global keyboard shortcuts.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Required for the global shortcut to work outside AuroraChat.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if accessibilityGranted {
                Text("Granted")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.green)
            } else {
                Button(action: openAccessibilitySettings) {
                    HStack(spacing: 4) {
                        Image(systemName: "gear")
                            .font(.system(size: 10))
                        Text("Open System Settings")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.85))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(accessibilityGranted ? Color.green.opacity(0.03) : Color.red.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(accessibilityGranted ? Color.green.opacity(0.12) : Color.red.opacity(0.15), lineWidth: 1)
                )
        )
        .onAppear { refreshAccessibility() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshAccessibility()
        }
    }

    private func refreshAccessibility() {
        accessibilityGranted = AXIsProcessTrusted()
    }

    private func openAccessibilitySettings() {
        // Open System Settings → Privacy & Security → Accessibility
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func approximateKeyCode(for char: Character) -> UInt16 {
        switch char.lowercased() {
        case " ": return 49
        case "a": return 0
        case "s": return 1
        case "d": return 2
        case "f": return 3
        case "g": return 5
        case "h": return 4
        case "j": return 38
        case "k": return 40
        case "l": return 37
        case "z": return 6
        case "x": return 7
        case "c": return 8
        case "v": return 9
        case "b": return 11
        case "n": return 45
        case "m": return 46
        case "q": return 12
        case "w": return 13
        case "e": return 14
        case "r": return 15
        case "t": return 17
        case "y": return 16
        case "u": return 32
        case "i": return 34
        case "o": return 31
        case "p": return 35
        default: return 49
        }
    }

    // MARK: - Server Tab

    @State private var ip: String = ""
    @State private var httpPort: String = ""
    @State private var tcpPort: String = ""
    @State private var serverSaved = false

    private var serverTab: some View {
        VStack(alignment: .leading, spacing: 20) {
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

                if serverSaved {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .transition(.opacity)
                }

                Button("Save") {
                    client.serverIP = ip
                    client.httpPort = Int(httpPort) ?? 6767
                    client.tcpPort = Int(tcpPort) ?? 3033
                    withAnimation { serverSaved = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { serverSaved = false }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.colors.accent)
            }

            Spacer()
        }
        .padding(24)
        .onAppear {
            ip = client.serverIP
            httpPort = String(client.httpPort)
            tcpPort = String(client.tcpPort)
        }
    }
}
