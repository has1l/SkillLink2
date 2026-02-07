//
//  CallSignaling.swift
//  Llinks
//

import Foundation
import FirebaseFirestore

class CallSignaling {
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []

    let chatId: String
    var callId: String?

    init(chatId: String) {
        self.chatId = chatId
    }

    private var callsRef: CollectionReference {
        db.collection("chats").document(chatId).collection("calls")
    }

    func callDoc(_ id: String) -> DocumentReference {
        callsRef.document(id)
    }

    // MARK: - Caller

    func createCall(fromUid: String, toUid: String) async throws -> String {
        let ref = callsRef.document()
        let cid = ref.documentID
        try await ref.setData([
            "fromUid": fromUid,
            "toUid": toUid,
            "status": "ringing",
            "offer": "",
            "answer": "",
            "createdAt": FieldValue.serverTimestamp()
        ])
        self.callId = cid
        return cid
    }

    func writeOffer(_ sdp: String) async throws {
        guard let cid = callId else { return }
        try await callDoc(cid).updateData(["offer": sdp, "status": "ringing"])
    }

    func writeAnswer(_ sdp: String) async throws {
        guard let cid = callId else { return }
        try await callDoc(cid).updateData(["answer": sdp, "status": "connecting"])
    }

    func writeCandidate(_ candidate: [String: Any], isCaller: Bool) async throws {
        guard let cid = callId else { return }
        let sub = isCaller ? "offerCandidates" : "answerCandidates"
        try await callDoc(cid).collection(sub).addDocument(data: candidate)
    }

    func endCall() async throws {
        guard let cid = callId else { return }
        try await callDoc(cid).updateData(["status": "ended"])
    }

    // MARK: - Listeners

    func listenForAnswer(onChange: @escaping (String) -> Void) {
        guard let cid = callId else { return }
        let l = callDoc(cid).addSnapshotListener { snap, _ in
            guard let data = snap?.data(), let answer = data["answer"] as? String, !answer.isEmpty else { return }
            onChange(answer)
        }
        listeners.append(l)
    }

    func listenForStatus(onChange: @escaping (String) -> Void) {
        guard let cid = callId else { return }
        let l = callDoc(cid).addSnapshotListener { snap, _ in
            guard let data = snap?.data(), let status = data["status"] as? String else { return }
            onChange(status)
        }
        listeners.append(l)
    }

    func listenForCandidates(isCaller: Bool, onCandidate: @escaping ([String: Any]) -> Void) {
        guard let cid = callId else { return }
        let sub = isCaller ? "answerCandidates" : "offerCandidates"
        let l = callDoc(cid).collection(sub).addSnapshotListener { snap, _ in
            snap?.documentChanges.forEach { change in
                if change.type == .added {
                    onCandidate(change.document.data())
                }
            }
        }
        listeners.append(l)
    }

    func listenForIncomingCall(toUid: String, onIncoming: @escaping (String, String) -> Void) {
        let l = callsRef
            .whereField("toUid", isEqualTo: toUid)
            .whereField("status", isEqualTo: "ringing")
            .addSnapshotListener { snap, _ in
                snap?.documentChanges.forEach { change in
                    if change.type == .added {
                        let data = change.document.data()
                        let fromUid = data["fromUid"] as? String ?? ""
                        onIncoming(change.document.documentID, fromUid)
                    }
                }
            }
        listeners.append(l)
    }

    func loadOffer(callId: String) async throws -> String {
        self.callId = callId
        let doc = try await callDoc(callId).getDocument()
        return doc.data()?["offer"] as? String ?? ""
    }

    func removeAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }

    deinit {
        removeAllListeners()
    }
}
