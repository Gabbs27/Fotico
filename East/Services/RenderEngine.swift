import Metal
import CoreImage
import UIKit

/// Singleton render engine providing shared Metal device, command queue, and CIContexts.
/// CIContext creation is expensive (~50-100ms). This ensures we create them once.
///
/// Two contexts are provided:
/// - `context`: For photo editing — caches intermediates for fast re-renders on parameter changes
/// - `cameraContext`: For camera preview — no caching (new image every frame)
final class RenderEngine: @unchecked Sendable {
    static let shared = RenderEngine()

    let device: MTLDevice
    let commandQueue: MTLCommandQueue

    /// Editing context — caches intermediates, half-float precision, high priority
    let context: CIContext

    /// Camera preview context — no caching, lower memory footprint
    let cameraContext: CIContext

    private init() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device
        self.commandQueue = queue

        // Editor context: cache intermediates for slider-driven re-renders
        self.context = CIContext(mtlDevice: device, options: [
            .workingFormat: CIFormat.RGBAh,           // Half-float (16-bit) — 50% less memory
            .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
            .cacheIntermediates: true,                 // Cache for repeated renders
            .priorityRequestLow: false,
        ])

        // Camera context: no caching — new image every frame
        self.cameraContext = CIContext(mtlDevice: device, options: [
            .workingFormat: CIFormat.RGBAh,
            .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
            .cacheIntermediates: false,                // New image every frame
            .priorityRequestLow: false,
        ])

        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearCaches()
        }
    }

    func clearCaches() {
        context.clearCaches()
        cameraContext.clearCaches()
    }
}
