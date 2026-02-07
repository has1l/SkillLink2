//
//  Message.swift
//  Llinks
//

import Foundation

struct Message: Identifiable, Codable {
    let id: String
    let chatId: String
    let senderId: String
    var text: String
    var timestamp: Date

    init(
        id: String = UUID().uuidString,
        chatId: String,
        senderId: String,
        text: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.chatId = chatId
        self.senderId = senderId
        self.text = text
        self.timestamp = timestamp
    }
}
