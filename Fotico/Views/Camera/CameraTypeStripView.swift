import SwiftUI

struct CameraTypeStripView: View {
    let cameraTypes: [CameraType]
    let selectedId: String
    let onSelect: (CameraType) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(cameraTypes) { cameraType in
                    Button {
                        HapticManager.selection()
                        onSelect(cameraType)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: cameraType.icon)
                                .font(.system(size: 22))
                                .frame(width: 44, height: 44)
                            Text(cameraType.name)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                        }
                        .foregroundColor(selectedId == cameraType.id ? Color.foticoPrimary : .white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
