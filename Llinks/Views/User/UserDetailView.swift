//
//  UserDetailView.swift
//  Llinks
//

import SwiftUI

struct UserDetailView: View {
    let user: UserSummary

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Header (Avatar + Name + Stats)
                VStack(spacing: 16) {
                    // Avatar
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.gray)

                    // Name
                    Text(user.name)
                        .font(.title)
                        .fontWeight(.bold)

                    // Stats (Rating + Points)
                    HStack(spacing: 32) {
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", user.rating))
                                    .fontWeight(.semibold)
                            }
                            .font(.title2)

                            Text("Рейтинг")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.orange)
                                Text("\(user.points)")
                                    .fontWeight(.semibold)
                            }
                            .font(.title2)

                            Text("Баллы")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 20)

                // MARK: - Skills Sections
                VStack(spacing: 20) {
                    // Teach Skills
                    SkillsSectionView(
                        title: "Может преподавать",
                        skills: user.teachSkills,
                        icon: "checkmark.circle.fill",
                        iconColor: .green
                    )

                    // Learn Skills
                    SkillsSectionView(
                        title: "Хочет изучить",
                        skills: user.learnSkills,
                        icon: "book.circle.fill",
                        iconColor: .blue
                    )
                }
                .padding(.horizontal)

                // MARK: - Action Button
                Button(action: {
                    handleMessageTap()
                }) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Написать сообщение")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Private Methods

    private func handleMessageTap() {
        AppLog.d("UserDetail", "message tap: \(user.name)")
        // TODO: В будущем откроет экран чата
    }
}

// MARK: - Skills Section View

struct SkillsSectionView: View {
    let title: String
    let skills: [String]
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            // Skills List
            if skills.isEmpty {
                Text("Нет навыков")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(spacing: 8) {
                    ForEach(skills, id: \.self) { skill in
                        HStack {
                            Image(systemName: icon)
                                .foregroundColor(iconColor)
                                .font(.caption)

                            Text(skill)
                                .font(.body)

                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        UserDetailView(
            user: UserSummary(
                id: "preview1",
                name: "Алексей Иванов",
                teachSkills: ["Swift", "iOS разработка", "UIKit"],
                learnSkills: ["SwiftUI", "Combine"],
                rating: 4.8,
                points: 250
            )
        )
    }
}
