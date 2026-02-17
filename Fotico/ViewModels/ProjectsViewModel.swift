import SwiftUI
import SwiftData

@MainActor
class ProjectsViewModel: ObservableObject {
    @Published var projects: [PhotoProject] = []
    @Published var isLoading = false

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchProjects()
    }

    func fetchProjects() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<PhotoProject>(sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)])
        projects = (try? context.fetch(descriptor)) ?? []
    }

    func saveProject(name: String, image: UIImage, editState: EditState) {
        guard let context = modelContext else { return }

        let projectId = UUID().uuidString
        guard let imagePath = ProjectStorageService.shared.saveOriginalImage(image, projectId: projectId) else { return }

        let editStateData = (try? JSONEncoder().encode(editState)) ?? Data()
        let project = PhotoProject(name: name, originalImagePath: imagePath, editStateData: editStateData)
        project.thumbnailData = ProjectStorageService.shared.generateThumbnail(image)

        context.insert(project)
        try? context.save()
        fetchProjects()
    }

    func deleteProject(_ project: PhotoProject) {
        guard let context = modelContext else { return }
        ProjectStorageService.shared.deleteImage(fileName: project.originalImagePath)
        context.delete(project)
        try? context.save()
        fetchProjects()
    }

    func loadProjectImage(_ project: PhotoProject) -> UIImage? {
        return ProjectStorageService.shared.loadOriginalImage(fileName: project.originalImagePath)
    }
}
