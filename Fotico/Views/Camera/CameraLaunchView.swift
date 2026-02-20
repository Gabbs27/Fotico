import SwiftUI

struct CameraLaunchView: View {
    @State private var showCamera = false
    var onPhotoCaptured: ((UIImage) -> Void)?

    var body: some View {
        ZStack {
            Color.lumeDark.ignoresSafeArea()
            if !showCamera {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.lumePrimary)
                    Button("Abrir Cámara") {
                        showCamera = true
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.lumePrimary)
                    .cornerRadius(12)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                showCamera = false
                onPhotoCaptured?(image)
            }
        }
        .onAppear {
            showCamera = true
        }
    }
}
