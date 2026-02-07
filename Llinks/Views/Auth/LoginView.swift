//
//  LoginView.swift
//  Llinks
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showError = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)

                    Text("Llinks")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)

                    Text("Обменивайтесь навыками")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Sign In Section
                VStack(spacing: 20) {
                    // Google Sign In Button
                    Button(action: {
                        Task {
                            await authService.signInWithGoogle()
                        }
                    }) {
                        HStack(spacing: 12) {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Image(systemName: "g.circle.fill")
                                    .font(.title2)
                                Text("Войти через Google")
                                    .font(.headline)
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .disabled(authService.isLoading)

                    // Privacy note
                    Text("Нажимая \"Войти\", вы соглашаетесь\nс условиями использования")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .alert("Ошибка авторизации", isPresented: $showError) {
            Button("OK", role: .cancel) {
                authService.errorMessage = nil
            }
        } message: {
            Text(authService.errorMessage ?? "Неизвестная ошибка")
        }
        .onChange(of: authService.errorMessage) { oldValue, newValue in
            showError = newValue != nil
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService())
}
