import SwiftUI
import StoreKit

struct PaywallView: View {
    @State private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.lumeDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Header
                        headerSection

                        // Features
                        featuresSection

                        // Price cards
                        priceCardsSection

                        // Purchase button
                        purchaseButton

                        // Restore + Terms
                        footerSection
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.lumeTextSecondary)
                            .font(.title2)
                    }
                }
            }
            .task {
                await subscriptionService.loadProducts()
                selectedProduct = subscriptionService.products.last // Default to annual
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundColor(Color.lumePrimary)

            Text("Lumé Pro")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("Unlock your full creative potential")
                .font(.subheadline)
                .foregroundColor(.lumeTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 16) {
            featureRow(icon: "camera.filters", title: "40+ Premium Presets", description: "Kodak, Fuji, Polaroid and more")
            featureRow(icon: "square.on.square", title: "Exclusive Overlays", description: "Dust, light, frames, textures")
            featureRow(icon: "doc.on.doc", title: "Batch Editing", description: "Copy and paste edits between photos")
            featureRow(icon: "wand.and.stars", title: "Professional LUT Filters", description: "Cinematic color grading")
        }
        .padding()
        .background(Color.lumeCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color.lumePrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.lumeTextSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Price Cards

    private var priceCardsSection: some View {
        HStack(spacing: 12) {
            ForEach(subscriptionService.products) { product in
                let isSelected = selectedProduct?.id == product.id
                let isAnnual = product.id.contains("annual")

                Button {
                    selectedProduct = product
                    HapticManager.selection()
                } label: {
                    VStack(spacing: 8) {
                        if isAnnual {
                            Text("POPULAR")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.lumePrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        Text(isAnnual ? "Annual" : "Monthly")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text(product.displayPrice)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text(isAnnual ? "per year" : "per month")
                            .font(.caption)
                            .foregroundColor(.lumeTextSecondary)

                        if isAnnual {
                            Text("Save ~50%")
                                .font(.caption2)
                                .foregroundColor(Color.lumeSuccess)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isSelected ? Color.lumeSurface : Color.lumeCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.lumePrimary : Color.lumeSurface, lineWidth: isSelected ? 2 : 1)
                    )
                }
            }
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            guard let product = selectedProduct else { return }
            isPurchasing = true
            Task {
                do {
                    let success = try await subscriptionService.purchase(product)
                    if success {
                        HapticManager.notification(.success)
                        dismiss()
                    }
                } catch {
                    errorMessage = "Error processing purchase: \(error.localizedDescription)"
                    HapticManager.notification(.error)
                }
                isPurchasing = false
            }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text("Subscribe")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.lumePrimary)
            .foregroundColor(.black)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isPurchasing || selectedProduct == nil)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    isPurchasing = true
                    await subscriptionService.restorePurchases()
                    isPurchasing = false
                    if subscriptionService.isPro {
                        HapticManager.notification(.success)
                        dismiss()
                    }
                }
            } label: {
                Text("Restore purchases")
                    .font(.subheadline)
                    .foregroundColor(.lumeTextSecondary)
            }

            Text("Subscription renews automatically. You can cancel anytime from Settings.")
                .font(.caption2)
                .foregroundColor(.lumeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}
