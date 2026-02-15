import SwiftUI

struct ToolBarView: View {
    @Binding var selectedTool: EditorTool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(EditorTool.allCases, id: \.rawValue) { tool in
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
                    .foregroundColor(selectedTool == tool ? Color.eastPrimary : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color.eastCardBg)
        .overlay(
            Rectangle()
                .fill(Color.eastSurface)
                .frame(height: 0.5),
            alignment: .top
        )
    }
}
