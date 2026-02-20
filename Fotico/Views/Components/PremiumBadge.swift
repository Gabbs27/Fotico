import SwiftUI

struct PremiumBadge: View {
    var body: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 12))
            .foregroundColor(.white)
            .padding(5)
            .background(Color.lumePrimary.opacity(0.9))
            .clipShape(Circle())
    }
}
