//
//  ProfileSetupView.swift
//  Llinks
//

import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var authService: AuthService

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var location = ""
    @State private var bio = ""
    @State private var newLearnSkill = ""
    @State private var newTeachSkill = ""
    @State private var learnSkills: [String] = []
    @State private var teachSkills: [String] = []
    @State private var isLoading = false

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        bio.count <= 140 &&
        !learnSkills.isEmpty &&
        !teachSkills.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Personal Info
                Section("Личная информация") {
                    TextField("Имя", text: $firstName)
                    TextField("Фамилия", text: $lastName)
                    TextField("Город, страна", text: $location)
                }

                // MARK: - Bio
                Section {
                    TextEditor(text: $bio)
                        .frame(minHeight: 80)
                    HStack {
                        Spacer()
                        Text("\(bio.count)/140")
                            .font(.caption)
                            .foregroundColor(bio.count > 140 ? .red : .secondary)
                    }
                } header: {
                    Text("О себе")
                }

                // MARK: - Learn Skills
                Section {
                    ForEach(learnSkills, id: \.self) { skill in
                        Text(skill)
                    }
                    .onDelete { indexSet in
                        learnSkills.remove(atOffsets: indexSet)
                    }

                    HStack {
                        TextField("Новый навык", text: $newLearnSkill)
                        Button("Добавить") {
                            addLearnSkill()
                        }
                        .disabled(newLearnSkill.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Хочу изучить (минимум 1)")
                }

                // MARK: - Teach Skills
                Section {
                    ForEach(teachSkills, id: \.self) { skill in
                        Text(skill)
                    }
                    .onDelete { indexSet in
                        teachSkills.remove(atOffsets: indexSet)
                    }

                    HStack {
                        TextField("Новый навык", text: $newTeachSkill)
                        Button("Добавить") {
                            addTeachSkill()
                        }
                        .disabled(newTeachSkill.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Могу обучать (минимум 1)")
                }

                // MARK: - Continue Button
                Section {
                    Button(action: completeSetup) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Продолжить")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .navigationTitle("Настройка профиля")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func addLearnSkill() {
        let skill = newLearnSkill.trimmingCharacters(in: .whitespaces)
        guard !skill.isEmpty, !learnSkills.contains(skill) else { return }
        learnSkills.append(skill)
        newLearnSkill = ""
    }

    private func addTeachSkill() {
        let skill = newTeachSkill.trimmingCharacters(in: .whitespaces)
        guard !skill.isEmpty, !teachSkills.contains(skill) else { return }
        teachSkills.append(skill)
        newTeachSkill = ""
    }

    private func completeSetup() {
        guard let uid = authService.user?.id else { return }
        isLoading = true

        Task {
            do {
                try await FirestoreService.shared.completeProfileSetup(
                    uid: uid,
                    firstName: firstName.trimmingCharacters(in: .whitespaces),
                    lastName: lastName.trimmingCharacters(in: .whitespaces),
                    location: location.trimmingCharacters(in: .whitespaces),
                    bio: bio,
                    teachSkills: teachSkills,
                    learnSkills: learnSkills
                )
                await MainActor.run {
                    authService.setProfileCompleted()
                    isLoading = false
                }
            } catch {
                AppLog.e("ProfileSetup", "error: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(AuthService())
}
