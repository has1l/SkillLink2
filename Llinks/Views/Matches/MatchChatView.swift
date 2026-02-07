//
//  MatchChatView.swift
//  Llinks
//

import SwiftUI
import FirebaseFirestore

struct ChatMessage: Identifiable {
    let id: String
    let senderId: String
    let text: String
    let createdAt: Date?
}

struct MatchChatView: View {
    let chatId: String
    let otherUser: UserSummary
    @EnvironmentObject var authService: AuthService

    @State private var messages: [ChatMessage] = []
    @State private var newMessage = ""
    @State private var listener: ListenerRegistration?
    @State private var showCall = false
    @State private var showSession = false
    @State private var activeSession: Session?
    @State private var callManager: CallManager?
    @State private var incomingSignaling: CallSignaling?

    private var myUid: String { authService.user?.id ?? "" }

    var body: some View {
        VStack(spacing: 0) {
            if let session = activeSession, session.status != "cancelled" {
                SessionBannerView(
                    session: session, myUid: myUid,
                    onConfirm: { confirmFromBanner() },
                    onDecline: { declineFromBanner() },
                    onTap: { showSession = true }
                )
                Divider()
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { msg in
                            MessageBubble(
                                text: msg.text,
                                isMe: msg.senderId == myUid
                            )
                            .id(msg.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            HStack(spacing: 12) {
                TextField("Сообщение...", text: $newMessage)
                    .textFieldStyle(.roundedBorder)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(newMessage.isEmpty ? .gray : .blue)
                }
                .disabled(newMessage.isEmpty)
            }
            .padding()
        }
        .navigationTitle(otherUser.name.isEmpty ? "Чат" : otherUser.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showSession = true
                } label: {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.blue)
                }

                Button {
                    startOutgoingCall()
                } label: {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .sheet(isPresented: $showSession, onDismiss: {
            Task { await loadActiveSession() }
        }) {
            SessionFlowView(chatId: chatId, myUid: myUid, otherUid: otherUser.id)
        }
        .onAppear {
            startListening()
            listenForIncomingCalls()
            Task { await loadActiveSession() }
        }
        .onDisappear {
            listener?.remove()
            incomingSignaling?.removeAllListeners()
        }
        .fullScreenCover(isPresented: $showCall) {
            if let cm = callManager {
                CallView(manager: cm)
            }
        }
    }

    private func startOutgoingCall() {
        guard !myUid.isEmpty else { return }
        let cm = CallManager(
            chatId: chatId, myUid: myUid, otherUid: otherUser.id,
            otherName: otherUser.name, isCaller: true
        )
        callManager = cm
        showCall = true
    }

    private func listenForIncomingCalls() {
        guard !myUid.isEmpty else { return }
        let sig = CallSignaling(chatId: chatId)
        incomingSignaling = sig
        sig.listenForIncomingCall(toUid: myUid) { callId, fromUid in
            guard !showCall else { return }
            let cm = CallManager(
                chatId: chatId, myUid: myUid, otherUid: fromUid,
                otherName: otherUser.name, isCaller: false, callId: callId
            )
            callManager = cm
            showCall = true
        }
    }

    private func startListening() {
        listener = FirestoreService.shared.messagesListener(chatId: chatId) { data in
            self.messages = data.map { dict in
                let ts = dict["createdAt"] as? Timestamp
                return ChatMessage(
                    id: dict["id"] as? String ?? UUID().uuidString,
                    senderId: dict["senderId"] as? String ?? "",
                    text: dict["text"] as? String ?? "",
                    createdAt: ts?.dateValue()
                )
            }
        }
    }

    private func sendMessage() {
        let text = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !myUid.isEmpty else { return }
        newMessage = ""
        Task {
            try? await FirestoreService.shared.sendMessage(chatId: chatId, senderId: myUid, text: text)
        }
    }

    private func loadActiveSession() async {
        activeSession = try? await FirestoreService.shared.findActiveSession(chatId: chatId, myUid: myUid)
    }

    private func confirmFromBanner() {
        guard let session = activeSession else { return }
        Task {
            try? await FirestoreService.shared.confirmSession(sessionId: session.id, uid: myUid)
            await loadActiveSession()
            if let s = activeSession, s.status == "scheduled" {
                s.scheduleNotification()
            }
        }
    }

    private func declineFromBanner() {
        guard let session = activeSession else { return }
        Task {
            try? await FirestoreService.shared.cancelSession(sessionId: session.id)
            await loadActiveSession()
        }
    }
}

struct MessageBubble: View {
    let text: String
    let isMe: Bool

    var body: some View {
        HStack {
            if isMe { Spacer(minLength: 40) }
            Text(text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isMe ? Color.blue : Color(.systemGray5))
                .foregroundColor(isMe ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            if !isMe { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: isMe ? .trailing : .leading)
    }
}

#Preview {
    NavigationStack {
        MatchChatView(chatId: "test", otherUser: UserSummary(id: "1", name: "Тест"))
            .environmentObject(AuthService())
    }
}
