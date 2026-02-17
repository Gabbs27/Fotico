import AuthenticationServices
import SwiftUI
import SwiftData

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?

    private let keychainKey = "com.fotico.appleUserID"

    func checkExistingAuth(modelContext: ModelContext) {
        guard let userID = KeychainHelper.load(key: keychainKey) else {
            isAuthenticated = false
            return
        }

        let descriptor = FetchDescriptor<UserProfile>()
        if let users = try? modelContext.fetch(descriptor),
           let user = users.first(where: { $0.appleUserID == userID }) {
            currentUser = user
            isAuthenticated = true
        }
    }

    func handleSignIn(result: Result<ASAuthorization, Error>, modelContext: ModelContext) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }

            let userID = credential.user
            let email = credential.email
            let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            // Save to Keychain
            KeychainHelper.save(key: keychainKey, value: userID)

            // Check if user exists
            let descriptor = FetchDescriptor<UserProfile>()
            let existingUsers = (try? modelContext.fetch(descriptor)) ?? []

            if let existingUser = existingUsers.first(where: { $0.appleUserID == userID }) {
                currentUser = existingUser
            } else {
                let displayName = fullName.isEmpty ? "Usuario" : fullName
                let newUser = UserProfile(displayName: displayName, email: email, appleUserID: userID)
                modelContext.insert(newUser)
                try? modelContext.save()
                currentUser = newUser
            }

            isAuthenticated = true
            HapticManager.notification(.success)

        case .failure(let error):
            print("[Auth] Sign in failed: \(error.localizedDescription)")
            HapticManager.notification(.error)
        }
    }

    func signOut() {
        KeychainHelper.delete(key: keychainKey)
        currentUser = nil
        isAuthenticated = false
        HapticManager.notification(.success)
    }
}

// MARK: - Keychain Helper

enum KeychainHelper {
    static func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
