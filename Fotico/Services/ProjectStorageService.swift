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

    enum StorageError: LocalizedError {
        case jpegConversionFailed
        case writeFailed(URL, Error)
        case fileNotFound(String)
        case dataCorrupted(String)

        var errorDescription: String? {
            switch self {
            case .jpegConversionFailed:
                return "Failed to convert image to JPEG data"
            case .writeFailed(let url, let underlying):
                return "Failed to write image to \(url.lastPathComponent): \(underlying.localizedDescription)"
            case .fileNotFound(let name):
                return "Image file not found: \(name)"
            case .dataCorrupted(let name):
                return "Image data corrupted or unreadable: \(name)"
            }
        }
    }

    func saveOriginalImage(_ image: UIImage, projectId: String) throws -> String {
        let fileName = "\(projectId).jpg"
        let path = projectsDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw StorageError.jpegConversionFailed
        }
        do {
            try data.write(to: path)
            return fileName
        } catch {
            throw StorageError.writeFailed(path, error)
        }
    }

    func loadOriginalImage(fileName: String) throws -> UIImage {
        let path = projectsDirectory.appendingPathComponent(fileName)
        let data: Data
        do {
            data = try Data(contentsOf: path)
        } catch {
            throw StorageError.fileNotFound(fileName)
        }
        guard let image = UIImage(data: data) else {
            throw StorageError.dataCorrupted(fileName)
        }
        return image
    }

    func deleteImage(fileName: String) throws {
        let path = projectsDirectory.appendingPathComponent(fileName)
        try fileManager.removeItem(at: path)
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
