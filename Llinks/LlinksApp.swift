//
//  LlinksApp.swift
//  Llinks
//
//  Created by Родион Милосердов on 31.01.2026.
//

import SwiftUI
import SwiftData
import FirebaseCore
import GoogleSignIn

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Инициализация Firebase
        FirebaseApp.configure()
        AppLog.i("App", "Firebase configured")
        return true
    }

    // Обработка URL для Google Sign-In (опциональный fallback)
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - App

@main
struct LlinksApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthService()
    @StateObject private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Инициализация связи между AppState и AuthService
        // Выполняется после создания @StateObject
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !authService.isAuthenticated {
                    // Не авторизован
                    LoginView()
                        .environmentObject(authService)
                } else if authService.isCheckingProfile {
                    // Проверяем профиль
                    ProgressView("Загрузка...")
                } else if !authService.profileCompleted {
                    // Профиль не заполнен
                    ProfileSetupView()
                        .environmentObject(authService)
                } else {
                    // Авторизован и профиль заполнен
                    switch appState.currentFlow {
                    case .launch:
                        LaunchView()
                    case .onboarding:
                        OnboardingView()
                    case .profileSetup:
                        ProfileSetupView()
                    case .main:
                        MainTabView()
                    }
                }
            }
            .environmentObject(appState)
            .environmentObject(authService)
            .onAppear {
                // Связываем AppState с AuthService
                appState.setAuthService(authService)
            }
            .onOpenURL { url in
                // Обработка URL для Google Sign-In callback
                GIDSignIn.sharedInstance.handle(url)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
