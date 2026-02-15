import SwiftUI
import Combine

/// Proper debounce modifier that cancels the previous task before creating a new one.
/// The old version created a new Task per change without cancelling, causing task pile-up.
struct DebounceModifier<V: Equatable>: ViewModifier {
    let value: V
    let delay: TimeInterval
    let action: () -> Void

    @State private var debounceTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content.onChange(of: value) { _, _ in
            debounceTask?.cancel()
            debounceTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { return }
                await MainActor.run { action() }
            }
        }
    }
}

extension View {
    /// Debounce a value change with proper cancellation.
    func debounce<V: Equatable>(_ value: V, delay: TimeInterval = 0.1, action: @escaping () -> Void) -> some View {
        self.modifier(DebounceModifier(value: value, delay: delay, action: action))
    }
}
