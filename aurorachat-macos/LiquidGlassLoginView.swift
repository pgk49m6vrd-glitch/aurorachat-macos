import SwiftUI

struct LiquidGlassLoginView: View {
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
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.6, blue: 0.7).opacity(0.06),
                    Color.clear,
                    theme.colors.accent.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 14) {
                    Image("AuroraChatLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 72)
                        .shadow(color: Color(red: 0.1, green: 0.7, blue: 0.7).opacity(0.3), radius: 24, y: 8)

                    Text(isSignUp ? "Create your account" : "Welcome back")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                }
                .padding(.bottom, 28)

                // Glass form card
                glassFormCard
                    .offset(x: shakeOffset)
                    .padding(.bottom, 16)

                // Buttons
                VStack(spacing: 10) {
                    Button(action: handleAuth) {
                        HStack(spacing: 6) {
                            if isLoading {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            }
                            Text(isSignUp ? "Create Account" : "Log In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: 300)
                        .padding(.vertical, 8)
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
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Text("macOS v0.1.0")
                    .font(.system(size: 10))
                    .foregroundStyle(.quaternary)
                    .padding(.bottom, 16)
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .onAppear { username = client.lastUsername }
    }

    // MARK: - Glass Form Card

    @ViewBuilder
    private var glassFormCard: some View {
        VStack(spacing: 14) {
            // Username
            HStack(spacing: 10) {
                Image(systemName: "person.fill")
                    .foregroundStyle(.tertiary)
                    .frame(width: 18)
                TextField("Username", text: $username)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .onSubmit { handleAuth() }
            }
            .padding(11)
            .background(glassFieldBg)

            // Password
            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.tertiary)
                    .frame(width: 18)
                SecureField("Password", text: $password)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .onSubmit { handleAuth() }
            }
            .padding(11)
            .background(glassFieldBg)

            // Error
            if let errorMessage {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                    Text(errorMessage)
                        .font(.system(size: 11))
                }
                .foregroundStyle(.red)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: 300)
        .padding(20)
        .background {
            if #available(macOS 26, *) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .glassEffect(in: .rect(cornerRadius: 20))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 16, y: 6)
            }
        }
    }

    @ViewBuilder
    private var glassFieldBg: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.primary.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
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
                withAnimation(.spring(response: 0.3)) { errorMessage = error.localizedDescription }
                triggerShake()
            } catch {
                withAnimation(.spring(response: 0.3)) { errorMessage = error.localizedDescription }
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
