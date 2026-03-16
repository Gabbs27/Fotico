import SwiftUI
import SwiftData

@MainActor
class ProjectsViewModel: ObservableObject {
    @Published var projects: [PhotoProject] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchProjects()
    }

    func fetchProjects() {
        guard let context = modelContext else { return }
        isLoading = true
        defer { isLoading = false }
        let descriptor = FetchDescriptor<PhotoProject>(sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)])
        do {
            projects = try context.fetch(descriptor)
        } catch {
            errorMessage = "No se pudieron cargar los proyectos"
            projects = []
        }
    }

    func saveProject(name: String, image: UIImage, editState: EditState) {
        guard let context = modelContext else { return }

        let projectId = UUID().uuidString
        guard let imagePath = ProjectStorageService.shared.saveOriginalImage(image, projectId: projectId) else {
            errorMessage = "No se pudo guardar la imagen"
            return
        }

        guard let editStateData = try? JSONEncoder().encode(editState) else {
            errorMessage = "No se pudo codificar el estado de edición"
            return
        }
        let project = PhotoProject(name: name, originalImagePath: imagePath, editStateData: editStateData)
        project.thumbnailData = ProjectStorageService.shared.generateThumbnail(image)

        context.insert(project)
        do {
            try context.save()
        } catch {
            errorMessage = "No se pudo guardar el proyecto"
        }
        fetchProjects()
    }

    func deleteProject(_ project: PhotoProject) {
        guard let context = modelContext else { return }
        ProjectStorageService.shared.deleteImage(fileName: project.originalImagePath)
        context.delete(project)
        do {
            try context.save()
        } catch {
            errorMessage = "No se pudo eliminar el proyecto"
        }
        fetchProjects()
    }

    func loadProjectImage(_ project: PhotoProject) -> UIImage? {
        return ProjectStorageService.shared.loadOriginalImage(fileName: project.originalImagePath)
    }
}
