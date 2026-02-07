//
//  ChatsWithMatchesView.swift
//  Llinks
//

import SwiftUI

struct ChatListItem: Identifiable {
    let id: String // chatId = pairId
    let otherUser: UserSummary
    let lastMessage: String
}

struct ChatsWithMatchesView: View {
    @StateObject private var matchesVM = MatchesViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var chatItems: [ChatListItem] = []
    @State private var isLoadingChats = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Matches horizontal section
                    if !matchesVM.matches.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Новые матчи")
                                .font(.headline)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(matchesVM.matches) { match in
                                        NavigationLink(destination: MatchChatView(chatId: match.id, otherUser: match.otherUser)) {
                                            VStack(spacing: 6) {
                                                AvatarView(url: match.otherUser.avatarURL, size: 60)
                                                Text(match.otherUser.name.components(separatedBy: " ").first ?? "")
                                                    .font(.caption)
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                            }
                                            .frame(width: 72)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 8)

                        Divider()
                            .padding(.horizontal)
                    }

                    // Chat list
                    if !chatItems.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(chatItems) { item in
                                NavigationLink(destination: MatchChatView(chatId: item.id, otherUser: item.otherUser)) {
                                    ChatRowItem(item: item)
                                }
                                Divider().padding(.leading, 72)
                            }
                        }
                    } else if !isLoadingChats && matchesVM.matches.isEmpty {
                        ContentUnavailableView(
                            "Нет чатов",
                            systemImage: "message",
                            description: Text("Лайкайте пользователей, чтобы начать общение")
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else if isLoadingChats {
                        ProgressView("Загрузка...")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                    }
                }
            }
            .navigationTitle("Чаты")
            .onAppear {
                if let uid = authService.user?.id {
                    Task {
                        await matchesVM.loadMatches(myUid: uid)
                        await loadChats(uid: uid)
                    }
                }
            }
        }
    }

    private func loadChats(uid: String) async {
        do {
            let chats = try await FirestoreService.shared.getChats(uid: uid)
            let allUsers = try await FirestoreService.shared.getAllUsers()

            let items: [ChatListItem] = chats.compactMap { chat in
                guard let user = allUsers.first(where: { $0.id == chat.otherUid }) else { return nil }
                return ChatListItem(id: chat.chatId, otherUser: user, lastMessage: chat.lastMessage)
            }

            await MainActor.run {
                self.chatItems = items
                self.isLoadingChats = false
            }
        } catch {
            AppLog.e("Chats", "load error: \(error.localizedDescription)")
            await MainActor.run { self.isLoadingChats = false }
        }
    }
}

struct ChatRowItem: View {
    let item: ChatListItem

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(url: item.otherUser.avatarURL, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.otherUser.name.isEmpty ? "Без имени" : item.otherUser.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(item.lastMessage.isEmpty ? "Начните общение" : item.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

#Preview {
    ChatsWithMatchesView()
        .environmentObject(AuthService())
}
