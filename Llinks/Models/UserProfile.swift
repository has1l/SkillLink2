//
//  UserProfile.swift
//  Llinks
//

import Foundation

struct UserProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var avatarURL: String?
    var location: String
    var bio: String
    var teachSkills: [String]
    var learnSkills: [String]
    var rating: Double
    var points: Int

    init(
        id: UUID = UUID(),
        name: String = "",
        avatarURL: String? = nil,
        location: String = "",
        bio: String = "",
        teachSkills: [String] = [],
        learnSkills: [String] = [],
        rating: Double = 0.0,
        points: Int = 0
    ) {
        self.id = id
        self.name = name
        self.avatarURL = avatarURL
        self.location = location
        self.bio = bio
        self.teachSkills = teachSkills
        self.learnSkills = learnSkills
        self.rating = rating
        self.points = points
    }
}
