import SwiftUI
import SwiftData

@MainActor
@Observable class ProjectsViewModel {
    var projects: [PhotoProject] = []
    var isLoading = false
    var errorMessage: String?

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
        let imagePath: String
        do {
            imagePath = try ProjectStorageService.shared.saveOriginalImage(image, projectId: projectId)
        } catch {
            errorMessage = error.localizedDescription
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
        do {
            try ProjectStorageService.shared.deleteImage(fileName: project.originalImagePath)
        } catch {
            // Log but don't block project deletion — the DB record matters more
            print("[ProjectStorageService] Failed to delete image: \(error.localizedDescription)")
        }
        context.delete(project)
        do {
            try context.save()
        } catch {
            errorMessage = "No se pudo eliminar el proyecto"
        }
        fetchProjects()
    }

    func loadProjectImage(_ project: PhotoProject) -> UIImage? {
        do {
            return try ProjectStorageService.shared.loadOriginalImage(fileName: project.originalImagePath)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
