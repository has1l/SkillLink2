//
//  SearchViewModel.swift
//  Llinks
//

import Foundation
import Combine

class SearchViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var allUsers: [UserSummary] = []
    @Published var query: String = ""
    @Published var filteredUsers: [UserSummary] = []

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        // Настройка автоматической фильтрации при изменении query
        $query
            .removeDuplicates()
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.filterUsers()
            }
            .store(in: &cancellables)

        // Загружаем пользователей из Firestore
        Task {
            await loadUsersFromFirestore()
        }
    }

    func loadUsersFromFirestore() async {
        do {
            let users = try await FirestoreService.shared.getAllUsers()
            await MainActor.run {
                self.allUsers = users
                self.filteredUsers = users
            }
        } catch {
            AppLog.e("Search", "load users error: \(error.localizedDescription)")
        }
    }

    // MARK: - Public Methods

    /// Фильтрация пользователей по запросу
    /// В будущем будет заменено на AI-поиск
    func filterUsers() {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Если запрос пустой — показываем всех
        if trimmedQuery.isEmpty {
            filteredUsers = allUsers
            return
        }

        // Фильтруем по совпадениям в teachSkills
        filteredUsers = allUsers.filter { user in
            user.teachSkills.contains { skill in
                skill.localizedCaseInsensitiveContains(trimmedQuery)
            }
        }
    }

}
