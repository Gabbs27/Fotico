import Foundation

@MainActor
class EditClipboard: ObservableObject {
    static let shared = EditClipboard()

    @Published var copiedState: EditState?

    var hasContent: Bool { copiedState != nil }

    func copy(_ state: EditState) {
        copiedState = state
        HapticManager.notification(.success)
    }

    func clear() {
        copiedState = nil
    }
}
