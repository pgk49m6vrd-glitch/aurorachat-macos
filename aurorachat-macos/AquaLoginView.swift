import SwiftUI

struct AquaLoginView: View {
    @Environment(AuroraClient.self) private var client
    @Environment(ThemeManager.self) private var theme

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isSignUp: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        ZStack {
            AquaPinstripeBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 10) {
                    Image("AuroraChatLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 70)
                        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

                    Text(isSignUp ? "Create your account" : "Welcome back")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 24)

                // Aqua form card
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Username:")
                            .font(.system(size: 12, weight: .medium))
                        TextField("Username", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13))
                            .onSubmit { handleAuth() }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password:")
                            .font(.system(size: 12, weight: .medium))
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13))
                            .onSubmit { handleAuth() }
                    }

                    // Error
                    if let errorMessage {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                            Text(errorMessage)
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(.red)
                        .transition(.opacity)
                    }
                }
                .frame(maxWidth: 280)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0.75, green: 0.78, blue: 0.82), lineWidth: 1)
                        )
                )
                .offset(x: shakeOffset)
                .padding(.bottom, 16)

                // Aqua buttons
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSignUp.toggle()
                            errorMessage = nil
                        }
                    }) {
                        Text(isSignUp ? "Log In Instead" : "Sign Up")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(AquaButtonStyle(isPrimary: false))

                    Button(action: handleAuth) {
                        HStack(spacing: 4) {
                            if isLoading {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            }
                            Text(isSignUp ? "Create Account" : "Log In")
                                .font(.system(size: 12))
                        }
                    }
                    .buttonStyle(AquaButtonStyle(isPrimary: true))
                    .disabled(isLoading)
                }

                Spacer()

                Text("macOS v0.1.0")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 14)
            }
        }
        .frame(minWidth: 400, minHeight: 480)
        .onAppear { username = client.lastUsername }
    }

    // MARK: - Auth

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
                }
                password = ""
            } catch let error as AuroraError {
                withAnimation(.easeInOut(duration: 0.2)) { errorMessage = error.localizedDescription }
                triggerShake()
            } catch {
                withAnimation(.easeInOut(duration: 0.2)) { errorMessage = error.localizedDescription }
                triggerShake()
            }
            isLoading = false
        }
    }

    private func triggerShake() {
        withAnimation(.default) { shakeOffset = -8 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.default) { shakeOffset = 8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.default) { shakeOffset = -5 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.spring(response: 0.2)) { shakeOffset = 0 }
        }
    }
}
