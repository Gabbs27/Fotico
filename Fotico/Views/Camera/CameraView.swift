import SwiftUI
import Combine

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    var onPhotoCaptured: ((UIImage) -> Void)?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Live preview -- GPU-rendered via MetalImageView (no CGImage creation)
            if let ciImage = viewModel.processedPreviewCIImage {
                ZStack {
                    MetalImageView(ciImage: ciImage, usesCameraContext: true)
                        .ignoresSafeArea()

                    GridOverlayView(mode: viewModel.gridMode)
                }
            } else if !viewModel.cameraService.permissionGranted {
                permissionDeniedView
            } else {
                ProgressView()
                    .tint(Color.foticoPrimary)
            }

            // Flash overlay animation
            if viewModel.showFlashOverlay {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.15), value: viewModel.showFlashOverlay)
            }

            // UI Controls
            VStack(spacing: 0) {
                topControls
                Spacer()
                zoomControls
                cameraTypeStrip
                    .padding(.bottom, 8)
                bottomControls
                CameraToolbarView(
                    selectedTab: $viewModel.selectedToolbarTab,
                    selectedFrame: $viewModel.selectedFrame,
                    gridMode: $viewModel.gridMode,
                    grainLevel: $viewModel.grainLevel,
                    lightLeakOn: $viewModel.toolbarLightLeakOn,
                    vignetteOn: $viewModel.toolbarVignetteOn,
                    bloomOn: $viewModel.toolbarBloomOn,
                    flashMode: viewModel.cameraService.flashMode,
                    onFlashSet: { mode in
                        viewModel.cameraService.flashMode = mode
                        HapticManager.selection()
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.startCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            viewModel.stopCamera()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { await viewModel.startCamera() }
        }
        .onChange(of: viewModel.showEditor) { _, showEditor in
            if showEditor, let image = viewModel.capturedImage {
                onPhotoCaptured?(image)
                dismiss()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Top Controls

    private var topControls: some View {
        HStack {
            // Close
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Cerrar camara")

            Spacer()

            // Switch camera
            Button {
                viewModel.cameraService.switchCamera()
                HapticManager.selection()
            } label: {
                Image(systemName: "camera.rotate.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Cambiar camara")
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Camera Type Strip

    private var cameraTypeStrip: some View {
        CameraTypeStripView(
            cameraTypes: CameraType.allTypes,
            selectedId: viewModel.selectedCameraType.id,
            onSelect: { cameraType in
                viewModel.selectCameraType(cameraType)
            }
        )
    }

    // MARK: - Zoom Controls

    private var zoomControls: some View {
        HStack(spacing: 12) {
            ForEach(viewModel.cameraService.zoomLevels) { level in
                zoomButton(level: level)
            }
        }
        .padding(.bottom, 12)
    }

    private func zoomButton(level: ZoomLevel) -> some View {
        let isActive = closestZoomLevel?.id == level.id
        return Button {
            HapticManager.selection()
            viewModel.cameraService.setZoom(level.factor)
        } label: {
            Text(level.label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isActive ? .black : .white)
                .frame(width: 36, height: 36)
                .background(isActive ? Color.white : Color.white.opacity(0.2))
                .clipShape(Circle())
        }
    }

    /// Find the closest zoom level to the current zoom factor
    private var closestZoomLevel: ZoomLevel? {
        let levels = viewModel.cameraService.zoomLevels
        let current = viewModel.cameraService.currentZoom
        guard !levels.isEmpty else { return nil }
        return levels.min(by: { abs($0.factor - current) < abs($1.factor - current) })
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack {
            // Spacer for balance
            Rectangle()
                .fill(Color.clear)
                .frame(width: 50, height: 50)

            Spacer()

            // Capture button
            CaptureButtonView(isCapturing: viewModel.isCapturing) {
                Task {
                    await viewModel.capturePhoto()
                }
            }
            .accessibilityLabel("Tomar foto")

            Spacer()

            // Spacer for balance
            Rectangle()
                .fill(Color.clear)
                .frame(width: 50, height: 50)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    // MARK: - Permission Denied

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("Acceso a la Camara")
                .font(.title2)
                .foregroundColor(.white)

            Text("Fotico necesita acceso a tu camara para tomar fotos con efectos vintage.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Abrir Ajustes")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
    }
}
