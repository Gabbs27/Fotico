import SwiftUI

struct CropView: View {
    @Binding var rotation: Double
    var onRotationChanged: () -> Void
    var onCommit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Rotation
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "rotate.right")
                        .font(.caption)
                        .foregroundColor(.white)

                    Text("Rotación")
                        .font(.caption)
                        .foregroundColor(.lumeTextSecondary)

                    Spacer()

                    Text("\(String(format: "%.1f", rotation))\u{00B0}")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(.white)
                }
                .padding(.horizontal)

                Slider(value: $rotation, in: -180...180, step: 0.5)
                    .tint(.white)
                    .padding(.horizontal)
                    .onChange(of: rotation) { _, _ in
                        onRotationChanged()
                    }
            }

            // Quick rotation buttons
            HStack(spacing: 16) {
                Button {
                    HapticManager.impact(.light)
                    onCommit()
                    rotation -= 90
                    if rotation < -180 { rotation += 360 }
                    onRotationChanged()
                } label: {
                    Label("Girar", systemImage: "rotate.left")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.lumeSurface)
                        .cornerRadius(8)
                }

                Button {
                    HapticManager.impact(.light)
                    onCommit()
                    rotation = 0
                    onRotationChanged()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                        .foregroundColor(Color.lumeWarning)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.lumeSurface)
                        .cornerRadius(8)
                }
            }

            Spacer()
        }
        .padding(.top, 12)
    }
}
