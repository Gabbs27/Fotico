import UIKit
import CoreImage

extension UIImage {
    /// Converts UIImage to CIImage with correct orientation.
    /// Always normalizes the image first so the CIImage extent starts at (0,0)
    /// which is required for CIFilters like CIRandomGenerator, CIRadialGradient, etc.
    func toCIImage() -> CIImage? {
        // Normalize orientation by redrawing - this ensures pixels are in the
        // correct orientation and the resulting CIImage has extent at origin (0,0)
        let normalized = normalizedImage()
        guard let cgImage = normalized.cgImage else {
            return normalized.ciImage
        }
        return CIImage(cgImage: cgImage)
    }

    /// Redraws the image with orientation applied to the pixel data
    private func normalizedImage() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(at: .zero)
        }
    }

    func resized(to targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    func aspectFitSize(in boundingSize: CGSize) -> CGSize {
        let widthRatio = boundingSize.width / size.width
        let heightRatio = boundingSize.height / size.height
        let scale = min(widthRatio, heightRatio)
        return CGSize(
            width: size.width * scale,
            height: size.height * scale
        )
    }
}

extension CIImage {
    func toUIImage(context: CIContext) -> UIImage? {
        guard let cgImage = context.createCGImage(self, from: self.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
