import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
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
                            .foregroundColor(.gray)
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

            Text("Desbloquea todo el potencial creativo")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 16) {
            featureRow(icon: "camera.filters", title: "40+ Presets Premium", description: "Kodak, Fuji, Polaroid y más")
            featureRow(icon: "square.on.square", title: "Overlays Exclusivos", description: "Polvo, luz, marcos, texturas")
            featureRow(icon: "doc.on.doc", title: "Edición por Lotes", description: "Copia y pega ediciones entre fotos")
            featureRow(icon: "wand.and.stars", title: "Filtros LUT Profesionales", description: "Color grading cinematográfico")
        }
        .padding()
        .background(Color.lumeCardBg)
        .cornerRadius(16)
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
                    .foregroundColor(.gray)
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
                                .cornerRadius(4)
                        }

                        Text(isAnnual ? "Anual" : "Mensual")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text(product.displayPrice)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text(isAnnual ? "por año" : "por mes")
                            .font(.caption)
                            .foregroundColor(.gray)

                        if isAnnual {
                            Text("Ahorra ~50%")
                                .font(.caption2)
                                .foregroundColor(Color.lumeSuccess)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isSelected ? Color.lumeSurface : Color.lumeCardBg)
                    .cornerRadius(12)
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
                    errorMessage = "Error al procesar la compra: \(error.localizedDescription)"
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
                    Text("Suscribirse")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.lumePrimary)
            .foregroundColor(.black)
            .cornerRadius(12)
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
                Text("Restaurar compras")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Text("La suscripción se renueva automáticamente. Puedes cancelar en cualquier momento desde Ajustes.")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}
