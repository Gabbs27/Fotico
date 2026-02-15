import UIKit

@MainActor
class ProjectStorageService {
    private let fileManager = FileManager.default

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var projectsDirectory: URL {
        documentsDirectory.appendingPathComponent("projects", isDirectory: true)
    }

    init() {
        try? fileManager.createDirectory(at: projectsDirectory, withIntermediateDirectories: true)
    }

    func saveOriginalImage(_ image: UIImage, projectId: UUID) throws -> String {
        let fileName = "\(projectId.uuidString)_original.jpg"
        let filePath = projectsDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.95) else {
            throw StorageError.encodingFailed
        }
        try data.write(to: filePath)
        return fileName
    }

    func loadOriginalImage(fileName: String) -> UIImage? {
        let filePath = projectsDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: filePath) else { return nil }
        return UIImage(data: data)
    }

    func saveProject(_ project: PhotoProject) throws {
        let filePath = projectsDirectory.appendingPathComponent("\(project.id.uuidString).json")
        let data = try JSONEncoder().encode(project)
        try data.write(to: filePath)
    }

    func loadProject(id: UUID) throws -> PhotoProject {
        let filePath = projectsDirectory.appendingPathComponent("\(id.uuidString).json")
        let data = try Data(contentsOf: filePath)
        return try JSONDecoder().decode(PhotoProject.self, from: data)
    }

    func listProjects() -> [PhotoProject] {
        guard let files = try? fileManager.contentsOfDirectory(at: projectsDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
            return []
        }
        let jsonFiles = files.filter { $0.pathExtension == "json" }
        return jsonFiles.compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  let project = try? JSONDecoder().decode(PhotoProject.self, from: data) else {
                return nil
            }
            return project
        }.sorted { $0.modifiedAt > $1.modifiedAt }
    }

    func deleteProject(id: UUID) throws {
        let jsonPath = projectsDirectory.appendingPathComponent("\(id.uuidString).json")
        let imagePath = projectsDirectory.appendingPathComponent("\(id.uuidString)_original.jpg")
        try? fileManager.removeItem(at: jsonPath)
        try? fileManager.removeItem(at: imagePath)
    }
}

enum StorageError: LocalizedError {
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "Error al codificar la imagen"
        case .decodingFailed: return "Error al decodificar el proyecto"
        }
    }
}
