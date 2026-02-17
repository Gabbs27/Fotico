import SwiftUI
import SwiftData

struct ProjectsGridView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ProjectsViewModel()
    @State private var showDeleteAlert = false
    @State private var projectToDelete: PhotoProject?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.foticoDark.ignoresSafeArea()

                if viewModel.projects.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("Sin proyectos")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Las fotos editadas aparecerán aquí")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.projects) { project in
                                projectCard(project)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Proyectos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .alert("Eliminar proyecto?", isPresented: $showDeleteAlert) {
                Button("Eliminar", role: .destructive) {
                    if let project = projectToDelete {
                        viewModel.deleteProject(project)
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acción no se puede deshacer")
            }
        }
    }

    private func projectCard(_ project: PhotoProject) -> some View {
        VStack(spacing: 4) {
            if let thumbData = project.thumbnailData,
               let thumb = UIImage(data: thumbData) {
                Image(uiImage: thumb)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.foticoSurface)
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }

            Text(project.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)

            Text(project.modifiedAt.formatted(.dateTime.month().day()))
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .contextMenu {
            Button(role: .destructive) {
                projectToDelete = project
                showDeleteAlert = true
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
}
