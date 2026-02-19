import CoreImage
import UIKit

/// Parses .cube LUT files and applies them via CIColorCubeWithColorSpace.
/// Caches parsed LUT data in memory to avoid re-parsing on every render.
/// Thread-safe: parsed data is immutable [Float] arrays cached in NSCache.
final class LUTService: @unchecked Sendable {
    static let shared = LUTService()

    // Cache of parsed LUT data: [fileName: LUTData]
    private let cache = NSCache<NSString, LUTData>()
    private let colorSpace = CGColorSpaceCreateDeviceRGB()

    private init() {
        cache.countLimit = 20  // Keep at most 20 LUTs in memory
    }

    /// Apply a .cube LUT to a CIImage. Returns original if LUT fails.
    func applyLUT(named fileName: String, to image: CIImage, intensity: Double = 1.0) -> CIImage {
        guard let lutData = loadLUT(named: fileName) else { return image }

        let filter = CIFilter(name: "CIColorCubeWithColorSpace")!
        filter.setValue(lutData.size, forKey: "inputCubeDimension")
        filter.setValue(lutData.data, forKey: "inputCubeData")
        filter.setValue(colorSpace, forKey: "inputColorSpace")
        filter.setValue(image, forKey: kCIInputImageKey)

        guard let filtered = filter.outputImage else { return image }

        // Blend with original based on intensity
        if intensity < 1.0 {
            let blend = CIFilter(name: "CIDissolveTransition")!
            blend.setValue(image, forKey: kCIInputImageKey)
            blend.setValue(filtered, forKey: kCIInputTargetImageKey)
            blend.setValue(intensity, forKey: kCIInputTimeKey)
            return blend.outputImage ?? filtered
        }

        return filtered
    }

    /// Load and cache parsed LUT data from bundle
    private func loadLUT(named fileName: String) -> LUTData? {
        let key = fileName as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        // Try free/ then pro/ subdirectories, then root
        let nameWithoutExt = (fileName as NSString).deletingPathExtension
        guard let url = Bundle.main.url(forResource: nameWithoutExt, withExtension: "cube", subdirectory: "LUTs/free")
                ?? Bundle.main.url(forResource: nameWithoutExt, withExtension: "cube", subdirectory: "LUTs/pro")
                ?? Bundle.main.url(forResource: nameWithoutExt, withExtension: "cube") else {
            print("[LUTService] LUT file not found: \(fileName)")
            return nil
        }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        guard let parsed = parseCubeFile(content) else { return nil }

        cache.setObject(parsed, forKey: key)
        return parsed
    }

    /// Parse .cube format into (dimension, float array as Data)
    private func parseCubeFile(_ content: String) -> LUTData? {
        var size = 0
        var values: [Float] = []

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix("TITLE") { continue }

            if trimmed.hasPrefix("LUT_3D_SIZE") {
                let parts = trimmed.split(separator: " ")
                if parts.count >= 2, let s = Int(parts[1]) {
                    size = s
                    values.reserveCapacity(size * size * size * 4)
                }
                continue
            }

            // Skip other metadata lines
            if trimmed.hasPrefix("DOMAIN_") { continue }

            let parts = trimmed.split(separator: " ")
            if parts.count >= 3,
               let r = Float(parts[0]),
               let g = Float(parts[1]),
               let b = Float(parts[2]) {
                values.append(r)
                values.append(g)
                values.append(b)
                values.append(1.0)  // Alpha
            }
        }

        guard size > 0, values.count == size * size * size * 4 else {
            print("[LUTService] Invalid LUT: expected \(size*size*size*4) values, got \(values.count)")
            return nil
        }

        let data = values.withUnsafeBufferPointer { Data(buffer: $0) }
        return LUTData(size: size, data: data)
    }
}

/// Wrapper class for NSCache (requires reference type)
private final class LUTData: @unchecked Sendable {
    let size: Int
    let data: Data

    init(size: Int, data: Data) {
        self.size = size
        self.data = data
    }
}
