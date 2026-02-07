//
//  SkillsView.swift
//  Llinks
//

import SwiftUI

struct SkillsView: View {
    @StateObject private var viewModel = SkillsViewModel()
    @EnvironmentObject var authService: AuthService

    @State private var newLearnSkill = ""
    @State private var newTeachSkill = ""

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Хочу изучить
                Section {
                    ForEach(viewModel.learnSkills, id: \.self) { skill in
                        Text(skill)
                    }
                    .onDelete { offsets in
                        viewModel.removeLearnSkill(at: offsets)
                    }

                    HStack {
                        TextField("Новый навык", text: $newLearnSkill)
                        Button("Добавить") {
                            viewModel.addLearnSkill(newLearnSkill)
                            newLearnSkill = ""
                        }
                        .disabled(newLearnSkill.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Хочу изучить")
                }

                // MARK: - Могу обучать
                Section {
                    ForEach(viewModel.teachSkills, id: \.self) { skill in
                        Text(skill)
                    }
                    .onDelete { offsets in
                        viewModel.removeTeachSkill(at: offsets)
                    }

                    HStack {
                        TextField("Новый навык", text: $newTeachSkill)
                        Button("Добавить") {
                            viewModel.addTeachSkill(newTeachSkill)
                            newTeachSkill = ""
                        }
                        .disabled(newTeachSkill.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Могу обучать")
                }
            }
            .navigationTitle("Мои навыки")
            .onAppear {
                if let uid = authService.user?.id {
                    Task {
                        await viewModel.loadSkills(uid: uid)
                    }
                }
            }
        }
    }
}

#Preview {
    SkillsView()
        .environmentObject(AuthService())
}
