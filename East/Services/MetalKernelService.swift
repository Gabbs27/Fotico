import Metal
import CoreImage

/// Metal compute shader service for custom GPU effects.
/// Uses shared RenderEngine device and command queue.
@MainActor
class MetalKernelService {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary?

    private var grainPipeline: MTLComputePipelineState?
    private var lightLeakPipeline: MTLComputePipelineState?
    private var bloomThresholdPipeline: MTLComputePipelineState?
    private var bloomBlurPipeline: MTLComputePipelineState?
    private var bloomCompositePipeline: MTLComputePipelineState?

    // Texture pool for reuse (avoids per-frame allocation)
    private var texturePool: [String: MTLTexture] = [:]

    init() {
        let engine = RenderEngine.shared
        self.device = engine.device
        self.commandQueue = engine.commandQueue
        self.library = device.makeDefaultLibrary()

        setupPipelines()
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
    }

    // MARK: - Grain Effect

    func applyGrain(to ciImage: CIImage, intensity: Float, grainSize: Float, context: CIContext) -> CIImage {
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

        // Use completion handler instead of synchronous wait
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return CIImage(mtlTexture: outTexture, options: [.colorSpace: CGColorSpaceCreateDeviceRGB()])?.oriented(.downMirrored) ?? ciImage
    }

    // MARK: - Texture Helpers

    /// Get or create a pooled texture — avoids per-frame allocation
    private func getPooledTexture(width: Int, height: Int, key: String) -> MTLTexture? {
        let poolKey = "\(key)_\(width)x\(height)"
        if let existing = texturePool[poolKey],
           existing.width == width, existing.height == height {
            return existing
        }
        guard let texture = makeEmptyTexture(width: width, height: height) else { return nil }
        texturePool[poolKey] = texture
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
