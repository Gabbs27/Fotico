import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authService = AuthService.shared
    @State private var showLogin = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.lumeDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        profileHeader
                            .padding(.top, 20)

                        // Account section
                        settingsSection(title: "Cuenta") {
                            if authService.isAuthenticated {
                                settingsRow(icon: "person.fill", title: authService.currentUser?.displayName ?? "Usuario")
                                if let email = authService.currentUser?.email {
                                    settingsRow(icon: "envelope.fill", title: email)
                                }
                                settingsRow(icon: "crown.fill", title: "Plan: \(authService.currentUser?.tier.rawValue.capitalized ?? "Free")", color: Color.lumePrimary)
                            } else {
                                Button {
                                    showLogin = true
                                } label: {
                                    settingsRow(icon: "person.badge.plus", title: "Iniciar sesion", color: Color.lumePrimary)
                                }
                            }
                        }

                        // App section
                        settingsSection(title: "App") {
                            settingsRow(icon: "star.fill", title: "Calificar Lumé", color: .yellow)
                            settingsRow(icon: "square.and.arrow.up", title: "Compartir Lumé")
                            settingsRow(icon: "questionmark.circle.fill", title: "Ayuda")
                        }

                        // Danger zone
                        if authService.isAuthenticated {
                            settingsSection(title: "") {
                                Button {
                                    authService.signOut()
                                } label: {
                                    settingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Cerrar sesion", color: .red)
                                }
                            }
                        }

                        // Version
                        Text("Lumé v2.0")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 16)
                    }
                    .padding()
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showLogin) {
                LoginView(authService: authService) {
                    showLogin = false
                }
            }
            .onAppear {
                authService.checkExistingAuth(modelContext: modelContext)
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.lumeSurface)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: authService.isAuthenticated ? "person.fill" : "person.crop.circle")
                        .font(.system(size: 32))
                        .foregroundColor(authService.isAuthenticated ? Color.lumePrimary : .gray)
                )

            Text(authService.isAuthenticated ? (authService.currentUser?.displayName ?? "Usuario") : "Invitado")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }

    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !title.isEmpty {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            VStack(spacing: 0) {
                content()
            }
            .background(Color.lumeCardBg)
            .cornerRadius(12)
        }
    }

    private func settingsRow(icon: String, title: String, color: Color = .white) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .font(.body)
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
