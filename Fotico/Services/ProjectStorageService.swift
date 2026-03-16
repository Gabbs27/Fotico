import UIKit

/// File I/O service for project images. Not @MainActor — callers should dispatch
/// from main thread if needed, or use the async overloads.
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
        do {
            try data.write(to: path)
            return fileName
        } catch {
            return nil
        }
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
        // Preserve aspect ratio instead of stretching
        let aspectWidth = size.width / image.size.width
        let aspectHeight = size.height / image.size.height
        let scale = min(aspectWidth, aspectHeight)
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return thumbnail.jpegData(compressionQuality: 0.7)
    }
}
