import SwiftUI

struct OnboardingScreen: View {
    @AppStorage("onboarding_complete") private var onboardingComplete: Bool = false
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "app.fill",
            title: "Welcome to countr",
            description: "Track anything you want to build habits, hit goals, and see your progress over time.",
            accentColor: .blue
        ),
        OnboardingPage(
            icon: "hand.tap.fill",
            title: "Tap to count",
            description: "Tap any counter to increment it by your chosen step value. Long-press for quick multiples.",
            accentColor: .teal
        ),
        OnboardingPage(
            icon: "target",
            title: "Set goals",
            description: "Add a daily goal to see your progress bar fill up and celebrate when you hit it.",
            accentColor: .green
        ),
        OnboardingPage(
            icon: "flame.fill",
            title: "Stay on track",
            description: "Build streaks, get reminded with notifications, and review your history in Stats.",
            accentColor: .orange
        ),
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            finishOnboarding()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    } else {
                        // Invisible placeholder to keep layout stable
                        Text("Skip")
                            .font(.subheadline)
                            .hidden()
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                    }
                }

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.accentColor : Color(.tertiaryLabel))
                            .frame(width: currentPage == index ? 10 : 7, height: currentPage == index ? 10 : 7)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // Navigation button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.easeInOut) {
                            currentPage += 1
                        }
                    } else {
                        finishOnboarding()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }

    private func finishOnboarding() {
        withAnimation(.easeInOut) {
            onboardingComplete = true
        }
    }
}

// MARK: - Page data

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
}

// MARK: - Page view

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.accentColor.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: page.icon)
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(page.accentColor)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}
