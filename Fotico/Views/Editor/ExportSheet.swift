import SwiftUI

struct ExportSheet: View {
    let image: UIImage
    let onSave: () async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .padding()

                // Image info
                VStack(spacing: 8) {
                    HStack {
                        Text("Resolución")
                            .foregroundColor(.lumeTextSecondary)
                        Spacer()
                        Text("\(Int(image.size.width))x\(Int(image.size.height))")
                            .foregroundColor(.white)
                    }
                    .font(.subheadline)

                    Divider().overlay(Color.lumeDivider)

                    HStack {
                        Text("Proporción")
                            .foregroundColor(.lumeTextSecondary)
                        Spacer()
                        Text(aspectRatioLabel(for: image.size))
                            .foregroundColor(.white)
                    }
                    .font(.subheadline)

                    Divider().overlay(Color.lumeDivider)

                    HStack {
                        Text("Formato")
                            .foregroundColor(.lumeTextSecondary)
                        Spacer()
                        Text("HEIC")
                            .foregroundColor(.white)
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color.lumeCardBg)
                .cornerRadius(12)
                .padding(.horizontal)

                // Actions
                VStack(spacing: 12) {
                    Button {
                        isSaving = true
                        Task {
                            await onSave()
                            isSaving = false
                            dismiss()
                        }
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                            }
                            Text("Guardar en Galería")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.lumePrimary)
                        .cornerRadius(12)
                    }
                    .disabled(isSaving)

                    ShareLink(item: Image(uiImage: image), preview: SharePreview("Lumé", image: Image(uiImage: image))) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Compartir")
                        }
                        .font(.headline)
                        .foregroundColor(Color.lumePrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.lumeSurface)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .background(Color.lumeDark.ignoresSafeArea())
            .navigationTitle("Exportar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(Color.lumePrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func aspectRatioLabel(for size: CGSize) -> String {
        let w = Int(size.width)
        let h = Int(size.height)
        let d = gcd(w, h)
        guard d > 0 else { return "\(w):\(h)" }
        let rw = w / d
        let rh = h / d
        // Simplify common ratios
        if rw == 4 && rh == 3 { return "4:3" }
        if rw == 3 && rh == 2 { return "3:2" }
        if rw == 16 && rh == 9 { return "16:9" }
        if rw == 1 && rh == 1 { return "1:1" }
        return "\(rw):\(rh)"
    }

    private func gcd(_ a: Int, _ b: Int) -> Int {
        b == 0 ? a : gcd(b, a % b)
    }
}
