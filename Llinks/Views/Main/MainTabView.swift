//
//  MainTabView.swift
//  Llinks
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverView()
                .tabItem {
                    Label("Поиск", systemImage: "magnifyingglass")
                }
                .tag(0)

            SwipeView()
                .tabItem {
                    Label("Знакомства", systemImage: "heart.circle")
                }
                .tag(1)

            ChatsWithMatchesView()
                .tabItem {
                    Label("Чаты", systemImage: "message")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person")
                }
                .tag(3)
        }
    }
}

#Preview {
    MainTabView()
}
