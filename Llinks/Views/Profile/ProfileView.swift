//
//  ProfileView.swift
//  Llinks
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Аватар и имя
                Section {
                    HStack(spacing: 16) {
                        if let photoURL = viewModel.profile.avatarURL,
                           let url = URL(string: photoURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 70))
                                .foregroundColor(.gray)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.profile.name.isEmpty ? "Имя не указано" : viewModel.profile.name)
                                .font(.title2)
                                .fontWeight(.semibold)

                            if !viewModel.profile.location.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(viewModel.profile.location)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // MARK: - О себе
                if !viewModel.profile.bio.isEmpty {
                    Section("О себе") {
                        Text(viewModel.profile.bio)
                            .font(.body)
                    }
                }

                // MARK: - Статистика
                Section("Статистика") {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Рейтинг")
                        Spacer()
                        Text(String(format: "%.1f", viewModel.profile.rating))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.orange)
                        Text("Баллы")
                        Spacer()
                        Text("\(viewModel.profile.points)")
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: - Действия
                Section {
                    NavigationLink(destination: SkillsView()) {
                        Label("Мои навыки", systemImage: "star")
                    }

                    Button(action: {
                        showEditProfile = true
                    }) {
                        Label("Редактировать", systemImage: "pencil")
                    }

                    Button(role: .destructive, action: {
                        authService.signOut()
                    }) {
                        Label("Выйти", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Профиль")
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(viewModel: viewModel)
            }
            .onAppear {
                if let uid = authService.user?.id {
                    Task {
                        await viewModel.loadProfile(uid: uid)
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthService())
}
