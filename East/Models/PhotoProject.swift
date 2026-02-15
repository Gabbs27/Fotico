import Foundation

struct PhotoProject: Codable, Identifiable, Sendable {
    let id: UUID
    var originalImagePath: String
    var editedImagePath: String?
    var editStatePath: String?
    var createdAt: Date
    var modifiedAt: Date
    var presetName: String?

    init(originalImagePath: String) {
        self.id = UUID()
        self.originalImagePath = originalImagePath
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}
