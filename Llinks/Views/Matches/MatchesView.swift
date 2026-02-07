//
//  MatchesView.swift
//  Llinks
//

import SwiftUI

struct MatchesView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Загрузка...")
                } else if viewModel.matches.isEmpty {
                    ContentUnavailableView(
                        "Нет матчей",
                        systemImage: "heart.slash",
                        description: Text("Лайкайте пользователей в Swipe")
                    )
                } else {
                    List(viewModel.matches) { match in
                        NavigationLink(destination: MatchChatView(chatId: match.id, otherUser: match.otherUser)) {
                            MatchRowView(user: match.otherUser)
                        }
                    }
                }
            }
            .navigationTitle("Матчи")
            .onAppear {
                if let uid = authService.user?.id {
                    Task {
                        await viewModel.loadMatches(myUid: uid)
                    }
                }
            }
        }
    }
}

struct MatchRowView: View {
    let user: UserSummary

    var body: some View {
        HStack(spacing: 14) {
            if let photoURL = user.avatarURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(Color(UIColor.systemGray3))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(user.name.isEmpty ? "Без имени" : user.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                if !user.location.isEmpty {
                    Label(user.location, systemImage: "mappin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    MatchesView()
        .environmentObject(AuthService())
}
