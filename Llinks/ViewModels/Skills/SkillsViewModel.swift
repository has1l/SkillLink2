//
//  SkillsViewModel.swift
//  Llinks
//

import Foundation
import Combine
import SwiftUI

class SkillsViewModel: ObservableObject {
    @Published var learnSkills: [String] = []
    @Published var teachSkills: [String] = []

    private var uid: String?

    func loadSkills(uid: String) async {
        self.uid = uid
        do {
            if let profile = try await FirestoreService.shared.getUser(uid: uid) {
                await MainActor.run {
                    self.learnSkills = profile.learnSkills
                    self.teachSkills = profile.teachSkills
                }
            }
        } catch {
            AppLog.e("Skills", "load error: \(error.localizedDescription)")
        }
    }

    func addLearnSkill(_ skill: String) {
        let trimmed = skill.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !learnSkills.contains(where: { $0.lowercased() == trimmed.lowercased() }) else { return }
        learnSkills.append(trimmed)
        syncSkills()
    }

    func removeLearnSkill(at offsets: IndexSet) {
        learnSkills.remove(atOffsets: offsets)
        syncSkills()
    }

    func addTeachSkill(_ skill: String) {
        let trimmed = skill.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !teachSkills.contains(where: { $0.lowercased() == trimmed.lowercased() }) else { return }
        teachSkills.append(trimmed)
        syncSkills()
    }

    func removeTeachSkill(at offsets: IndexSet) {
        teachSkills.remove(atOffsets: offsets)
        syncSkills()
    }

    private func syncSkills() {
        guard let uid = uid else { return }
        Task {
            do {
                try await FirestoreService.shared.updateSkills(
                    uid: uid,
                    teachSkills: teachSkills,
                    learnSkills: learnSkills
                )
            } catch {
                AppLog.e("Skills", "sync error: \(error.localizedDescription)")
            }
        }
    }
}
