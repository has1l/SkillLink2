//
//  SwipeView.swift
//  Llinks
//

import SwiftUI

struct SwipeView: View {
    @StateObject private var viewModel = SwipeViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("Загрузка...")
                } else if let user = viewModel.currentUser {
                    VStack(spacing: 0) {
                        Spacer(minLength: 16)

                        // Карточка с drag
                        SwipeCardView(user: user, dragOffset: dragOffset)
                            .offset(x: dragOffset.width, y: 0)
                            .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragOffset = value.translation
                                    }
                                    .onEnded { value in
                                        if value.translation.width > 100 {
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                dragOffset = CGSize(width: 500, height: 0)
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                dragOffset = .zero
                                                viewModel.like()
                                            }
                                        } else if value.translation.width < -100 {
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                dragOffset = CGSize(width: -500, height: 0)
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                dragOffset = .zero
                                                viewModel.pass()
                                            }
                                        } else {
                                            withAnimation(.spring()) {
                                                dragOffset = .zero
                                            }
                                        }
                                    }
                            )

                        Spacer()
                    }
                } else {
                    ContentUnavailableView(
                        "Пока никого нет",
                        systemImage: "person.slash",
                        description: Text("Вы просмотрели всех пользователей")
                    )
                }
            }
            .navigationTitle("Знакомства")
            .onAppear {
                if let uid = authService.user?.id {
                    Task {
                        await viewModel.loadCandidates(myUid: uid)
                    }
                }
            }
            .alert("Совпадение!", isPresented: $viewModel.showMatch) {
                Button("OK") {
                    viewModel.dismissMatch()
                }
            } message: {
                if let matched = viewModel.matchedUser {
                    Text("Вы понравились друг другу с \(matched.name)!")
                }
            }
        }
    }
}

// MARK: - Swipe Card

struct SwipeCardView: View {
    let user: UserSummary
    var dragOffset: CGSize = .zero

    private var likeOpacity: Double {
        min(max(Double(dragOffset.width) / 100, 0), 1)
    }

    private var passOpacity: Double {
        min(max(Double(-dragOffset.width) / 100, 0), 1)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 16) {
                // Avatar
                SwipeAvatarView(url: user.avatarURL, size: 130)

                // Name
                Text(user.name.isEmpty ? "Без имени" : user.name)
                    .font(.title2)
                    .fontWeight(.bold)

                // Location
                if !user.location.isEmpty {
                    Label(user.location, systemImage: "mappin")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Bio
                if !user.bio.isEmpty {
                    Text(user.bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 8)
                }

                // Skills
                VStack(spacing: 12) {
                    if !user.teachSkills.isEmpty {
                        SwipeSkillSection(title: "Может обучить", skills: user.teachSkills, isTeach: true)
                    }
                    if !user.learnSkills.isEmpty {
                        SwipeSkillSection(title: "Хочет изучить", skills: user.learnSkills, isTeach: false)
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(22)
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)

            // LIKE overlay
            Text("НРАВИТСЯ")
                .font(.title)
                .fontWeight(.heavy)
                .foregroundColor(.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green, lineWidth: 4)
                )
                .rotationEffect(.degrees(-15))
                .offset(x: -40, y: 30)
                .opacity(likeOpacity)

            // PASS overlay
            Text("ПРОПУСК")
                .font(.title)
                .fontWeight(.heavy)
                .foregroundColor(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red, lineWidth: 4)
                )
                .rotationEffect(.degrees(15))
                .offset(x: -40, y: 30)
                .opacity(passOpacity)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Components

struct SwipeAvatarView: View {
    let url: String?
    var size: CGFloat = 130

    var body: some View {
        if let photoURL = url, let imageUrl = URL(string: photoURL) {
            AsyncImage(url: imageUrl) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color(UIColor.systemGray5))
                    .overlay(ProgressView())
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        } else {
            Circle()
                .fill(Color(UIColor.systemGray5))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.45))
                        .foregroundColor(Color(UIColor.systemGray3))
                )
        }
    }
}

struct SwipeSkillSection: View {
    let title: String
    let skills: [String]
    let isTeach: Bool

    private var displaySkills: [String] { Array(skills.prefix(3)) }
    private var extraCount: Int { max(0, skills.count - 3) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            HStack(spacing: 6) {
                ForEach(displaySkills, id: \.self) { skill in
                    Text(skill)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(isTeach ? Color.green.opacity(0.12) : Color.blue.opacity(0.12))
                        )
                        .foregroundColor(isTeach ? .green : .blue)
                }
                if extraCount > 0 {
                    Text("+\(extraCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SwipeView()
        .environmentObject(AuthService())
}
