import SwiftUI
import PhotosUI
import Combine

@MainActor
class GalleryViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var recentProjects: [PhotoProject] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let libraryService = PhotoLibraryService()
    private let storageService = ProjectStorageService()

    func loadSelectedImage() async {
        guard let item = selectedItem else { return }
        isLoading = true

        do {
            let image = try await libraryService.loadImage(from: item)
            selectedImage = image
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadRecentProjects() {
        recentProjects = storageService.listProjects()
    }

    func deleteProject(_ project: PhotoProject) {
        try? storageService.deleteProject(id: project.id)
        recentProjects.removeAll { $0.id == project.id }
    }
}
