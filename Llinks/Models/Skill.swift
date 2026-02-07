//
//  Skill.swift
//  Llinks
//

import Foundation

struct Skill: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: SkillCategory
    var level: SkillLevel

    init(id: UUID = UUID(), name: String, category: SkillCategory, level: SkillLevel) {
        self.id = id
        self.name = name
        self.category = category
        self.level = level
    }
}
