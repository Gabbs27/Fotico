import SwiftUI
import SwiftData

struct ProjectsGridView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ProjectsViewModel()
    @State private var showDeleteAlert = false
    @State private var projectToDelete: PhotoProject?
    @State private var showOpenError = false

    var onOpenProject: ((UIImage) -> Void)?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.lumeDark.ignoresSafeArea()

                if viewModel.projects.isEmpty {
                    ContentUnavailableView("No Projects", systemImage: "photo.stack", description: Text("Your saved projects will appear here"))
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.projects) { project in
                                projectCard(project)
                                    .onTapGesture {
                                        openProject(project)
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .alert("Delete project?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let project = projectToDelete {
                        viewModel.deleteProject(project)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone")
            }
        }
    }

    private func openProject(_ project: PhotoProject) {
        guard let image = try? ProjectStorageService.shared.loadOriginalImage(fileName: project.originalImagePath) else {
            showOpenError = true
            return
        }
        HapticManager.selection()
        onOpenProject?(image)
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
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.lumeSurface)
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.lumeTextSecondary)
                    )
            }

            Text(project.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)

            Text(project.modifiedAt.formatted(.dateTime.month().day()))
                .font(.caption2)
                .foregroundColor(.lumeTextSecondary)
        }
        .contextMenu {
            Button(role: .destructive) {
                projectToDelete = project
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Error", isPresented: $showOpenError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Could not open project. The original image may be missing.")
        }
    }
}
