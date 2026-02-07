//
//  ProfileDetailView.swift
//  Llinks
//

import SwiftUI

struct ProfileDetailView: View {
    let userUid: String
    @State private var user: UserSummary?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Загрузка...")
            } else if let user = user {
                ScrollView {
                    VStack(spacing: 16) {
                        // Hero Header Card
                        HStack(spacing: 14) {
                            ProfileAvatarView(url: user.avatarURL, size: 78)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(user.name.isEmpty ? "Без имени" : user.name)
                                    .font(.title2)
                                    .fontWeight(.bold)

                                if !user.location.isEmpty {
                                    Label(user.location, systemImage: "mappin")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(18)

                        // Bio Card
                        ProfileCard(title: "О себе") {
                            Text(user.bio.isEmpty ? "Пока ничего не указано" : user.bio)
                                .font(.body)
                                .foregroundColor(user.bio.isEmpty ? .secondary : .primary)
                        }

                        // Teach Skills Card
                        ProfileCard(title: "Может обучать", icon: "lightbulb.fill", iconColor: .green) {
                            if user.teachSkills.isEmpty {
                                Text("Не указано")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                FlowLayout(items: user.teachSkills) { skill in
                                    ProfileSkillTag(text: skill, isTeach: true)
                                }
                            }
                        }

                        // Learn Skills Card
                        ProfileCard(title: "Хочет изучить", icon: "book.fill", iconColor: .blue) {
                            if user.learnSkills.isEmpty {
                                Text("Не указано")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                FlowLayout(items: user.learnSkills) { skill in
                                    ProfileSkillTag(text: skill, isTeach: false)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            } else {
                ContentUnavailableView(
                    "Пользователь не найден",
                    systemImage: "person.slash"
                )
            }
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUser()
        }
    }

    private func loadUser() {
        Task {
            do {
                let users = try await FirestoreService.shared.getAllUsers()
                if let found = users.first(where: { $0.id == userUid }) {
                    await MainActor.run {
                        self.user = found
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            } catch {
                AppLog.e("ProfileDetail", "load user error: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Profile Components

struct ProfileCard<Content: View>: View {
    let title: String
    var icon: String? = nil
    var iconColor: Color = .primary
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.subheadline)
                }
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(18)
    }
}

struct ProfileAvatarView: View {
    let url: String?
    var size: CGFloat = 78

    var body: some View {
        if let photoURL = url, let imageUrl = URL(string: photoURL) {
            AsyncImage(url: imageUrl) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color(UIColor.systemGray5))
                    .overlay(ProgressView().scaleEffect(0.8))
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(UIColor.systemGray5))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(Color(UIColor.systemGray3))
                        .font(.system(size: size * 0.45))
                )
        }
    }
}

struct ProfileSkillTag: View {
    let text: String
    let isTeach: Bool

    var body: some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isTeach ? Color.green.opacity(0.12) : Color.blue.opacity(0.12))
            )
            .foregroundColor(isTeach ? .green : .blue)
    }
}

// MARK: - Flow Layout

struct FlowLayout<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(items, id: \.self) { item in
                    content(item)
                        .padding(3)
                        .alignmentGuide(.leading) { d in
                            if abs(width - d.width) > geometry.size.width {
                                width = 0
                                height -= d.height
                            }
                            let result = width
                            if item == items.last {
                                width = 0
                            } else {
                                width -= d.width
                            }
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = height
                            if item == items.last {
                                height = 0
                            }
                            return result
                        }
                }
            }
        }
        .frame(height: CGFloat(items.count / 3 + 1) * 40)
    }
}

#Preview {
    NavigationStack {
        ProfileDetailView(userUid: "test")
    }
}
