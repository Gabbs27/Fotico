import SwiftUI

struct BeforeAfterView: View {
    let originalCIImage: CIImage?
    let editedCIImage: CIImage?
    let onDismiss: () -> Void

    @State private var dividerPosition: CGFloat = 0.5

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let dividerX = width * dividerPosition

            ZStack {
                // Edited image (full)
                if let edited = editedCIImage {
                    MetalImageView(ciImage: edited)
                        .ignoresSafeArea()
                }

                // Original image (clipped to left of divider)
                if let original = originalCIImage {
                    MetalImageView(ciImage: original)
                        .ignoresSafeArea()
                        .mask(
                            HStack(spacing: 0) {
                                Rectangle()
                                    .frame(width: dividerX)
                                Spacer(minLength: 0)
                            }
                        )
                }

                // Divider line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2)
                    .position(x: dividerX, y: geometry.size.height / 2)
                    .shadow(color: .black.opacity(0.5), radius: 2)

                // Divider handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .overlay(
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                                .font(.caption2.weight(.bold))
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundColor(.black)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .position(x: dividerX, y: geometry.size.height / 2)

                // Labels
                VStack {
                    HStack {
                        Text("ORIGINAL")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)
                            .foregroundColor(.white)
                            .padding(.leading, 12)

                        Spacer()

                        Text("EDITADO")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)
                            .foregroundColor(.white)
                            .padding(.trailing, 12)
                    }
                    .padding(.top, 12)

                    Spacer()
                }

                // Close button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 50)
                    Spacer()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dividerPosition = min(max(value.location.x / width, 0.02), 0.98)
                    }
            )
            .background(Color.black)
        }
    }
}
