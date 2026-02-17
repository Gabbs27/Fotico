import SwiftUI

struct ProjectsGridView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.foticoDark.ignoresSafeArea()
                Text("Proyectos")
                    .foregroundColor(.gray)
            }
            .navigationTitle("Proyectos")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
