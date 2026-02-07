//
//  AppState.swift
//  Llinks
//

import Foundation
import Combine
import SwiftUI

class AppState: ObservableObject {
    @Published var currentFlow: AppFlow = .launch
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // Ссылка на AuthService
    var authService: AuthService?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Инициализация состояния
    }

    func setAuthService(_ authService: AuthService) {
        self.authService = authService

        // Подписываемся на изменения состояния авторизации
        authService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                guard let self = self else { return }
                // Если пользователь разлогинился, показываем логин
                if !isAuthenticated && self.currentFlow == .main {
                    self.currentFlow = .launch
                }
            }
            .store(in: &cancellables)
    }

    func checkInitialFlow(isAuthenticated: Bool) {
        // Проверяем авторизацию
        if !isAuthenticated {
            currentFlow = .launch // будет показан LoginView через LlinksApp
            return
        }

        // Если авторизован, проверяем онбординг
        if hasCompletedOnboarding {
            currentFlow = .main
        } else {
            currentFlow = .onboarding
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        currentFlow = .main
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentFlow = .onboarding
    }
}

