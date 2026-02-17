import SwiftUI
import SwiftData

@main
struct FoticoApp: App {
    var body: some Scene {
        WindowGroup {
            HomeTabView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [UserProfile.self, PhotoProject.self, SavedEdit.self])
    }
}
