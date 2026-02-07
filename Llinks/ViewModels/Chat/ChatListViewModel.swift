//
//  ChatListViewModel.swift
//  Llinks
//

import Foundation
import Combine

class ChatListViewModel: ObservableObject {
    @Published var chats: [ChatSummary] = []

    init() {
        loadTestChats()
    }

    // MARK: - Private Methods

    private func loadTestChats() {
        // Создаем тестовых пользователей для чатов
        let user1 = UserSummary(
            id: "test1",
            name: "Алексей Иванов",
            teachSkills: ["Swift", "iOS разработка"],
            learnSkills: ["SwiftUI"],
            rating: 4.8,
            points: 250
        )

        let user2 = UserSummary(
            id: "test2",
            name: "Мария Петрова",
            teachSkills: ["Python", "Machine Learning"],
            learnSkills: ["iOS разработка"],
            rating: 4.9,
            points: 320
        )

        let user3 = UserSummary(
            id: "test3",
            name: "Ольга Волкова",
            teachSkills: ["SwiftUI", "Combine"],
            learnSkills: ["Backend разработка"],
            rating: 4.9,
            points: 380
        )

        let user4 = UserSummary(
            id: "test4",
            name: "Дмитрий Сидоров",
            teachSkills: ["JavaScript", "React"],
            learnSkills: ["Swift"],
            rating: 4.6,
            points: 180
        )

        // Создаем тестовые чаты с разным временем последних сообщений
        chats = [
            ChatSummary(
                otherUser: user1,
                lastMessageText: "Отлично! Когда начнем первое занятие?",
                lastMessageTime: Date().addingTimeInterval(-300) // 5 минут назад
            ),
            ChatSummary(
                otherUser: user2,
                lastMessageText: "Спасибо за объяснение! Теперь все понятно",
                lastMessageTime: Date().addingTimeInterval(-3600) // 1 час назад
            ),
            ChatSummary(
                otherUser: user3,
                lastMessageText: "Да, давай обменяемся навыками",
                lastMessageTime: Date().addingTimeInterval(-7200) // 2 часа назад
            ),
            ChatSummary(
                otherUser: user4,
                lastMessageText: "Привет! Интересует обмен навыками?",
                lastMessageTime: Date().addingTimeInterval(-86400) // 1 день назад
            )
        ]

        // Сортируем по времени (новые сверху)
        chats.sort { $0.lastMessageTime > $1.lastMessageTime }
    }

    // MARK: - Public Methods

    func updateLastMessage(for chatId: String, text: String, time: Date) {
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].lastMessageText = text
            chats[index].lastMessageTime = time
            // Пересортируем чаты
            chats.sort { $0.lastMessageTime > $1.lastMessageTime }
        }
    }
}
