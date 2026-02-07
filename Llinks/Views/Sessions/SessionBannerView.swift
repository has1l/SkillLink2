//
//  SessionBannerView.swift
//  Llinks
//

import SwiftUI

struct SessionBannerView: View {
    let session: Session
    let myUid: String
    var onConfirm: () -> Void
    var onDecline: () -> Void
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusTitle)
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.primary)

                        if let sub = statusSubtitle {
                            Text(sub)
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if session.status == "proposed" || session.status == "scheduled" {
                        HStack(spacing: 4) {
                            ForEach(session.users, id: \.self) { uid in
                                Image(systemName: (session.confirmations[uid] ?? false)
                                      ? "checkmark.circle.fill" : "circle")
                                    .font(.caption)
                                    .foregroundColor((session.confirmations[uid] ?? false) ? .green : .gray)
                            }
                        }
                    }
                }

                if session.status == "proposed" && !(session.confirmations[myUid] ?? false) {
                    HStack(spacing: 8) {
                        Button {
                            onConfirm()
                        } label: {
                            Text("Подтвердить")
                                .font(.caption).fontWeight(.semibold)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color.green).foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        Button {
                            onDecline()
                        } label: {
                            Text("Отклонить")
                                .font(.caption).fontWeight(.semibold)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color.red.opacity(0.8)).foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
        }
        .buttonStyle(.plain)
    }

    private var statusIcon: String {
        switch session.status {
        case "draft": return "square.and.pencil"
        case "proposed": return "clock.badge.questionmark"
        case "scheduled": return "checkmark.seal.fill"
        default: return "questionmark.circle"
        }
    }

    private var statusColor: Color {
        switch session.status {
        case "draft": return .blue
        case "proposed": return .orange
        case "scheduled": return .green
        default: return .secondary
        }
    }

    private var statusTitle: String {
        switch session.status {
        case "draft": return "Черновик занятия"
        case "proposed": return session.title.isEmpty ? "Занятие предложено" : session.title
        case "scheduled": return session.title.isEmpty ? "Запланировано" : session.title
        default: return session.status
        }
    }

    private var statusSubtitle: String? {
        if session.status == "draft" { return "Нажмите, чтобы заполнить" }
        guard let start = session.startAt else { return nil }
        let s = start.formatted(date: .abbreviated, time: .shortened)
        return session.durationMin > 0 ? "\(s) · \(session.durationMin) мин" : s
    }
}
