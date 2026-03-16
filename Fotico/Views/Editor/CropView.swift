import SwiftUI

struct CropView: View {
    @Binding var rotation: Double
    @Binding var cropAspectRatio: CropAspectRatio
    var onRotationChanged: () -> Void
    var onCommit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Aspect Ratio chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CropAspectRatio.allCases, id: \.rawValue) { ratio in
                        Button {
                            HapticManager.selection()
                            onCommit()
                            cropAspectRatio = ratio
                        } label: {
                            Text(ratio.displayName)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(cropAspectRatio == ratio ? Color.lumePrimary : Color.lumeSurface)
                                .foregroundColor(cropAspectRatio == ratio ? .black : .white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal)
            }

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
                    .tint(Color.lumePrimary)
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
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.lumeSurface)
                        .cornerRadius(10)
                }

                Button {
                    HapticManager.impact(.light)
                    onCommit()
                    rotation = 0
                    onRotationChanged()
                } label: {
                    Label("Restablecer", systemImage: "arrow.counterclockwise")
                        .font(.subheadline)
                        .foregroundColor(Color.lumeWarning)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.lumeSurface)
                        .cornerRadius(10)
                }
            }

            Spacer()
        }
        .padding(.top, 12)
    }
}
