//
//  OnboardingView.swift
//  Llinks
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Добро пожаловать в Llinks")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Платформа для обмена навыками")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 16) {
                OnboardingStepView(
                    icon: "magnifyingglass",
                    title: "Находите людей",
                    description: "С нужными навыками"
                )

                OnboardingStepView(
                    icon: "arrow.left.arrow.right",
                    title: "Обменивайтесь",
                    description: "Учите других и учитесь сами"
                )

                OnboardingStepView(
                    icon: "message",
                    title: "Общайтесь",
                    description: "Договаривайтесь об обмене"
                )
            }
            .padding(.horizontal)

            Spacer()

            Button(action: {
                withAnimation {
                    appState.completeOnboarding()
                }
            }) {
                Text("Начать")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

struct OnboardingStepView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 50, height: 50)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
