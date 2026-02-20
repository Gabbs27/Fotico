import SwiftUI

struct CategoryChipView: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.selection()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(name)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.lumePrimary : Color.lumeCardBg)
            .foregroundColor(isSelected ? .black : .lumeTextSecondary)
            .cornerRadius(12)
        }
    }
}
