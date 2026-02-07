//
//  ChatsViewModel.swift
//  Llinks
//

import Foundation
import Combine

class ChatsViewModel: ObservableObject {
    @Published var chats: [String] = []

    init() {
        // Пустой инициализатор
    }
}
