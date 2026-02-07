//
//  DiscoverViewModel.swift
//  Llinks
//

import Foundation
import Combine
import FirebaseFirestore

class DiscoverViewModel: ObservableObject {
    @Published var allUsers: [UserSummary] = []
    @Published var searchQuery = ""
    @Published var showOnlyMatching = false
    @Published var showMatchAlert = false
    @Published var matchedUserName = ""
    @Published var isLoading = false
    @Published var isLoadingPage = false

    private var currentUserUid: String?
    private var myLearnSkills: [String] = []
    private var myTeachSkills: [String] = []
    private var myLocation: String = ""
    private var excludedIds: Set<String> = []
    private var lastDocument: DocumentSnapshot?
    private var hasMore = true

    // Cached scores
    private var scoreCache: [String: Int] = [:]
    private var reasonsCache: [String: [String]] = [:]

    var filteredUsers: [UserSummary] {
        var result = allUsers

        let query = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter { user in
                user.teachSkills.contains { $0.lowercased().contains(query) } ||
                user.learnSkills.contains { $0.lowercased().contains(query) } ||
                user.name.lowercased().contains(query)
            }
        }

        if showOnlyMatching {
            result = result.filter { matchScore(for: $0) > 0 }
        }

        result.sort { lhs, rhs in
            let scoreL = matchScore(for: lhs)
            let scoreR = matchScore(for: rhs)
            if scoreL != scoreR { return scoreL > scoreR }
            return lhs.name < rhs.name
        }

        return result
    }

    func loadUsers(currentUid: String) async {
        self.currentUserUid = currentUid
        await refresh()
    }

    func refresh() async {
        guard let uid = currentUserUid else { return }
        allUsers = []
        scoreCache = [:]
        reasonsCache = [:]
        lastDocument = nil
        hasMore = true
        isLoading = true

        // My profile
        if let p = try? await FirestoreService.shared.getUser(uid: uid) {
            myLearnSkills = p.learnSkills
            myTeachSkills = p.teachSkills
            myLocation = p.location
        }

        // Excluded set (once)
        let liked = (try? await FirestoreService.shared.getLikedUserIds(uid: uid)) ?? []
        let passed = (try? await FirestoreService.shared.getPassedUserIds(uid: uid)) ?? []
        let matches = (try? await FirestoreService.shared.getMatches(uid: uid)) ?? []
        let matchedIds = Set(matches.map { $0.otherUid })
        excludedIds = liked.union(passed).union(matchedIds)
        excludedIds.insert(uid)
        AppLog.d("Discover", "excludedSet size=\(excludedIds.count)")

        await loadNextPage()
        isLoading = false
    }

    func loadMoreIfNeeded(currentItem: UserSummary) {
        let visible = filteredUsers
        guard let idx = visible.firstIndex(where: { $0.id == currentItem.id }) else { return }
        if idx >= visible.count - 5 {
            Task { await loadNextPage() }
        }
    }

    private func loadNextPage() async {
        guard hasMore, !isLoadingPage else { return }
        isLoadingPage = true

        var totalNew: [UserSummary] = []
        var attempts = 0

        while attempts < 3 && hasMore {
            attempts += 1
            do {
                let result = try await FirestoreService.shared.getUsersPage(
                    afterDocument: lastDocument, limit: 20
                )
                let raw = result.users
                lastDocument = result.lastDocument
                if raw.count < 20 { hasMore = false }
                let filtered = raw.filter { !excludedIds.contains($0.id) }
                AppLog.d("Discover", "page raw=\(raw.count) filtered=\(filtered.count)")

                for user in filtered {
                    scoreCache[user.id] = RecommendationService.calculateMatchScore(
                        myLearn: myLearnSkills, myTeach: myTeachSkills, myLocation: myLocation,
                        other: user
                    )
                    reasonsCache[user.id] = RecommendationService.buildReasons(
                        myLearn: myLearnSkills, myTeach: myTeachSkills, myLocation: myLocation,
                        other: user
                    )
                }

                totalNew.append(contentsOf: filtered)
                if !filtered.isEmpty { break }
            } catch {
                AppLog.e("Discover", "page error: \(error.localizedDescription)")
                hasMore = false
            }
        }

        allUsers.append(contentsOf: totalNew)
        isLoadingPage = false
    }

    func matchScore(for user: UserSummary) -> Int {
        scoreCache[user.id] ?? 0
    }

    func reasons(for user: UserSummary) -> [String] {
        reasonsCache[user.id] ?? []
    }

    func likeUser(_ user: UserSummary) {
        guard let myUid = currentUserUid else { return }
        allUsers.removeAll { $0.id == user.id }
        excludedIds.insert(user.id)

        Task {
            do {
                let isMatch = try await FirestoreService.shared.likeUser(myUid: myUid, theirUid: user.id)
                if isMatch {
                    self.matchedUserName = user.name
                    self.showMatchAlert = true
                }
            } catch {
                AppLog.e("Discover", "like error: \(error.localizedDescription)")
            }
        }
    }
}
