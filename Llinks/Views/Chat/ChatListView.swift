//
//  ChatListView.swift
//  Llinks
//

import SwiftUI

struct ChatListView: View {
    @StateObject private var viewModel = ChatListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.chats.isEmpty {
                    EmptyChatListView()
                } else {
                    List(viewModel.chats) { chat in
                        NavigationLink(destination: ChatView(chat: chat)) {
                            ChatRowView(chat: chat)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Сообщения")
        }
    }
}

// MARK: - Chat Row View

struct ChatRowView: View {
    let chat: ChatSummary

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Image(systemName: "person.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            // Chat Info
            VStack(alignment: .leading, spacing: 4) {
                // Name and Time
                HStack {
                    Text(chat.otherUser.name)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    Text(formatTime(chat.lastMessageTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Last Message
                Text(chat.lastMessageText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Вчера"
        } else if calendar.dateComponents([.day], from: date, to: now).day! < 7 {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}

// MARK: - Empty State View

struct EmptyChatListView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "message")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Нет сообщений")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Найдите людей для обмена навыками\nи начните общение")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    ChatListView()
}
