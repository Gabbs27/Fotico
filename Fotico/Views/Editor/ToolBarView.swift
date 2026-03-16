import SwiftUI

struct ToolBarView: View {
    @Binding var selectedTool: EditorTool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(EditorTool.allCases, id: \.rawValue) { tool in
                let isSelected = selectedTool == tool
                Button {
                    HapticManager.selection()
                    selectedTool = tool
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tool.icon)
                            .font(.title3)
                        Text(tool.displayName)
                            .font(.caption2)
                    }
                    .foregroundColor(isSelected ? Color.lumePrimary : .lumeTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .overlay(alignment: .bottom) {
                        if isSelected {
                            Capsule()
                                .fill(Color.lumePrimary)
                                .frame(width: 24, height: 3)
                                .offset(y: 2)
                        }
                    }
                }
            }
        }
        .background(Color.lumeCardBg)
    }
}
