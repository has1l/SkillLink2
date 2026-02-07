//
//  Session.swift
//  Llinks
//

import Foundation
import UserNotifications

struct Session: Identifiable {
    let id: String
    let chatId: String
    let users: [String]
    let createdBy: String
    var status: String // draft | proposed | scheduled | active | finished | cancelled
    var confirmations: [String: Bool]
    var title: String
    var startAt: Date?
    var durationMin: Int
    var callLink: String
    let createdAt: Date?
    var updatedAt: Date?

    func scheduleNotification() {
        guard let startAt else { return }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }

        let content = UNMutableNotificationContent()
        content.title = "Занятие скоро"
        content.body = title.isEmpty ? "Через 15 минут" : "\(title) — через 15 минут"
        content.sound = .default

        let fire = startAt.addingTimeInterval(-15 * 60)
        guard fire > Date() else { return }
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req = UNNotificationRequest(identifier: "session_\(id)", content: content, trigger: trigger)
        center.add(req)
    }
}
