import SwiftUI

struct HomeTabView: View {
    @State private var selectedTab = 0
    @State private var capturedImage: UIImage?
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                MainEditorView(injectedImage: $capturedImage)
                    .tabItem {
                        Image(systemName: "photo.on.rectangle")
                        Text("Editor")
                    }
                    .tag(0)

                CameraLaunchView { image in
                    capturedImage = image
                    selectedTab = 0
                }
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                }
                .tag(1)

                ProjectsGridView { image in
                    capturedImage = image
                    selectedTab = 0
                }
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Projects")
                }
                .tag(2)

                ProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
                    .tag(3)
            }
            .tint(Color.lumePrimary)

            if !hasSeenOnboarding {
                OnboardingView {
                    withAnimation(.easeInOut) {
                        hasSeenOnboarding = true
                    }
                }
                .transition(.opacity)
            }
        }
    }
}
