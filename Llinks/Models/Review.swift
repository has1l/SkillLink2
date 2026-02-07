//
//  Review.swift
//  Llinks
//

import Foundation

struct Review: Identifiable {
    let id: String // reviewerUid
    let toUid: String
    let stars: Int
    let text: String
    let createdAt: Date?
}
