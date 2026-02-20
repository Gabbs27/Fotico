import UIKit

@MainActor
enum HapticManager {
    private static let impactLight = UIImpactFeedbackGenerator(style: .light)
    private static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private static let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let selectionGen = UISelectionFeedbackGenerator()
    private static let notificationGen = UINotificationFeedbackGenerator()

    /// Pre-warm all generators so the first haptic fires with minimal latency.
    /// Call once during app launch or first view appearance.
    static func warmUp() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selectionGen.prepare()
        notificationGen.prepare()
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        switch style {
        case .light:
            impactLight.impactOccurred()
            impactLight.prepare()
        case .medium:
            impactMedium.impactOccurred()
            impactMedium.prepare()
        case .heavy:
            impactHeavy.impactOccurred()
            impactHeavy.prepare()
        default:
            impactMedium.impactOccurred()
            impactMedium.prepare()
        }
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGen.notificationOccurred(type)
        notificationGen.prepare()
    }

    static func selection() {
        selectionGen.selectionChanged()
        selectionGen.prepare()
    }
}
