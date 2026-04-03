import Metal
import CoreImage
import UIKit

/// Metal compute shader service for custom GPU effects.
/// Uses shared RenderEngine device and command queue.
/// Not bound to @MainActor — Metal operations are thread-safe via their own command queue.
/// The texture pool is only accessed from the render queue, so no main-thread contention.
class MetalKernelService {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary?

    private var grainPipeline: MTLComputePipelineState?
    private var lightLeakPipeline: MTLComputePipelineState?
    private var bloomThresholdPipeline: MTLComputePipelineState?
    private var bloomBlurPipeline: MTLComputePipelineState?
    private var bloomCompositePipeline: MTLComputePipelineState?
    private var hslPipelineState: MTLComputePipelineState?

    // Texture pool for reuse (avoids per-frame allocation)
    // Capped at maxPoolSize to prevent unbounded GPU memory growth.
    private static let maxPoolSize = 6
    private var texturePool: [String: MTLTexture] = [:]
    private var texturePoolOrder: [String] = []  // LRU eviction order

    private var memoryWarningObserver: Any?

    init() {
        let engine = RenderEngine.shared
        self.device = engine.device
        self.commandQueue = engine.commandQueue
        self.library = device.makeDefaultLibrary()

        setupPipelines()

        // Clear texture pool on memory warning
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearTexturePool()
        }
    }

    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func clearTexturePool() {
        texturePool.removeAll()
        texturePoolOrder.removeAll()
    }

    private func setupPipelines() {
        guard let library = library else { return }

        if let fn = library.makeFunction(name: "grainKernel") {
            grainPipeline = try? device.makeComputePipelineState(function: fn)
        }
        if let fn = library.makeFunction(name: "lightLeakKernel") {
            lightLeakPipeline = try? device.makeComputePipelineState(function: fn)
        }
        if let fn = library.makeFunction(name: "bloomThresholdKernel") {
            bloomThresholdPipeline = try? device.makeComputePipelineState(function: fn)
        }
        if let fn = library.makeFunction(name: "bloomBlurKernel") {
            bloomBlurPipeline = try? device.makeComputePipelineState(function: fn)
        }
        if let fn = library.makeFunction(name: "bloomCompositeKernel") {
            bloomCompositePipeline = try? device.makeComputePipelineState(function: fn)
        }
        if let fn = library.makeFunction(name: "hslAdjustKernel") {
            hslPipelineState = try? device.makeComputePipelineState(function: fn)
        }
    }

    // MARK: - Grain Effect

    /// Applies grain effect using Metal compute shader.
    /// Returns the result asynchronously to avoid blocking the main thread.
    func applyGrain(to ciImage: CIImage, intensity: Float, grainSize: Float, context: CIContext) async -> CIImage {
        guard let pipeline = grainPipeline else { return ciImage }

        let width = Int(ciImage.extent.width)
        let height = Int(ciImage.extent.height)

        guard let inTexture = makeTexture(from: ciImage, context: context),
              let outTexture = getPooledTexture(width: width, height: height, key: "grainOut") else {
            return ciImage
        }

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else { return ciImage }

        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(inTexture, index: 0)
        encoder.setTexture(outTexture, index: 1)

        var intensityVal = intensity
        var grainSizeVal = max(grainSize * 40.0, 1.0)
        var seed = Float.random(in: 0...100)
        encoder.setBytes(&intensityVal, length: MemoryLayout<Float>.size, index: 0)
        encoder.setBytes(&grainSizeVal, length: MemoryLayout<Float>.size, index: 1)
        encoder.setBytes(&seed, length: MemoryLayout<Float>.size, index: 2)

        dispatchThreads(encoder: encoder, pipeline: pipeline, width: width, height: height)
        encoder.endEncoding()

        // Async wait — does NOT block the main thread
        commandBuffer.commit()
        await withCheckedContinuation { continuation in
            commandBuffer.addCompletedHandler { _ in
                continuation.resume()
            }
        }

        return CIImage(mtlTexture: outTexture, options: [.colorSpace: CGColorSpaceCreateDeviceRGB()])?.oriented(.downMirrored) ?? ciImage
    }

    // MARK: - Texture Helpers

    /// Get or create a pooled texture — avoids per-frame allocation.
    /// Uses LRU eviction when pool exceeds maxPoolSize.
    private func getPooledTexture(width: Int, height: Int, key: String) -> MTLTexture? {
        let poolKey = "\(key)_\(width)x\(height)"
        if let existing = texturePool[poolKey],
           existing.width == width, existing.height == height {
            // Move to end of LRU order (most recently used)
            if let idx = texturePoolOrder.firstIndex(of: poolKey) {
                texturePoolOrder.remove(at: idx)
            }
            texturePoolOrder.append(poolKey)
            return existing
        }

        // Evict oldest entries if pool is full
        while texturePool.count >= Self.maxPoolSize, let oldest = texturePoolOrder.first {
            texturePool.removeValue(forKey: oldest)
            texturePoolOrder.removeFirst()
        }

        guard let texture = makeEmptyTexture(width: width, height: height) else { return nil }
        texturePool[poolKey] = texture
        texturePoolOrder.append(poolKey)
        return texture
    }

    private func makeTexture(from ciImage: CIImage, context: CIContext) -> MTLTexture? {
        let width = Int(ciImage.extent.width)
        let height = Int(ciImage.extent.height)

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead]

        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }

        context.render(
            ciImage,
            to: texture,
            commandBuffer: nil,
            bounds: ciImage.extent,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        return texture
    }

    private func makeEmptyTexture(width: Int, height: Int) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.shaderWrite, .shaderRead]
        return device.makeTexture(descriptor: descriptor)
    }

    // MARK: - HSL Adjustment

    /// Applies per-color HSL adjustments using Metal compute shader.
    func applyHSL(to ciImage: CIImage, adjustments: [String: HSLAdjustment], context: CIContext) async -> CIImage {
        guard let pipeline = hslPipelineState, !adjustments.isEmpty else { return ciImage }

        let width = Int(ciImage.extent.width)
        let height = Int(ciImage.extent.height)

        guard let inTexture = makeTexture(from: ciImage, context: context),
              let outTexture = getPooledTexture(width: width, height: height, key: "hslOut") else {
            return ciImage
        }

        // Build params
        var params = MetalHSLParams()
        var index: UInt32 = 0
        for (colorKey, adj) in adjustments {
            guard let color = HSLColorRange(rawValue: colorKey), !adj.isDefault, index < 8 else { continue }
            let i = Int(index)
            withUnsafeMutablePointer(to: &params.hueCenters) {
                $0.withMemoryRebound(to: Float.self, capacity: 8) { $0[i] = color.hueCenter }
            }
            withUnsafeMutablePointer(to: &params.hueShifts) {
                $0.withMemoryRebound(to: Float.self, capacity: 8) { $0[i] = Float(adj.hue) }
            }
            withUnsafeMutablePointer(to: &params.satShifts) {
                $0.withMemoryRebound(to: Float.self, capacity: 8) { $0[i] = Float(adj.saturation) }
            }
            withUnsafeMutablePointer(to: &params.lumShifts) {
                $0.withMemoryRebound(to: Float.self, capacity: 8) { $0[i] = Float(adj.luminance) }
            }
            index += 1
        }
        params.activeCount = index

        guard params.activeCount > 0 else { return ciImage }

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else { return ciImage }

        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(inTexture, index: 0)
        encoder.setTexture(outTexture, index: 1)
        encoder.setBytes(&params, length: MemoryLayout<MetalHSLParams>.size, index: 0)

        dispatchThreads(encoder: encoder, pipeline: pipeline, width: width, height: height)
        encoder.endEncoding()

        commandBuffer.commit()
        await withCheckedContinuation { continuation in
            commandBuffer.addCompletedHandler { _ in
                continuation.resume()
            }
        }

        return CIImage(mtlTexture: outTexture, options: [.colorSpace: CGColorSpaceCreateDeviceRGB()])?.oriented(.downMirrored) ?? ciImage
    }

    private func dispatchThreads(encoder: MTLComputeCommandEncoder, pipeline: MTLComputePipelineState, width: Int, height: Int) {
        let threadgroupSize = MTLSize(
            width: min(pipeline.threadExecutionWidth, width),
            height: min(pipeline.maxTotalThreadsPerThreadgroup / pipeline.threadExecutionWidth, height),
            depth: 1
        )
        let threadgroups = MTLSize(
            width: (width + threadgroupSize.width - 1) / threadgroupSize.width,
            height: (height + threadgroupSize.height - 1) / threadgroupSize.height,
            depth: 1
        )
        encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)
    }
}

/// Swift representation of Metal HSLParams struct — must match layout exactly.
struct MetalHSLParams {
    var hueCenters: (Float, Float, Float, Float, Float, Float, Float, Float) = (0,0,0,0,0,0,0,0)
    var hueShifts: (Float, Float, Float, Float, Float, Float, Float, Float) = (0,0,0,0,0,0,0,0)
    var satShifts: (Float, Float, Float, Float, Float, Float, Float, Float) = (0,0,0,0,0,0,0,0)
    var lumShifts: (Float, Float, Float, Float, Float, Float, Float, Float) = (0,0,0,0,0,0,0,0)
    var activeCount: UInt32 = 0
}
