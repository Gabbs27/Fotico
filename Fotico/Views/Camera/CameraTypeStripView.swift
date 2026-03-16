import SwiftUI

struct CameraTypeStripView: View {
    let cameraTypes: [CameraType]
    let selectedId: String
    let onSelect: (CameraType) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(cameraTypes) { cameraType in
                    let isSelected = selectedId == cameraType.id
                    Button {
                        HapticManager.selection()
                        onSelect(cameraType)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: cameraType.icon)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                            Text(cameraType.name)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .lineLimit(1)
                        }
                        .foregroundColor(isSelected ? Color.lumePrimary : .white.opacity(0.7))
                    }
                    .accessibilityLabel("\(cameraType.name)\(isSelected ? ", seleccionada" : "")")
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
