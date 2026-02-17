import SwiftData
import Foundation

@Model
class SavedEdit {
    var name: String
    var editStateJSON: Data
    var thumbnailData: Data?
    var createdAt: Date

    init(name: String, editStateData: Data) {
        self.name = name
        self.editStateJSON = editStateData
        self.createdAt = Date()
    }
}
