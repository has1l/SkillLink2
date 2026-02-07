//
//  SessionFlowView.swift
//  Llinks
//

import SwiftUI

struct SessionFlowView: View {
    let chatId: String
    let myUid: String
    let otherUid: String

    @Environment(\.dismiss) private var dismiss
    @State private var session: Session?
    @State private var isLoading = true
    @State private var isSending = false
    @State private var errorMsg: String?
    @State private var isEditing = false

    // Form
    @State private var title = ""
    @State private var startAt = Date().addingTimeInterval(3600)
    @State private var durationMin = 60
    @State private var callLinkInput = ""

    // Review (kept for future finished flow)
    @State private var stars: Int = 5
    @State private var reviewText = ""

    private var users: [String] { [myUid, otherUid] }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Загрузка...")
                } else if let session {
                    ScrollView {
                        contentView(for: session).padding()
                    }
                } else {
                    ContentUnavailableView("Ошибка", systemImage: "exclamationmark.triangle")
                }
            }
            .navigationTitle("Занятие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
        .task { await loadOrCreate() }
    }

    // MARK: - Content Router

    @ViewBuilder
    private func contentView(for session: Session) -> some View {
        VStack(spacing: 20) {
            if session.status == "draft" || isEditing {
                proposalForm(session)
            } else {
                switch session.status {
                case "proposed": proposedView(session)
                case "scheduled": scheduledView(session)
                case "cancelled": cancelledView()
                default: Text("Статус: \(session.status)")
                }
            }

            if let errorMsg {
                Text(errorMsg).font(.caption).foregroundColor(.red)
            }
        }
    }

    // MARK: - Proposal Form

    @ViewBuilder
    private func proposalForm(_ session: Session) -> some View {
        Image(systemName: "square.and.pencil")
            .font(.system(size: 40))
            .foregroundColor(.blue)

        Text(isEditing ? "Изменить занятие" : "Новое занятие")
            .font(.headline)

        TextField("Название занятия", text: $title)
            .textFieldStyle(.roundedBorder)

        DatePicker("Начало", selection: $startAt, in: Date()...,
                   displayedComponents: [.date, .hourAndMinute])

        Picker("Длительность", selection: $durationMin) {
            Text("30 мин").tag(30)
            Text("45 мин").tag(45)
            Text("60 мин").tag(60)
            Text("90 мин").tag(90)
            Text("120 мин").tag(120)
        }
        .pickerStyle(.segmented)

        Button {
            Task { await propose(session) }
        } label: {
            Group {
                if isSending { ProgressView() } else { Text("Предложить") }
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(title.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isSending || title.trimmingCharacters(in: .whitespaces).isEmpty)

        if isEditing {
            Button("Отмена") { isEditing = false }
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Proposed

    @ViewBuilder
    private func proposedView(_ session: Session) -> some View {
        Image(systemName: "clock.badge.questionmark")
            .font(.system(size: 40))
            .foregroundColor(.orange)

        Text(session.title.isEmpty ? "Занятие" : session.title)
            .font(.headline)

        sessionInfoRow(session)
        confirmationsRow(session)

        let myConfirmed = session.confirmations[myUid] ?? false
        if !myConfirmed {
            HStack(spacing: 12) {
                Button {
                    Task { await confirm(session.id) }
                } label: {
                    Text("Подтвердить")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.green).foregroundColor(.white).cornerRadius(12)
                }
                .disabled(isSending)

                Button {
                    Task { await cancel(session.id) }
                } label: {
                    Text("Отклонить")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.red.opacity(0.8)).foregroundColor(.white).cornerRadius(12)
                }
                .disabled(isSending)
            }
        } else {
            Text("Вы подтвердили. Ожидаем партнёра.")
                .font(.subheadline).foregroundColor(.secondary)
        }

        Button("Изменить") {
            prefillForm(session)
            isEditing = true
        }
        .foregroundColor(.blue)
    }

    // MARK: - Scheduled

    @ViewBuilder
    private func scheduledView(_ session: Session) -> some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: 40))
            .foregroundColor(.green)

        Text("Запланировано!").font(.headline)

        Text(session.title.isEmpty ? "Занятие" : session.title)
            .font(.title3).fontWeight(.medium)

        sessionInfoRow(session)

        VStack(spacing: 8) {
            TextField("Ссылка на звонок", text: $callLinkInput)
                .textFieldStyle(.roundedBorder)
                .onAppear { callLinkInput = session.callLink }

            if callLinkInput != session.callLink {
                Button("Сохранить ссылку") {
                    Task { await saveCallLink(session.id) }
                }
                .font(.subheadline)
            } else if !session.callLink.isEmpty {
                Label("Ссылка сохранена", systemImage: "checkmark.circle.fill")
                    .font(.caption).foregroundColor(.green)
            }
        }

        Button {
            Task { await cancel(session.id) }
        } label: {
            Text("Отменить занятие").foregroundColor(.red)
        }
        .disabled(isSending)
    }

    // MARK: - Cancelled

    @ViewBuilder
    private func cancelledView() -> some View {
        Image(systemName: "xmark.circle.fill")
            .font(.system(size: 40))
            .foregroundColor(.secondary)
        Text("Занятие отменено")
            .font(.headline).foregroundColor(.secondary)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sessionInfoRow(_ session: Session) -> some View {
        VStack(spacing: 4) {
            if let start = session.startAt {
                Label(start.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .font(.subheadline)
            }
            if session.durationMin > 0 {
                Label("\(session.durationMin) мин", systemImage: "clock")
                    .font(.subheadline).foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func confirmationsRow(_ session: Session) -> some View {
        HStack(spacing: 16) {
            ForEach(session.users, id: \.self) { uid in
                let ok = session.confirmations[uid] ?? false
                HStack(spacing: 4) {
                    Image(systemName: ok ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(ok ? .green : .gray)
                    Text(uid == myUid ? "Вы" : "Партнёр")
                        .font(.subheadline)
                }
            }
        }
    }

    private func prefillForm(_ s: Session) {
        title = s.title
        startAt = s.startAt ?? Date().addingTimeInterval(3600)
        durationMin = s.durationMin > 0 ? s.durationMin : 60
    }

    // MARK: - Actions

    private func loadOrCreate() async {
        do {
            if let existing = try await FirestoreService.shared.findActiveSession(chatId: chatId, myUid: myUid) {
                session = existing
                if existing.status == "draft" { prefillForm(existing) }
            } else {
                session = try await FirestoreService.shared.createDraftSession(
                    chatId: chatId, users: users, createdBy: myUid
                )
            }
        } catch {
            AppLog.e("Session", "loadOrCreate: \(error.localizedDescription)")
            errorMsg = error.localizedDescription
        }
        isLoading = false
    }

    private func propose(_ session: Session) async {
        isSending = true; errorMsg = nil
        do {
            try await FirestoreService.shared.proposeSession(
                sessionId: session.id, title: title.trimmingCharacters(in: .whitespaces),
                startAt: startAt, durationMin: durationMin,
                proposerUid: myUid, users: session.users
            )
            isEditing = false
            self.session = try await FirestoreService.shared.getSession(sessionId: session.id)
        } catch {
            AppLog.e("Session", "propose: \(error.localizedDescription)")
            errorMsg = error.localizedDescription
        }
        isSending = false
    }

    private func confirm(_ sessionId: String) async {
        isSending = true; errorMsg = nil
        do {
            try await FirestoreService.shared.confirmSession(sessionId: sessionId, uid: myUid)
            if let fresh = try await FirestoreService.shared.getSession(sessionId: sessionId) {
                self.session = fresh
                if fresh.status == "scheduled" { fresh.scheduleNotification() }
            }
        } catch {
            AppLog.e("Session", "confirm: \(error.localizedDescription)")
            errorMsg = error.localizedDescription
        }
        isSending = false
    }

    private func cancel(_ sessionId: String) async {
        isSending = true; errorMsg = nil
        do {
            try await FirestoreService.shared.cancelSession(sessionId: sessionId)
            self.session = try await FirestoreService.shared.getSession(sessionId: sessionId)
        } catch {
            AppLog.e("Session", "cancel: \(error.localizedDescription)")
            errorMsg = error.localizedDescription
        }
        isSending = false
    }

    private func saveCallLink(_ sessionId: String) async {
        do {
            try await FirestoreService.shared.updateSessionCallLink(
                sessionId: sessionId, callLink: callLinkInput.trimmingCharacters(in: .whitespaces)
            )
            self.session = try await FirestoreService.shared.getSession(sessionId: sessionId)
        } catch {
            AppLog.e("Session", "saveLink: \(error.localizedDescription)")
            errorMsg = error.localizedDescription
        }
    }
}
