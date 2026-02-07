//
//  SkillCategory.swift
//  Llinks
//

import Foundation

enum SkillCategory: String, CaseIterable, Codable {
    case programming = "Программирование"
    case design = "Дизайн"
    case music = "Музыка"
    case language = "Языки"
    case sport = "Спорт"
    case cooking = "Кулинария"
    case other = "Другое"
}
