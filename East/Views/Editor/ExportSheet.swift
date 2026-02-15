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
                        Text("Resolucion")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(Int(image.size.width))x\(Int(image.size.height))")
                            .foregroundColor(.white)
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color.eastCardBg)
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
                            Text("Guardar en Galeria")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .disabled(isSaving)

                    ShareLink(item: Image(uiImage: image), preview: SharePreview("East Photo", image: Image(uiImage: image))) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Compartir")
                        }
                        .font(.headline)
                        .foregroundColor(Color.eastPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.eastSurface)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .background(Color.eastDark.ignoresSafeArea())
            .navigationTitle("Exportar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(Color.eastPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
