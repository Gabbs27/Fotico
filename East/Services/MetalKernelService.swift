import Metal
import CoreImage

@MainActor
class MetalKernelService {
    private let device: MTLDevice?
    private let commandQueue: MTLCommandQueue?
    private let library: MTLLibrary?

    private var grainPipeline: MTLComputePipelineState?
    private var lightLeakPipeline: MTLComputePipelineState?
    private var bloomThresholdPipeline: MTLComputePipelineState?
    private var bloomBlurPipeline: MTLComputePipelineState?
    private var bloomCompositePipeline: MTLComputePipelineState?

    init() {
        self.device = MTLCreateSystemDefaultDevice()
        self.commandQueue = device?.makeCommandQueue()
        self.library = device?.makeDefaultLibrary()

        setupPipelines()
    }

    private func setupPipelines() {
        guard let library = library, let device = device else { return }

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
        guard let device = device,
              let commandQueue = commandQueue,
              let pipeline = grainPipeline else { return ciImage }

        let width = Int(ciImage.extent.width)
        let height = Int(ciImage.extent.height)

        guard let inTexture = makeTexture(from: ciImage, context: context, device: device),
              let outTexture = makeEmptyTexture(width: width, height: height, device: device) else {
            return ciImage
        }

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else { return ciImage }

        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(inTexture, index: 0)
        encoder.setTexture(outTexture, index: 1)

        var intensityVal = intensity
        var grainSizeVal = max(grainSize * 40.0, 1.0) // Scale to pixel size
        var seed = Float.random(in: 0...100)
        encoder.setBytes(&intensityVal, length: MemoryLayout<Float>.size, index: 0)
        encoder.setBytes(&grainSizeVal, length: MemoryLayout<Float>.size, index: 1)
        encoder.setBytes(&seed, length: MemoryLayout<Float>.size, index: 2)

        dispatchThreads(encoder: encoder, pipeline: pipeline, width: width, height: height)
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return CIImage(mtlTexture: outTexture, options: [.colorSpace: CGColorSpaceCreateDeviceRGB()])?.oriented(.downMirrored) ?? ciImage
    }

    // MARK: - Texture Helpers

    private func makeTexture(from ciImage: CIImage, context: CIContext, device: MTLDevice) -> MTLTexture? {
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

    private func makeEmptyTexture(width: Int, height: Int, device: MTLDevice) -> MTLTexture? {
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
