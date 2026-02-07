//
//  AuthService.swift
//  Llinks
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

class AuthService: ObservableObject {
    @Published var user: AuthUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var profileCompleted = false
    @Published var isCheckingProfile = false

    private var authStateListener: AuthStateDidChangeListenerHandle?

    init() {
        setupAuthStateListener()
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Auth State Listener

    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }

            if let firebaseUser = firebaseUser {
                // Пользователь авторизован
                self.user = AuthUser(
                    id: firebaseUser.uid,
                    displayName: firebaseUser.displayName,
                    email: firebaseUser.email,
                    photoURL: firebaseUser.photoURL?.absoluteString
                )
                self.isAuthenticated = true
                self.isCheckingProfile = true
                AppLog.i("Auth", "User authenticated: \(firebaseUser.email ?? "no email")")

                // Загружаем profileCompleted из Firestore
                Task {
                    await self.loadProfileCompleted(uid: firebaseUser.uid)
                }
            } else {
                // Пользователь не авторизован
                self.user = nil
                self.isAuthenticated = false
                self.profileCompleted = false
                self.isCheckingProfile = false
                AppLog.i("Auth", "User signed out")
            }
        }
    }

    @MainActor
    private func loadProfileCompleted(uid: String) async {
        do {
            let completed = try await FirestoreService.shared.checkProfileCompleted(uid: uid)
            self.profileCompleted = completed
            AppLog.d("Auth", "profileCompleted=\(completed)")
        } catch {
            AppLog.e("Auth", "profileCompleted load failed: \(error.localizedDescription)")
            self.profileCompleted = false
        }
        self.isCheckingProfile = false
    }

    // MARK: - Google Sign In

    @MainActor
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        do {
            // Получаем clientID из GoogleService-Info.plist
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw AuthError.missingClientID
            }

            // Настройка Google Sign In
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            // Получаем root view controller
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                throw AuthError.noRootViewController
            }

            // Запускаем Google Sign In
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = result.user

            guard let idToken = user.idToken?.tokenString else {
                throw AuthError.noIDToken
            }

            let accessToken = user.accessToken.tokenString

            // Создаём Firebase credential
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            // Авторизуемся в Firebase
            let authResult = try await Auth.auth().signIn(with: credential)

            // Создаём DRAFT или проверяем profileCompleted
            do {
                let completed = try await FirestoreService.shared.createDraftUserIfNeeded(
                    uid: authResult.user.uid,
                    email: authResult.user.email,
                    photoURL: authResult.user.photoURL?.absoluteString
                )
                self.profileCompleted = completed
                AppLog.d("Auth", "Firestore OK, profileCompleted=\(completed)")
            } catch {
                let nsError = error as NSError
                AppLog.e("Auth", "Firestore fail: \(nsError.domain) code=\(nsError.code) \(nsError.localizedDescription)")
            }

            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
        }
    }

    // MARK: - Profile

    @MainActor
    func setProfileCompleted() {
        self.profileCompleted = true
    }

    // MARK: - Sign Out

    @MainActor
    func signOut() {
        self.profileCompleted = false
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            errorMessage = nil
        } catch {
            handleError(error)
        }
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        AppLog.e("Auth", "error: \(error.localizedDescription)")

        if let authError = error as? AuthError {
            errorMessage = authError.localizedDescription
        } else if let nsError = error as NSError? {
            switch nsError.code {
            case AuthErrorCode.networkError.rawValue:
                errorMessage = "Ошибка сети. Проверьте подключение к интернету"
            case AuthErrorCode.userDisabled.rawValue:
                errorMessage = "Эта учетная запись отключена"
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "Неверный email"
            default:
                errorMessage = "Ошибка авторизации: \(error.localizedDescription)"
            }
        } else {
            errorMessage = "Ошибка авторизации: \(error.localizedDescription)"
        }
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case missingClientID
    case noRootViewController
    case noIDToken

    var errorDescription: String? {
        switch self {
        case .missingClientID:
            return "Client ID не найден в GoogleService-Info.plist"
        case .noRootViewController:
            return "Не удалось получить root view controller"
        case .noIDToken:
            return "Не удалось получить ID token от Google"
        }
    }
}
