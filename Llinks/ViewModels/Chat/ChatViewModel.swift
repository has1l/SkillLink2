//
//  ChatViewModel.swift
//  Llinks
//

import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []

    let chatId: String
    let otherUser: UserSummary
    let currentUserId: String = UUID().uuidString // ID текущего пользователя (мок)

    init(chatId: String, otherUser: UserSummary) {
        self.chatId = chatId
        self.otherUser = otherUser
        loadTestMessages()
    }

    // MARK: - Public Methods

    func sendMessage(text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let newMessage = Message(
            chatId: chatId,
            senderId: currentUserId,
            text: text,
            timestamp: Date()
        )

        messages.append(newMessage)
    }

    // MARK: - Private Methods

    private func loadTestMessages() {
        let otherUserId = otherUser.id

        // Создаем тестовую историю переписки
        messages = [
            Message(
                chatId: chatId,
                senderId: otherUserId,
                text: "Привет! Я видел твой профиль, тебе интересен обмен навыками?",
                timestamp: Date().addingTimeInterval(-86400 * 2) // 2 дня назад
            ),
            Message(
                chatId: chatId,
                senderId: currentUserId,
                text: "Привет! Да, конечно! Я как раз хотел изучить \(otherUser.teachSkills.first ?? "новые навыки")",
                timestamp: Date().addingTimeInterval(-86400 * 2 + 600) // 2 дня назад + 10 минут
            ),
            Message(
                chatId: chatId,
                senderId: otherUserId,
                text: "Отлично! А ты можешь научить меня \(getRandomSkill())?",
                timestamp: Date().addingTimeInterval(-86400 * 2 + 1200) // 2 дня назад + 20 минут
            ),
            Message(
                chatId: chatId,
                senderId: currentUserId,
                text: "Конечно, это одна из моих основных специализаций 👍",
                timestamp: Date().addingTimeInterval(-86400 * 2 + 1800) // 2 дня назад + 30 минут
            ),
            Message(
                chatId: chatId,
                senderId: otherUserId,
                text: "Когда тебе будет удобно начать?",
                timestamp: Date().addingTimeInterval(-3600) // 1 час назад
            ),
            Message(
                chatId: chatId,
                senderId: currentUserId,
                text: "Завтра вечером подойдет?",
                timestamp: Date().addingTimeInterval(-1800) // 30 минут назад
            ),
            Message(
                chatId: chatId,
                senderId: otherUserId,
                text: "Да, отлично! Договорились 🙂",
                timestamp: Date().addingTimeInterval(-300) // 5 минут назад
            )
        ]
    }

    private func getRandomSkill() -> String {
        let skills = ["Swift", "SwiftUI", "iOS разработка", "Python", "JavaScript"]
        return skills.randomElement() ?? "программирование"
    }
}
