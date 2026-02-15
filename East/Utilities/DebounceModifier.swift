import SwiftUI
import Combine

struct DebounceModifier: ViewModifier {
    let delay: TimeInterval
    let action: () -> Void

    @State private var debounceTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content.onChange(of: UUID()) { _, _ in
            debounceTask?.cancel()
            debounceTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { return }
                action()
            }
        }
    }
}

extension View {
    func debounce(_ value: some Equatable, delay: TimeInterval = 0.1, action: @escaping () -> Void) -> some View {
        self.onChange(of: value) { _, _ in
            Task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await MainActor.run {
                    action()
                }
            }
        }
    }
}
