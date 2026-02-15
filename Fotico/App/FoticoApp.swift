import SwiftUI

@main
struct FoticoApp: App {
    var body: some Scene {
        WindowGroup {
            MainEditorView()
                .preferredColorScheme(.dark)
        }
    }
}
