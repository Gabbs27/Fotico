import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.lumeDark.ignoresSafeArea()

            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                featuresPage.tag(1)
                getStartedPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Skip button (top-right, visible on pages 0-1)
            VStack {
                HStack {
                    Spacer()
                    if currentPage < 2 {
                        Button {
                            onComplete()
                        } label: {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundColor(.lumeTextSecondary)
                                .padding(.horizontal, 16)
                                .frame(minHeight: 44)
                        }
                        .accessibilityLabel("Skip introduction")
                    }
                }
                .padding(.top, 8)
                .padding(.trailing, 8)
                Spacer()
            }
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "camera.aperture")
                .font(.system(size: 80))
                .foregroundColor(Color.lumePrimary)

            Text("LUME")
                .font(.system(size: 48, weight: .bold))
                .tracking(8)
                .foregroundColor(.white)

            Text("Film & Effects")
                .font(.title3)
                .foregroundColor(.lumeTextSecondary)

            Text("Your photo editor with a film-style look")
                .font(.subheadline)
                .foregroundColor(.lumeTextSecondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            nextButton
        }
        .padding()
    }

    // MARK: - Page 2: Features

    private var featuresPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Everything you need")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            VStack(spacing: 20) {
                featureCard(icon: "camera.fill", title: "Camera with Filters", description: "Apply filters in real time while capturing")
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lumePrimary, lineWidth: 1))
                featureCard(icon: "camera.filters", title: "40+ Presets", description: "Professional presets inspired by Kodak, Fuji, Polaroid")
                featureCard(icon: "wand.and.stars", title: "Advanced Effects", description: "Grain, light leaks, bloom, vignette and more")
                featureCard(icon: "square.on.square", title: "Overlays", description: "Dust, light, frame and paper textures")
            }
            .padding(.horizontal)

            Spacer()

            nextButton
        }
        .padding()
    }

    // MARK: - Page 3: Get Started

    private var getStartedPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(Color.lumePrimary)

            Text("Ready to create!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Start editing your photos with a professional style")
                .font(.subheadline)
                .foregroundColor(.lumeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                onComplete()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.lumePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .padding()
    }

    // MARK: - Components

    /// "Next" button for pages 0-1 with swipe hint
    private var nextButton: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation {
                    currentPage += 1
                }
            } label: {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.lumePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)

            Text("or swipe to continue")
                .font(.caption2)
                .foregroundColor(Color.lumeSecondary.opacity(0.6))
        }
        .padding(.bottom, 40)
    }

    private func featureCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color.lumePrimary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
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
        .padding()
        .background(Color.lumeCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
