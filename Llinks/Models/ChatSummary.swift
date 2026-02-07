//
//  ChatSummary.swift
//  Llinks
//

import Foundation

struct ChatSummary: Identifiable, Codable {
    let id: String
    var otherUser: UserSummary
    var lastMessageText: String
    var lastMessageTime: Date

    init(
        id: String = UUID().uuidString,
        otherUser: UserSummary,
        lastMessageText: String,
        lastMessageTime: Date = Date()
    ) {
        self.id = id
        self.otherUser = otherUser
        self.lastMessageText = lastMessageText
        self.lastMessageTime = lastMessageTime
    }
}
