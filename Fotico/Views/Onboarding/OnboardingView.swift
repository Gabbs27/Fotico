import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.foticoDark.ignoresSafeArea()

            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                featuresPage.tag(1)
                getStartedPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "camera.aperture")
                .font(.system(size: 80))
                .foregroundColor(Color.foticoPrimary)

            Text("FOTICO")
                .font(.system(size: 48, weight: .bold))
                .tracking(8)
                .foregroundColor(.white)

            Text("Film & Effects")
                .font(.title3)
                .foregroundColor(.gray)

            Text("Tu editor de fotos con estilo de película")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            swipeHint
        }
        .padding()
    }

    // MARK: - Page 2: Features

    private var featuresPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Todo lo que necesitas")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            VStack(spacing: 20) {
                featureCard(icon: "camera.filters", title: "40+ Presets", description: "Presets profesionales inspirados en Kodak, Fuji, Polaroid")
                featureCard(icon: "camera.fill", title: "Cámara con Filtros", description: "Aplica filtros en tiempo real mientras capturas")
                featureCard(icon: "wand.and.stars", title: "Efectos Avanzados", description: "Grano, light leaks, bloom, viñeta y más")
                featureCard(icon: "square.on.square", title: "Overlays", description: "Texturas de polvo, luz, marcos y papel")
            }
            .padding(.horizontal)

            Spacer()

            swipeHint
        }
        .padding()
    }

    // MARK: - Page 3: Get Started

    private var getStartedPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(Color.foticoPrimary)

            Text("¡Listo para crear!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Empieza a editar tus fotos con estilo profesional")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                onComplete()
            } label: {
                Text("Comenzar")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.foticoPrimary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .padding()
    }

    // MARK: - Components

    private func featureCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color.foticoPrimary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
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
        .padding()
        .background(Color.foticoCardBg)
        .cornerRadius(12)
    }

    private var swipeHint: some View {
        HStack(spacing: 4) {
            Image(systemName: "chevron.left")
                .font(.caption2)
            Text("Desliza")
                .font(.caption)
            Image(systemName: "chevron.right")
                .font(.caption2)
        }
        .foregroundColor(.gray.opacity(0.5))
        .padding(.bottom, 40)
    }
}
