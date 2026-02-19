import SwiftUI
import SwiftData

@main
struct LumeApp: App {
    var body: some Scene {
        WindowGroup {
            HomeTabView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [UserProfile.self, PhotoProject.self, SavedEdit.self])
    }
}
