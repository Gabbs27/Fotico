@preconcurrency import AVFoundation
import UIKit
import CoreImage
import Combine

/// Represents a zoom button with display label and actual zoom factor
struct ZoomLevel: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let factor: CGFloat

    static func == (lhs: ZoomLevel, rhs: ZoomLevel) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
class CameraService: NSObject, ObservableObject {
    @Published var previewCIImage: CIImage?
    @Published var capturedPhoto: UIImage?
    @Published var isRunning = false
    @Published var flashMode: FlashStyle = .off
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    @Published var permissionGranted = false
    @Published var errorMessage: String?
    @Published var currentZoom: CGFloat = 1.0
    @Published var hasUltraWide = false
    @Published var minZoom: CGFloat = 1.0
    @Published var maxZoom: CGFloat = 5.0
    @Published var zoomLevels: [ZoomLevel] = []

    // AVCaptureSession is internally thread-safe; we access it from processingQueue
    // for start/stop but configure it on main thread.
    nonisolated(unsafe) private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "com.fotico.camera", qos: .userInitiated)
    private var currentDevice: AVCaptureDevice?
    private var photoContinuation: CheckedContinuation<UIImage?, Never>?

    // MARK: - Permissions

    func requestPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            permissionGranted = await AVCaptureDevice.requestAccess(for: .video)
        default:
            permissionGranted = false
            errorMessage = "Se necesita acceso a la camara. Activalo en Ajustes."
        }
    }

    // MARK: - Session Setup

    func setupSession() {
        guard permissionGranted else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        // Camera input
        guard let device = bestCamera(for: cameraPosition) else {
            errorMessage = "No se encontro camara disponible"
            session.commitConfiguration()
            return
        }
        currentDevice = device
        minZoom = device.minAvailableVideoZoomFactor
        maxZoom = min(device.maxAvailableVideoZoomFactor, 10.0)
        configureZoomLevels(for: device)

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            errorMessage = "Error al configurar la camara"
            session.commitConfiguration()
            return
        }

        // Photo output — don't override maxPhotoDimensions so the system
        // picks the right resolution for the current zoom on virtual devices
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        // Video data output for live preview
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        // Fix orientation
        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 90
        }

        session.commitConfiguration()

        // Start at "1x" (wide lens) by default — use direct set, not ramp
        if let wideFactor = zoomLevels.first(where: { $0.label == "1x" })?.factor {
            setZoom(wideFactor, animated: false)
        }
    }

    func startSession() {
        guard !isRunning else { return }
        let captureSession = session
        processingQueue.async { [weak self] in
            captureSession.startRunning()
            Task { @MainActor in
                guard let self else { return }
                self.isRunning = true
                // Re-apply zoom after session starts running — some devices
                // reset videoZoomFactor when the session begins.
                self.setZoom(self.currentZoom, animated: false)
            }
        }
    }

    func stopSession() {
        guard isRunning else { return }
        let captureSession = session
        processingQueue.async { [weak self] in
            captureSession.stopRunning()
            Task { @MainActor in
                self?.isRunning = false
            }
        }
    }

    // MARK: - Camera Controls

    func switchCamera() {
        let newPosition: AVCaptureDevice.Position = cameraPosition == .back ? .front : .back
        cameraPosition = newPosition

        session.beginConfiguration()

        // Remove existing input
        for input in session.inputs {
            session.removeInput(input)
        }

        guard let device = bestCamera(for: newPosition) else {
            session.commitConfiguration()
            return
        }
        currentDevice = device
        minZoom = device.minAvailableVideoZoomFactor
        maxZoom = min(device.maxAvailableVideoZoomFactor, 10.0)
        configureZoomLevels(for: device)
        // Set zoom to "1x" equivalent (wide lens)
        if let wideLevelFactor = zoomLevels.first(where: { $0.label == "1x" })?.factor {
            currentZoom = wideLevelFactor
        } else {
            currentZoom = 1.0
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            errorMessage = "Error al cambiar camara"
        }

        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 90
            if newPosition == .front {
                connection.isVideoMirrored = true
            }
        }

        session.commitConfiguration()

        // After committing, set zoom to "1x" equivalent — direct set
        if let wideFactor = zoomLevels.first(where: { $0.label == "1x" })?.factor {
            setZoom(wideFactor, animated: false)
        }
    }

    func cycleFlash() {
        let allModes = FlashStyle.allCases
        guard let currentIndex = allModes.firstIndex(of: flashMode) else { return }
        let nextIndex = (currentIndex + 1) % allModes.count
        flashMode = allModes[nextIndex]
        HapticManager.selection()
    }

    func setZoom(_ factor: CGFloat, animated: Bool = true) {
        guard let device = currentDevice else { return }
        do {
            try device.lockForConfiguration()
            let clamped = max(device.minAvailableVideoZoomFactor, min(factor, min(device.maxAvailableVideoZoomFactor, 10.0)))
            if animated {
                device.ramp(toVideoZoomFactor: clamped, withRate: 8.0)
            } else {
                device.videoZoomFactor = clamped
            }
            device.unlockForConfiguration()
            currentZoom = clamped
        } catch {
            // Silently fail — zoom is non-critical
        }
    }

    /// Configures zoom levels based on the device's virtual camera switch-over points.
    /// On builtInTripleCamera (iPhone 15 Pro):
    ///   - factor 1.0 = ultra-wide ("0.5x")
    ///   - factor 2.0 = wide ("1x") — first switchover
    ///   - factor 4.0 = 2x crop of wide ("2x")
    ///   - factor 6.0 = telephoto ("3x") — second switchover
    /// On builtInDualWideCamera:
    ///   - factor 1.0 = ultra-wide ("0.5x")
    ///   - factor 2.0 = wide ("1x") — switchover
    /// On simple wide-angle (front camera, older devices):
    ///   - factor 1.0 = "1x"
    ///   - factor 2.0 = "2x"
    private func configureZoomLevels(for device: AVCaptureDevice) {
        let switchOverFactors = device.virtualDeviceSwitchOverVideoZoomFactors

        var levels: [ZoomLevel] = []

        if !switchOverFactors.isEmpty {
            hasUltraWide = true
            levels.append(ZoomLevel(id: "uw", label: ".5", factor: 1.0))

            let firstSwitchOver = CGFloat(truncating: switchOverFactors[0])
            levels.append(ZoomLevel(id: "wide", label: "1x", factor: firstSwitchOver))

            if switchOverFactors.count >= 2 {
                let secondSwitchOver = CGFloat(truncating: switchOverFactors[1])
                let twoXFactor = firstSwitchOver * 2.0
                if twoXFactor < secondSwitchOver {
                    levels.append(ZoomLevel(id: "2x", label: "2x", factor: twoXFactor))
                }
                levels.append(ZoomLevel(id: "tele", label: "3x", factor: secondSwitchOver))
            } else {
                let twoXFactor = firstSwitchOver * 2.0
                levels.append(ZoomLevel(id: "2x", label: "2x", factor: twoXFactor))
            }
        } else {
            hasUltraWide = false
            levels.append(ZoomLevel(id: "wide", label: "1x", factor: 1.0))
            if device.maxAvailableVideoZoomFactor >= 2.0 {
                levels.append(ZoomLevel(id: "2x", label: "2x", factor: 2.0))
            }
        }

        zoomLevels = levels
    }

    // MARK: - Photo Capture

    func capturePhoto() async -> UIImage? {
        // Force-apply zoom right before capture
        setZoom(currentZoom, animated: false)

        return await withCheckedContinuation { continuation in
            self.photoContinuation = continuation

            let settings = AVCapturePhotoSettings()

            // Configure flash
            if let device = currentDevice, device.hasFlash {
                switch flashMode {
                case .off:
                    settings.flashMode = .off
                case .on, .vintage:
                    settings.flashMode = .on
                case .auto:
                    settings.flashMode = .auto
                }
            }

            // Don't set maxPhotoDimensions on settings — let AVFoundation
            // decide the correct resolution for the current zoom level.
            // Setting max dims on virtual multi-camera devices can cause
            // the capture to return the full sensor ignoring zoom crop.

            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // MARK: - Helpers

    private func bestCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let preferredTypes: [AVCaptureDevice.DeviceType] = [
            .builtInTripleCamera,
            .builtInDualWideCamera,
            .builtInDualCamera,
            .builtInWideAngleCamera
        ]

        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: preferredTypes,
            mediaType: .video,
            position: position
        )

        for type in preferredTypes {
            if let device = discovery.devices.first(where: { $0.deviceType == type }) {
                return device
            }
        }

        return AVCaptureDevice.default(for: .video)
    }
}

// MARK: - Video Data Output Delegate (Live Preview Frames)

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        Task { @MainActor in
            self.previewCIImage = ciImage
        }
    }
}

// MARK: - Photo Capture Delegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let photoData = photo.fileDataRepresentation()

        Task { @MainActor in
            if let error = error {
                self.errorMessage = "Error al capturar foto: \(error.localizedDescription)"
                self.photoContinuation?.resume(returning: nil)
                self.photoContinuation = nil
                return
            }

            guard let data = photoData,
                  let image = UIImage(data: data) else {
                self.photoContinuation?.resume(returning: nil)
                self.photoContinuation = nil
                return
            }

            self.capturedPhoto = image
            self.photoContinuation?.resume(returning: image)
            self.photoContinuation = nil
        }
    }
}

// MARK: - Flash Style

enum FlashStyle: String, CaseIterable, Sendable {
    case off
    case on
    case auto
    case vintage

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .on: return "On"
        case .auto: return "Auto"
        case .vintage: return "Vintage"
        }
    }

    var icon: String {
        switch self {
        case .off: return "bolt.slash.fill"
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.automatic.fill"
        case .vintage: return "bolt.badge.clock.fill"
        }
    }
}
