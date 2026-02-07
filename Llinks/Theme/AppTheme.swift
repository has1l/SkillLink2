//
//  AppTheme.swift
//  Llinks
//

import SwiftUI

enum AppTheme {
    static let primary = Color.blue
    static let secondary = Color(UIColor.systemGray5)
    static let cardBg = Color(UIColor.systemBackground)
    static let radius: CGFloat = 14
    static let shadowRadius: CGFloat = 4
    static let shadowOpacity: CGFloat = 0.1
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AppTheme.primary)
            .cornerRadius(AppTheme.radius)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppTheme.cardBg)
            .cornerRadius(AppTheme.radius)
            .shadow(color: .black.opacity(AppTheme.shadowOpacity), radius: AppTheme.shadowRadius, y: 2)
    }
}

struct SkillTag: View {
    let text: String
    var isTeach: Bool = false

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isTeach ? Color.green.opacity(0.15) : AppTheme.primary.opacity(0.15))
            .foregroundColor(isTeach ? .green : AppTheme.primary)
            .cornerRadius(12)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
