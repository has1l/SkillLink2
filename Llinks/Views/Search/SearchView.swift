//
//  SearchView.swift
//  Llinks
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Search Bar
                SearchBarView(query: $viewModel.query)
                    .padding()

                // MARK: - Results List
                if viewModel.filteredUsers.isEmpty {
                    EmptySearchResultView(hasQuery: !viewModel.query.isEmpty)
                } else {
                    List(viewModel.filteredUsers) { user in
                        NavigationLink(destination: UserDetailView(user: user)) {
                            UserRowView(user: user)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Поиск")
        }
    }
}

// MARK: - Search Bar View

struct SearchBarView: View {
    @Binding var query: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Найти по навыку", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !query.isEmpty {
                Button(action: {
                    query = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - User Row View

struct UserRowView: View {
    let user: UserSummary

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Image(systemName: "person.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            // User Info
            VStack(alignment: .leading, spacing: 6) {
                // Name
                Text(user.name)
                    .font(.headline)
                    .lineLimit(1)

                // Skills
                if !user.teachSkills.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)

                        Text(displayedSkills)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    /// Отображаем первые 3 навыка
    private var displayedSkills: String {
        let skills = Array(user.teachSkills.prefix(3))
        let skillsText = skills.joined(separator: ", ")

        if user.teachSkills.count > 3 {
            return skillsText + "..."
        }
        return skillsText
    }
}

// MARK: - Empty State View

struct EmptySearchResultView: View {
    let hasQuery: Bool

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: hasQuery ? "magnifyingglass" : "person.3")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(hasQuery ? "Ничего не найдено" : "Найдите людей по навыкам")
                .font(.title3)
                .fontWeight(.semibold)

            Text(hasQuery
                ? "Попробуйте изменить запрос"
                : "Введите навык, который хотите изучить"
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)

            Spacer()
        }
    }
}

#Preview {
    SearchView()
}
