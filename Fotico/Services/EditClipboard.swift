import Foundation

@MainActor
@Observable class EditClipboard {
    static let shared = EditClipboard()

    var copiedState: EditState?

    var hasContent: Bool { copiedState != nil }

    func copy(_ state: EditState) {
        copiedState = state
        HapticManager.notification(.success)
    }

    func clear() {
        copiedState = nil
    }
}
