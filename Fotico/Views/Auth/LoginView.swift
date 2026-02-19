import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var authService: AuthService
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo
            VStack(spacing: 8) {
                Text("LUMÉ")
                    .font(.system(size: 40, weight: .bold))
                    .tracking(6)
                    .foregroundColor(.white)

                Text("Film & Effects")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Sign in with Apple
            VStack(spacing: 16) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    authService.handleSignIn(result: result, modelContext: modelContext)
                    if authService.isAuthenticated {
                        onComplete()
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .cornerRadius(12)

                // Skip button
                Button {
                    onComplete()
                } label: {
                    Text("Continuar sin cuenta")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 40)

            Spacer().frame(height: 40)
        }
        .background(Color.lumeDark.ignoresSafeArea())
    }
}
