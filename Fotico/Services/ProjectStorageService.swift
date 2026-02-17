import UIKit

@MainActor
class ProjectStorageService {
    static let shared = ProjectStorageService()

    private let fileManager = FileManager.default

    private var projectsDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("projects", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func saveOriginalImage(_ image: UIImage, projectId: String) -> String? {
        let fileName = "\(projectId).jpg"
        let path = projectsDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        try? data.write(to: path)
        return fileName
    }

    func loadOriginalImage(fileName: String) -> UIImage? {
        let path = projectsDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: path) else { return nil }
        return UIImage(data: data)
    }

    func deleteImage(fileName: String) {
        let path = projectsDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: path)
    }

    func generateThumbnail(_ image: UIImage, size: CGSize = CGSize(width: 200, height: 200)) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return thumbnail.jpegData(compressionQuality: 0.7)
    }
}
