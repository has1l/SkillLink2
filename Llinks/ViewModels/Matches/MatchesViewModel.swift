//
//  MatchesViewModel.swift
//  Llinks
//

import Foundation
import Combine

struct MatchItem: Identifiable {
    let id: String // pairId
    let otherUser: UserSummary
}

class MatchesViewModel: ObservableObject {
    @Published var matches: [MatchItem] = []
    @Published var isLoading = true

    func loadMatches(myUid: String) async {
        do {
            let matchPairs = try await FirestoreService.shared.getMatches(uid: myUid)
            let allUsers = try await FirestoreService.shared.getAllUsers()

            let items: [MatchItem] = matchPairs.compactMap { pair in
                guard let otherUser = allUsers.first(where: { $0.id == pair.otherUid }) else { return nil }
                return MatchItem(id: pair.pairId, otherUser: otherUser)
            }

            await MainActor.run {
                self.matches = items
                self.isLoading = false
            }
        } catch {
            AppLog.e("Matches", "load error: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
