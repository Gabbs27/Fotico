import SwiftUI

struct CameraLaunchView: View {
    @State private var showCamera = false

    var body: some View {
        ZStack {
            Color.foticoDark.ignoresSafeArea()
            if !showCamera {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.foticoPrimary)
                    Button("Abrir Cámara") {
                        showCamera = true
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(12)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { _ in showCamera = false }
        }
    }
}
