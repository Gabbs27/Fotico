import SwiftUI

@main
struct EastApp: App {
    var body: some Scene {
        WindowGroup {
            MainEditorView()
                .preferredColorScheme(.dark)
        }
    }
}
