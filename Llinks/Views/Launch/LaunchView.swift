//
//  LaunchView.swift
//  Llinks
//

import SwiftUI

struct LaunchView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthService

    var body: some View {
        VStack {
            Spacer()

            Text("Llinks")
                .font(.system(size: 48, weight: .bold))

            Text("Обменивайтесь навыками")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    appState.checkInitialFlow(isAuthenticated: authService.isAuthenticated)
                }
            }
        }
    }
}

#Preview {
    LaunchView()
}
