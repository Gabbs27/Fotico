import SwiftData
import Foundation

@Model
class PhotoProject {
    var name: String
    var originalImagePath: String
    var editStateJSON: Data
    var thumbnailData: Data?
    var createdAt: Date
    var modifiedAt: Date

    init(name: String, originalImagePath: String, editStateData: Data) {
        self.name = name
        self.originalImagePath = originalImagePath
        self.editStateJSON = editStateData
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}
