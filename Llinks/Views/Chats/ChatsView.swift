//
//  ChatsView.swift
//  Llinks
//

import SwiftUI

struct ChatsView: View {
    @StateObject private var viewModel = ChatsViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.chats.isEmpty {
                    ContentUnavailableView(
                        "Нет чатов",
                        systemImage: "message",
                        description: Text("Здесь будут отображаться ваши чаты с другими пользователями")
                    )
                } else {
                    List(viewModel.chats, id: \.self) { chat in
                        Text(chat)
                    }
                }
            }
            .navigationTitle("Чаты")
        }
    }
}

#Preview {
    ChatsView()
}
