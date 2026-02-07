//
//  User.swift
//  Llinks
//

import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var bio: String
    var photoURL: String?
    var skillsToLearn: [Skill]
    var skillsToTeach: [Skill]
    var location: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        bio: String,
        photoURL: String? = nil,
        skillsToLearn: [Skill] = [],
        skillsToTeach: [Skill] = [],
        location: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.bio = bio
        self.photoURL = photoURL
        self.skillsToLearn = skillsToLearn
        self.skillsToTeach = skillsToTeach
        self.location = location
        self.createdAt = createdAt
    }
}
