import SwiftUI
import CoreImage

/// Image preview with pinch-to-zoom and pan.
/// Uses MetalImageView for zero-copy GPU rendering (CIImage → MTKView drawable).
/// Falls back to UIImage-based rendering if CIImage is not available.
struct ImagePreviewView: View {
    let ciImage: CIImage?
    let uiImage: UIImage?
    let isProcessing: Bool

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    init(ciImage: CIImage? = nil, uiImage: UIImage? = nil, isProcessing: Bool = false) {
        self.ciImage = ciImage
        self.uiImage = uiImage
        self.isProcessing = isProcessing
    }

    // Legacy init for backwards compatibility
    init(image: UIImage?, isProcessing: Bool) {
        self.ciImage = nil
        self.uiImage = image
        self.isProcessing = isProcessing
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.eastDark

                if let ciImage = ciImage {
                    // GPU-rendered path — no CGImage creation
                    MetalImageView(ciImage: ciImage)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(zoomGesture)
                        .simultaneousGesture(panGesture)
                        .onTapGesture(count: 2, perform: doubleTap)
                } else if let uiImage = uiImage {
                    // Fallback UIImage path
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(zoomGesture)
                        .simultaneousGesture(panGesture)
                        .onTapGesture(count: 2, perform: doubleTap)
                }

                if isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.eastPrimary)
                        .scaleEffect(0.8)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                }
            }
        }
        .clipped()
    }

    // MARK: - Gestures (extracted for cleaner body)

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newScale = lastScale * value.magnification
                scale = min(max(newScale, 1.0), 5.0)
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1.0 {
                    withAnimation(.spring(response: 0.3)) {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if scale > 1.0 {
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func doubleTap() {
        withAnimation(.spring(response: 0.3)) {
            if scale > 1.0 {
                scale = 1.0
                offset = .zero
                lastOffset = .zero
                lastScale = 1.0
            } else {
                scale = 2.5
                lastScale = 2.5
            }
        }
    }
}
