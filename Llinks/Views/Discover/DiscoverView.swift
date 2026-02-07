//
//  DiscoverView.swift
//  Llinks
//

import SwiftUI

struct DiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    TextField("Поиск по навыку", text: $viewModel.searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    Toggle("Только подходящие", isOn: $viewModel.showOnlyMatching)
                        .padding(.horizontal)
                }
                .padding(.vertical, 8)

                if viewModel.isLoading {
                    ProgressView("Загрузка...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 80)
                } else if viewModel.filteredUsers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Пока никого нет")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Button {
                            Task { await viewModel.refresh() }
                        } label: {
                            Label("Обновить", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    List(viewModel.filteredUsers) { user in
                        NavigationLink(destination: ProfileDetailView(userUid: user.id)) {
                            UserCardView(
                                user: user,
                                matchScore: viewModel.matchScore(for: user),
                                reasons: viewModel.reasons(for: user)
                            )
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .trailing) {
                            Button {
                                viewModel.likeUser(user)
                            } label: {
                                Label("Нравится", systemImage: "heart.fill")
                            }
                            .tint(.green)
                        }
                        .onAppear {
                            viewModel.loadMoreIfNeeded(currentItem: user)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Поиск")
            .onAppear {
                if let uid = authService.user?.id {
                    Task {
                        await viewModel.loadUsers(currentUid: uid)
                    }
                }
            }
            .alert("Совпадение!", isPresented: $viewModel.showMatchAlert) {
                Button("OK") {}
            } message: {
                Text("Вы понравились друг другу с \(viewModel.matchedUserName)!")
            }
        }
    }
}

// MARK: - User Card

struct UserCardView: View {
    let user: UserSummary
    let matchScore: Int
    let reasons: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 10) {
                Text(user.name.isEmpty ? "Без имени" : user.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer()

                ScoreBadge(score: matchScore)
            }

            // Skills
            if !user.teachSkills.isEmpty {
                SkillRow(title: "Может обучить", skills: user.teachSkills, isTeach: true)
            }
            if !user.learnSkills.isEmpty {
                SkillRow(title: "Хочет изучить", skills: user.learnSkills, isTeach: false)
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

// MARK: - Card Components

struct ScoreBadge: View {
    let score: Int

    var body: some View {
        Text(score > 0 ? "\(score)%" : "Новый")
            .font(.system(size: 12, weight: .semibold))
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(score > 0 ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            )
            .foregroundColor(score > 0 ? .blue : .secondary)
    }
}

struct SkillRow: View {
    let title: String
    let skills: [String]
    let isTeach: Bool

    private var displaySkills: [String] { Array(skills.prefix(2)) }
    private var extraCount: Int { max(0, skills.count - 2) }

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .fixedSize()

            ForEach(displaySkills, id: \.self) { skill in
                SkillCapsule(text: skill, isTeach: isTeach)
            }
            if extraCount > 0 {
                Text("+\(extraCount)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SkillCapsule: View {
    let text: String
    let isTeach: Bool

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isTeach ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
            )
            .foregroundColor(isTeach ? Color(red: 0.2, green: 0.55, blue: 0.2) : Color(red: 0.2, green: 0.35, blue: 0.7))
    }
}

struct AvatarView: View {
    let url: String?
    var size: CGFloat = 50

    var body: some View {
        if let photoURL = url, let imageUrl = URL(string: photoURL) {
            AsyncImage(url: imageUrl) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color(UIColor.systemGray5))
                    .overlay(ProgressView().scaleEffect(0.7))
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
                        .font(.system(size: size * 0.5))
                )
        }
    }
}

#Preview {
    DiscoverView()
        .environmentObject(AuthService())
}
