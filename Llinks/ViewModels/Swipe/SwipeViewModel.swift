//
//  SwipeViewModel.swift
//  Llinks
//

import Foundation
import Combine

class SwipeViewModel: ObservableObject {
    @Published var currentUser: UserSummary?
    @Published var isLoading = true
    @Published var showMatch = false
    @Published var matchedUser: UserSummary?

    private var candidates: [UserSummary] = []
    private var currentIndex = 0
    private var myUid: String?
    private var myLearnSkills: [String] = []
    private var myTeachSkills: [String] = []

    func loadCandidates(myUid: String) async {
        self.myUid = myUid

        do {
            // Загружаем мой профиль
            if let myProfile = try await FirestoreService.shared.getUser(uid: myUid) {
                myLearnSkills = myProfile.learnSkills
                myTeachSkills = myProfile.teachSkills
            }

            // Загружаем всех
            let allUsers = try await FirestoreService.shared.getAllUsers()

            // Исключаем себя
            var filtered = allUsers.filter { $0.id != myUid }

            // Исключаем уже лайкнутых/пропущенных
            let liked = try await FirestoreService.shared.getLikedUserIds(uid: myUid)
            let passed = try await FirestoreService.shared.getPassedUserIds(uid: myUid)
            let excluded = liked.union(passed)
            filtered = filtered.filter { !excluded.contains($0.id) }

            // Сортируем по score
            filtered.sort { lhs, rhs in
                matchScore(for: lhs) > matchScore(for: rhs)
            }

            await MainActor.run {
                self.candidates = filtered
                self.currentIndex = 0
                self.currentUser = filtered.first
                self.isLoading = false
            }
        } catch {
            AppLog.e("Swipe", "load candidates error: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    func like() {
        guard let myUid = myUid, let user = currentUser else { return }

        Task {
            do {
                let isMatch = try await FirestoreService.shared.likeUser(myUid: myUid, theirUid: user.id)
                if isMatch {
                    await MainActor.run {
                        self.matchedUser = user
                        self.showMatch = true
                    }
                }
                await MainActor.run {
                    self.showNext()
                }
            } catch {
                AppLog.e("Swipe", "like error: \(error.localizedDescription)")
            }
        }
    }

    func pass() {
        guard let myUid = myUid, let user = currentUser else { return }

        Task {
            do {
                try await FirestoreService.shared.passUser(myUid: myUid, theirUid: user.id)
                await MainActor.run {
                    self.showNext()
                }
            } catch {
                AppLog.e("Swipe", "pass error: \(error.localizedDescription)")
            }
        }
    }

    func dismissMatch() {
        showMatch = false
        matchedUser = nil
    }

    private func showNext() {
        currentIndex += 1
        if currentIndex < candidates.count {
            currentUser = candidates[currentIndex]
        } else {
            currentUser = nil
        }
    }

    private func matchScore(for user: UserSummary) -> Int {
        let theirTeach = Set(user.teachSkills.map { $0.lowercased() })
        let myLearn = Set(myLearnSkills.map { $0.lowercased() })
        let teachMatch = theirTeach.intersection(myLearn).count

        let theirLearn = Set(user.learnSkills.map { $0.lowercased() })
        let myTeach = Set(myTeachSkills.map { $0.lowercased() })
        let learnMatch = theirLearn.intersection(myTeach).count

        return 3 * teachMatch + 3 * learnMatch
    }
}
