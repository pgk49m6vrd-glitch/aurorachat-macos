import SwiftUI

struct LoginView: View {
    @Environment(AuroraClient.self) private var client
    @Environment(ThemeManager.self) private var theme

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isSignUp: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo & Title
            VStack(spacing: 12) {
                Image("AuroraChatLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .shadow(color: Color(red: 0.1, green: 0.7, blue: 0.7).opacity(0.35), radius: 20, y: 6)

                Text(isSignUp ? "Create your account" : "Welcome back")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 32)

            // Form
            VStack(spacing: 16) {
                // Username Field
                HStack(spacing: 10) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    TextField("Username", text: $username)
                        .textFieldStyle(.plain)
                        .onSubmit { handleAuth() }
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )

                // Password Field
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .onSubmit { handleAuth() }
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )

                // Error Message
                if let errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text(errorMessage)
                            .font(.caption)
                    }
                    .foregroundStyle(.red)
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .frame(maxWidth: 320)
            .offset(x: shakeOffset)
            .padding(.bottom, 20)

            VStack(spacing: 10) {
                // TODO: add "remember me" toggle
                Button(action: handleAuth) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        }
                        Text(isSignUp ? "Create Account" : "Log In")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: 320)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.colors.accent)
                .disabled(isLoading)

                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isSignUp.toggle()
                        errorMessage = nil
                    }
                }) {
                    Text(isSignUp ? "Already have an account? Log In" : "Don't have an account? Sign Up")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Bottom section: Server Config + Version
            VStack(spacing: 8) {
                Button(action: {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gear")
                            .font(.caption2)
                        Text("Settings")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Text("macOS v0.1.0")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
            .padding(.bottom, 16)
        }
        .frame(minWidth: 400, minHeight: 500)
        .onAppear {
            username = client.lastUsername
        }
    }

    // auth logic

    private func handleAuth() {
        guard !isLoading else { return }

        withAnimation { errorMessage = nil }
        isLoading = true

        Task {
            do {
                if isSignUp {
                    try await client.signup(username: username, password: password)
                } else {
                    try await client.login(username: username, password: password)
                    print("logged in as \(username)") // debug
                }
                password = "" // Clear password on success
            } catch let error as AuroraError {
                withAnimation(.spring(response: 0.3)) {
                    errorMessage = error.localizedDescription
                }
                triggerShake()
            } catch {
                withAnimation(.spring(response: 0.3)) {
                    errorMessage = error.localizedDescription
                }
                triggerShake()
            }
            isLoading = false
        }
    }

    private func triggerShake() {
        withAnimation(.default) { shakeOffset = -10 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.default) { shakeOffset = 10 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.default) { shakeOffset = -6 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.spring(response: 0.2)) { shakeOffset = 0 }
        }
    }
}

#Preview {
    LoginView()
        .environment(AuroraClient())
}
