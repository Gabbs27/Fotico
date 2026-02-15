import SwiftUI

struct CaptureButtonView: View {
    let isCapturing: Bool
    let onCapture: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            guard !isCapturing else { return }
            onCapture()
        } label: {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 76, height: 76)

                // Inner fill
                Circle()
                    .fill(Color.white)
                    .frame(width: 64, height: 64)
                    .scaleEffect(isPressed ? 0.85 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)

                if isCapturing {
                    ProgressView()
                        .tint(.black)
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .disabled(isCapturing)
    }
}
