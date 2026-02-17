import SwiftUI

struct PremiumBadge: View {
    var body: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 10))
            .foregroundColor(.white)
            .padding(4)
            .background(Color.black.opacity(0.7))
            .clipShape(Circle())
    }
}
