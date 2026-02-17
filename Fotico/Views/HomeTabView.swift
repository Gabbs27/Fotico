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
                    Text("Cámara")
                }
                .tag(1)

                ProjectsGridView { image in
                    capturedImage = image
                    selectedTab = 0
                }
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Proyectos")
                }
                .tag(2)

                ProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Perfil")
                    }
                    .tag(3)
            }
            .tint(Color.foticoPrimary)

            if !hasSeenOnboarding {
                OnboardingView {
                    withAnimation {
                        hasSeenOnboarding = true
                    }
                }
                .transition(.opacity)
            }
        }
    }
}
