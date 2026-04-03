import SwiftUI

/// Overlay view for painting a motion blur mask.
/// Captures finger gestures and renders strokes to an offscreen CGContext.
struct MaskPaintingView: View {
    var viewModel: PhotoEditorViewModel
    let imageSize: CGSize
    let displaySize: CGSize

    @State private var maskContext: CGContext?
    @State private var maskImage: UIImage?
    @State private var lastPoint: CGPoint?

    var body: some View {
        ZStack {
            // Semi-transparent overlay showing painted mask areas
            if let maskImage {
                Image(uiImage: maskImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: displaySize.width, height: displaySize.height)
                    .opacity(0.35)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
            }

            // Gesture capture
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let point = convertToImageCoordinates(value.location)
                            if let last = lastPoint {
                                drawLine(from: last, to: point)
                            } else {
                                drawLine(from: point, to: point)
                            }
                            lastPoint = point
                            updateMaskImage()
                        }
                        .onEnded { _ in
                            lastPoint = nil
                            saveMaskToState()
                        }
                )
        }
        .onAppear {
            initializeContext()
            loadExistingMask()
        }
    }

    private func initializeContext() {
        let width = Int(imageSize.width)
        let height = Int(imageSize.height)
        guard width > 0, height > 0 else { return }
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return }

        ctx.setFillColor(gray: 0, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        maskContext = ctx
    }

    private func loadExistingMask() {
        guard let data = viewModel.editState.motionBlurMask,
              let uiImage = UIImage(data: data),
              let cgImage = uiImage.cgImage else { return }
        maskContext?.draw(cgImage, in: CGRect(x: 0, y: 0, width: Int(imageSize.width), height: Int(imageSize.height)))
        updateMaskImage()
    }

    private func drawLine(from: CGPoint, to: CGPoint) {
        guard let ctx = maskContext else { return }

        let brushRadius = viewModel.maskBrushSize / 2.0

        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setLineWidth(brushRadius * 2)

        switch viewModel.maskBrushMode {
        case .brush:
            ctx.setStrokeColor(gray: 1, alpha: 1)
        case .eraser:
            ctx.setStrokeColor(gray: 0, alpha: 1)
        }
        ctx.setBlendMode(.normal)

        let flippedFrom = CGPoint(x: from.x, y: imageSize.height - from.y)
        let flippedTo = CGPoint(x: to.x, y: imageSize.height - to.y)

        ctx.beginPath()
        ctx.move(to: flippedFrom)
        ctx.addLine(to: flippedTo)
        ctx.strokePath()
    }

    private func convertToImageCoordinates(_ screenPoint: CGPoint) -> CGPoint {
        let scaleX = imageSize.width / displaySize.width
        let scaleY = imageSize.height / displaySize.height
        return CGPoint(x: screenPoint.x * scaleX, y: screenPoint.y * scaleY)
    }

    private func updateMaskImage() {
        guard let ctx = maskContext, let cgImage = ctx.makeImage() else { return }
        maskImage = UIImage(cgImage: cgImage)
    }

    private func saveMaskToState() {
        guard let ctx = maskContext, let cgImage = ctx.makeImage() else { return }
        let uiImage = UIImage(cgImage: cgImage)
        let pngData = uiImage.pngData()
        viewModel.updateMotionBlurMask(pngData)
    }
}
