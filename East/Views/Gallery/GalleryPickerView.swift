import SwiftUI
import PhotosUI

struct GalleryPickerView: View {
    @Binding var selectedItem: PhotosPickerItem?
    let onImageSelected: (UIImage) -> Void

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            VStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 40))
                    .foregroundColor(Color.eastPrimary)

                Text("Seleccionar de la Galeria")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Color.eastCardBg)
            .cornerRadius(16)
        }
        .onChange(of: selectedItem) { _, newValue in
            guard let item = newValue else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    onImageSelected(image)
                }
            }
        }
    }
}
