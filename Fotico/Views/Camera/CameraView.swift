import SwiftUI
import Combine

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showFilterSheet = false
    @State private var dummyIntensity: Double = 1.0
    @State private var showPaywall = false

    var onPhotoCaptured: ((UIImage) -> Void)?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Live preview — GPU-rendered via MetalImageView (no CGImage creation)
            if let ciImage = viewModel.processedPreviewCIImage {
                MetalImageView(ciImage: ciImage, usesCameraContext: true)
                    .ignoresSafeArea()
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
                modeToggle
                if viewModel.cameraMode == .film {
                    filterButton
                }
                bottomControls
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
        .sheet(isPresented: $showFilterSheet) {
            filterSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .presentationCornerRadius(20)
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
            .accessibilityLabel("Cerrar cámara")

            Spacer()

            // Flash mode
            Button {
                viewModel.cameraService.cycleFlash()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.cameraService.flashMode.icon)
                        .font(.title3)

                    if viewModel.cameraService.flashMode == .vintage {
                        Text("Vintage")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
                .foregroundColor(flashColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.4))
                .cornerRadius(20)
            }
            .accessibilityLabel("Flash: \(viewModel.cameraService.flashMode.displayName)")

            Spacer()

            // Spacer to balance layout (switch camera button is in bottom controls)
            Rectangle()
                .fill(Color.clear)
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var flashColor: Color {
        switch viewModel.cameraService.flashMode {
        case .off: return .white
        case .on: return Color.foticoAccent
        case .auto: return Color.foticoAccent
        case .vintage: return Color.foticoWarning
        }
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            ForEach(CameraMode.allCases, id: \.self) { mode in
                Button {
                    if viewModel.cameraMode != mode {
                        viewModel.toggleMode()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.caption)
                        Text(mode.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(viewModel.cameraMode == mode ? Color.foticoDark : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        viewModel.cameraMode == mode
                        ? Color.foticoPrimary
                        : Color.white.opacity(0.15)
                    )
                }
            }
        }
        .cornerRadius(20)
        .padding(.bottom, 8)
    }

    // MARK: - Filter Button & Sheet

    private var filterButton: some View {
        Button {
            showFilterSheet = true
            HapticManager.selection()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "camera.filters")
                    .font(.caption)
                Text(viewModel.selectedPreset?.displayName ?? "Filtros")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(viewModel.selectedPreset != nil ? .black : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(viewModel.selectedPreset != nil ? Color.foticoPrimary : Color.white.opacity(0.2))
            .cornerRadius(20)
        }
        .padding(.bottom, 8)
    }

    private var filterSheet: some View {
        NavigationStack {
            PresetGridView(
                presets: FilterPreset.allPresets,
                selectedPresetId: viewModel.selectedPreset?.id,
                presetIntensity: $dummyIntensity,
                thumbnails: nil,
                isPro: subscriptionService.isPro,
                showIntensitySlider: false,
                onSelectPreset: { preset in
                    viewModel.selectPreset(preset)
                },
                onDeselectPreset: {
                    viewModel.selectPreset(nil)
                },
                onIntensityChange: nil,
                onLockedPresetTapped: {
                    showFilterSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showPaywall = true
                    }
                }
            )
            .background(Color.foticoCardBg)
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") {
                        showFilterSheet = false
                    }
                    .foregroundColor(Color.foticoPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
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
            // Grain toggle (film mode only)
            if viewModel.cameraMode == .film {
                Button {
                    viewModel.grainOnPreview.toggle()
                    HapticManager.selection()
                } label: {
                    Image(systemName: viewModel.grainOnPreview ? "circle.dotted.circle" : "circle.dotted")
                        .font(.title2)
                        .foregroundColor(viewModel.grainOnPreview ? .white : .white.opacity(0.5))
                        .frame(width: 50, height: 50)
                }
                .accessibilityLabel("Grano: \(viewModel.grainOnPreview ? "activado" : "desactivado")")
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 50, height: 50)
            }

            Spacer()

            // Capture button
            CaptureButtonView(isCapturing: viewModel.isCapturing) {
                Task {
                    await viewModel.capturePhoto()
                }
            }
            .accessibilityLabel("Tomar foto")

            Spacer()

            // Switch camera (selfie)
            Button {
                viewModel.cameraService.switchCamera()
                HapticManager.selection()
            } label: {
                Image(systemName: "camera.rotate.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Cambiar cámara")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    // MARK: - Permission Denied

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("Acceso a la Cámara")
                .font(.title2)
                .foregroundColor(.white)

            Text("Fotico necesita acceso a tu cámara para tomar fotos con efectos vintage.")
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
