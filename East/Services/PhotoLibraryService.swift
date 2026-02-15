import UIKit
import SwiftUI
import PhotosUI
import Photos
import Combine

@MainActor
class PhotoLibraryService: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined

    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        authorizationStatus = status
        return status
    }

    func saveToPhotoLibrary(_ image: UIImage) async throws {
        let status = await requestAuthorization()
        guard status == .authorized || status == .limited else {
            throw PhotoLibraryError.notAuthorized
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    func loadImage(from item: PhotosPickerItem) async throws -> UIImage {
        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw PhotoLibraryError.loadFailed
        }
        guard let image = UIImage(data: data) else {
            throw PhotoLibraryError.invalidImage
        }
        return image
    }
}

enum PhotoLibraryError: LocalizedError {
    case notAuthorized
    case loadFailed
    case invalidImage
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "No tienes permiso para acceder a la galeria"
        case .loadFailed: return "No se pudo cargar la imagen"
        case .invalidImage: return "La imagen no es valida"
        case .saveFailed: return "No se pudo guardar la imagen"
        }
    }
}
