//
//  SkillLevel.swift
//  Llinks
//

import Foundation

enum SkillLevel: String, CaseIterable, Codable {
    case beginner = "Начинающий"
    case intermediate = "Средний"
    case advanced = "Продвинутый"
    case expert = "Эксперт"
}
