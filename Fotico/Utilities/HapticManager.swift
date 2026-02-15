import UIKit

@MainActor
enum HapticManager {
    private static let impactLight = UIImpactFeedbackGenerator(style: .light)
    private static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private static let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let selectionGen = UISelectionFeedbackGenerator()
    private static let notificationGen = UINotificationFeedbackGenerator()

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        switch style {
        case .light: impactLight.impactOccurred()
        case .medium: impactMedium.impactOccurred()
        case .heavy: impactHeavy.impactOccurred()
        default: impactMedium.impactOccurred()
        }
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGen.notificationOccurred(type)
    }

    static func selection() {
        selectionGen.selectionChanged()
    }
}
