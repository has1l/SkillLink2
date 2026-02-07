//
//  ProfileViewModel.swift
//  Llinks
//

import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile
    private var currentUserUID: String?

    init() {
        // Инициализация с дефолтным профилем
        self.profile = UserProfile(
            name: "",
            teachSkills: [],
            learnSkills: [],
            rating: 0.0,
            points: 0
        )
    }

    func loadProfile(uid: String) async {
        self.currentUserUID = uid
        do {
            if let loadedProfile = try await FirestoreService.shared.getUser(uid: uid) {
                await MainActor.run {
                    self.profile = loadedProfile
                }
            }
        } catch {
            AppLog.e("Profile", "load error: \(error.localizedDescription)")
        }
    }

    // MARK: - Public Methods

    func updateName(_ name: String) {
        profile.name = name
    }

    func addTeachSkill(_ skill: String) {
        guard !skill.isEmpty, !profile.teachSkills.contains(skill) else { return }
        profile.teachSkills.append(skill)
    }

    func removeTeachSkill(at index: Int) {
        guard index < profile.teachSkills.count else { return }
        profile.teachSkills.remove(at: index)
    }

    func addLearnSkill(_ skill: String) {
        guard !skill.isEmpty, !profile.learnSkills.contains(skill) else { return }
        profile.learnSkills.append(skill)
    }

    func removeLearnSkill(at index: Int) {
        guard index < profile.learnSkills.count else { return }
        profile.learnSkills.remove(at: index)
    }

    func saveProfile() async {
        guard let uid = currentUserUID else { return }
        do {
            try await FirestoreService.shared.updateProfileInfo(
                uid: uid,
                location: profile.location,
                bio: profile.bio
            )
        } catch {
            AppLog.e("Profile", "save error: \(error.localizedDescription)")
        }
    }

    func updateLocation(_ location: String) {
        profile.location = location
    }

    func updateBio(_ bio: String) {
        profile.bio = bio
    }
}
