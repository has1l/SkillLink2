//
//  EditProfileView.swift
//  Llinks
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileViewModel

    @State private var location: String
    @State private var bio: String

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        _location = State(initialValue: viewModel.profile.location)
        _bio = State(initialValue: viewModel.profile.bio)
    }

    private var isBioValid: Bool {
        bio.count <= 140
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Местоположение") {
                    TextField("Город, страна", text: $location)
                }

                Section {
                    TextEditor(text: $bio)
                        .frame(minHeight: 100)
                    HStack {
                        Spacer()
                        Text("\(bio.count)/140")
                            .font(.caption)
                            .foregroundColor(bio.count > 140 ? .red : .secondary)
                    }
                } header: {
                    Text("О себе")
                }
            }
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveProfile()
                    }
                    .disabled(!isBioValid)
                }
            }
        }
    }

    private func saveProfile() {
        viewModel.updateLocation(location)
        viewModel.updateBio(bio)
        Task {
            await viewModel.saveProfile()
            dismiss()
        }
    }
}

#Preview {
    EditProfileView(viewModel: ProfileViewModel())
}
