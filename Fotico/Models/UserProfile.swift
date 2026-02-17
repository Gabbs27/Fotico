import SwiftData
import Foundation

enum SubscriptionTier: String, Codable, Sendable {
    case free
    case pro
}

@Model
class UserProfile {
    var appleUserID: String?
    var displayName: String
    var email: String?
    var avatarData: Data?
    var createdAt: Date
    var subscriptionTier: String  // "free" or "pro"

    init(displayName: String = "Usuario", email: String? = nil, appleUserID: String? = nil) {
        self.displayName = displayName
        self.email = email
        self.appleUserID = appleUserID
        self.createdAt = Date()
        self.subscriptionTier = "free"
    }

    var tier: SubscriptionTier {
        get { SubscriptionTier(rawValue: subscriptionTier) ?? .free }
        set { subscriptionTier = newValue.rawValue }
    }
}
