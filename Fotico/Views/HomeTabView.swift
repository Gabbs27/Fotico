import SwiftUI

struct HomeTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MainEditorView()
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                    Text("Editor")
                }
                .tag(0)

            CameraLaunchView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Cámara")
                }
                .tag(1)

            ProjectsGridView()
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
    }
}
