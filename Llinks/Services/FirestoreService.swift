//
//  FirestoreService.swift
//  Llinks
//

import Foundation
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Debug

    func testPing(uid: String) async throws {
        let pingRef = db.collection("debug").document("ping")
        let pingData: [String: Any] = [
            "uid": uid,
            "timestamp": FieldValue.serverTimestamp(),
            "test": "ping"
        ]
        do {
            try await pingRef.setData(pingData, merge: true)
            AppLog.d("Firestore", "ping OK: \(uid)")
        } catch {
            let nsError = error as NSError
            AppLog.e("Firestore", "ping FAIL: \(nsError.domain) code=\(nsError.code) \(nsError.localizedDescription)")
            throw error
        }
    }

    // MARK: - User Management

    /// Проверяет существует ли документ и возвращает profileCompleted
    func checkProfileCompleted(uid: String) async throws -> Bool {
        let doc = try await db.collection("users").document(uid).getDocument()
        if doc.exists, let data = doc.data() {
            return data["profileCompleted"] as? Bool ?? false
        }
        return false
    }

    /// Создает DRAFT документ если не существует, иначе возвращает profileCompleted
    func createDraftUserIfNeeded(uid: String, email: String?, photoURL: String?) async throws -> Bool {
        let userRef = db.collection("users").document(uid)
        let doc = try await userRef.getDocument()

        if doc.exists, let data = doc.data() {
            // Документ существует - возвращаем profileCompleted
            AppLog.d("Firestore", "user exists, profileCompleted=\(data["profileCompleted"] ?? false)")
            return data["profileCompleted"] as? Bool ?? false
        }

        // Создаем DRAFT
        let draftData: [String: Any] = [
            "uid": uid,
            "email": email ?? "",
            "photoURL": photoURL ?? "",
            "firstName": "",
            "lastName": "",
            "fullName": "",
            "location": "",
            "bio": "",
            "teachSkills": [],
            "learnSkills": [],
            "profileCompleted": false,
            "rating": 0.0,
            "points": 0,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await userRef.setData(draftData)
        AppLog.i("Firestore", "draft created uid=\(uid)")
        return false
    }

    /// Завершает настройку профиля
    func completeProfileSetup(
        uid: String,
        firstName: String,
        lastName: String,
        location: String,
        bio: String,
        teachSkills: [String],
        learnSkills: [String]
    ) async throws {
        let userRef = db.collection("users").document(uid)

        let updateData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "fullName": "\(firstName) \(lastName)",
            "location": location,
            "bio": bio,
            "teachSkills": teachSkills,
            "learnSkills": learnSkills,
            "profileCompleted": true,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await userRef.setData(updateData, merge: true)
        AppLog.i("Firestore", "profile completed uid=\(uid)")
    }

    func getUser(uid: String) async throws -> UserProfile? {
        let doc = try await db.collection("users").document(uid).getDocument()

        guard doc.exists, let data = doc.data() else {
            return nil
        }

        return UserProfile(
            id: UUID(uuidString: data["uid"] as? String ?? "") ?? UUID(),
            name: data["fullName"] as? String ?? "",
            avatarURL: data["photoURL"] as? String,
            location: data["location"] as? String ?? "",
            bio: data["bio"] as? String ?? "",
            teachSkills: data["teachSkills"] as? [String] ?? [],
            learnSkills: data["learnSkills"] as? [String] ?? [],
            rating: data["rating"] as? Double ?? 0.0,
            points: data["points"] as? Int ?? 0
        )
    }

    func updateSkills(uid: String, teachSkills: [String], learnSkills: [String]) async throws {
        let userRef = db.collection("users").document(uid)
        try await userRef.setData([
            "teachSkills": teachSkills,
            "learnSkills": learnSkills,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    func updateProfileInfo(uid: String, location: String, bio: String) async throws {
        let userRef = db.collection("users").document(uid)
        try await userRef.setData([
            "location": location,
            "bio": bio,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    // MARK: - Paginated Users

    func getUsersPage(afterDocument: DocumentSnapshot?, limit: Int) async throws -> (users: [UserSummary], lastDocument: DocumentSnapshot?) {
        var query: Query = db.collection("users")
            .whereField("profileCompleted", isEqualTo: true)
            .order(by: "updatedAt", descending: true)
            .limit(to: limit)

        if let after = afterDocument {
            query = query.start(afterDocument: after)
        }

        let snapshot = try await query.getDocuments()

        let users = snapshot.documents.compactMap { doc -> UserSummary? in
            let data = doc.data()
            let uid = data["uid"] as? String ?? doc.documentID
            return UserSummary(
                id: uid,
                name: data["fullName"] as? String ?? "",
                avatarURL: data["photoURL"] as? String,
                location: data["location"] as? String ?? "",
                bio: data["bio"] as? String ?? "",
                teachSkills: data["teachSkills"] as? [String] ?? [],
                learnSkills: data["learnSkills"] as? [String] ?? [],
                rating: data["rating"] as? Double ?? 0.0,
                points: data["points"] as? Int ?? 0
            )
        }

        return (users: users, lastDocument: snapshot.documents.last)
    }

    func getAllUsers() async throws -> [UserSummary] {
        let snapshot = try await db.collection("users").getDocuments()

        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            let uid = data["uid"] as? String ?? doc.documentID
            return UserSummary(
                id: uid,
                name: data["fullName"] as? String ?? "",
                avatarURL: data["photoURL"] as? String,
                location: data["location"] as? String ?? "",
                bio: data["bio"] as? String ?? "",
                teachSkills: data["teachSkills"] as? [String] ?? [],
                learnSkills: data["learnSkills"] as? [String] ?? [],
                rating: data["rating"] as? Double ?? 0.0,
                points: data["points"] as? Int ?? 0
            )
        }
    }

    // MARK: - Swipe Actions

    func recordLike(fromUid: String, toUid: String) async throws {
        let likeRef = db.collection("users").document(fromUid).collection("likes").document(toUid)
        try await likeRef.setData(["createdAt": FieldValue.serverTimestamp()])
    }

    func recordPass(fromUid: String, toUid: String) async throws {
        let passRef = db.collection("users").document(fromUid).collection("passes").document(toUid)
        try await passRef.setData(["createdAt": FieldValue.serverTimestamp()])
    }

    func checkMutualLike(myUid: String, theirUid: String) async throws -> Bool {
        let theirLikeRef = db.collection("users").document(theirUid).collection("likes").document(myUid)
        let doc = try await theirLikeRef.getDocument()
        return doc.exists
    }

    func pairId(_ uid1: String, _ uid2: String) -> String {
        let sorted = [uid1, uid2].sorted()
        return "\(sorted[0])_\(sorted[1])"
    }

    func likeUser(myUid: String, theirUid: String) async throws -> Bool {
        // 1. Записать лайк
        let likeRef = db.collection("users").document(myUid).collection("likes").document(theirUid)
        try await likeRef.setData(["createdAt": FieldValue.serverTimestamp()])
        AppLog.d("Firestore", "like saved: \(myUid) -> \(theirUid)")

        // 2. Проверить взаимность
        // A) Прямой документ users/{theirUid}/likes/{myUid}
        var directDoc = false
        do {
            let doc = try await db.collection("users").document(theirUid).collection("likes").document(myUid).getDocument()
            directDoc = doc.exists
        } catch {
            AppLog.w("Firestore", "mutual directDoc error: \((error as NSError).code) \(error.localizedDescription)")
        }

        // B) Fallback query (autoId документы с полем uid)
        var queryFallback = false
        if !directDoc {
            do {
                let snap = try await db.collection("users").document(theirUid).collection("likes")
                    .whereField("uid", isEqualTo: myUid)
                    .limit(to: 1)
                    .getDocuments()
                queryFallback = !snap.documents.isEmpty
            } catch {
                AppLog.w("Firestore", "mutual query fallback error: \((error as NSError).code) \(error.localizedDescription)")
            }
        }

        let isMutual = directDoc || queryFallback
        let pid = pairId(myUid, theirUid)
        AppLog.d("Firestore", "mutual check: isMutual=\(isMutual) pairId=\(pid)")

        guard isMutual else { return false }

        // 3. Создать матч
        let users = [myUid, theirUid].sorted()

        do {
            try await db.collection("matches").document(pid).setData([
                "users": users,
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true)
            AppLog.i("Firestore", "match created pairId=\(pid)")
        } catch {
            let nsErr = error as NSError
            AppLog.e("Firestore", "match create FAILED: \(nsErr.domain) code=\(nsErr.code) \(nsErr.localizedDescription)")
        }

        // 4. Создать чат
        do {
            try await db.collection("chats").document(pid).setData([
                "users": users,
                "createdAt": FieldValue.serverTimestamp(),
                "lastMessage": "",
                "lastMessageAt": NSNull(),
                "lastSenderId": ""
            ], merge: true)
            AppLog.i("Firestore", "chat created pairId=\(pid)")
        } catch {
            let nsErr = error as NSError
            AppLog.e("Firestore", "chat create FAILED: \(nsErr.domain) code=\(nsErr.code) \(nsErr.localizedDescription)")
        }

        return true
    }

    func passUser(myUid: String, theirUid: String) async throws {
        let passRef = db.collection("users").document(myUid).collection("passes").document(theirUid)
        try await passRef.setData(["createdAt": FieldValue.serverTimestamp()])
    }

    func getMatches(uid: String) async throws -> [(pairId: String, otherUid: String)] {
        let snapshot = try await db.collection("matches")
            .whereField("users", arrayContains: uid)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            guard let users = doc.data()["users"] as? [String] else { return nil }
            let otherUid = users.first { $0 != uid } ?? ""
            return (pairId: doc.documentID, otherUid: otherUid)
        }
    }

    func createMatch(uid1: String, uid2: String) async throws {
        let sorted = [uid1, uid2].sorted()
        let matchId = "\(sorted[0])_\(sorted[1])"
        let matchRef = db.collection("matches").document(matchId)
        try await matchRef.setData([
            "users": sorted,
            "createdAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    func getLikedUserIds(uid: String) async throws -> Set<String> {
        let snapshot = try await db.collection("users").document(uid).collection("likes").getDocuments()
        return Set(snapshot.documents.map { $0.documentID })
    }

    func getPassedUserIds(uid: String) async throws -> Set<String> {
        let snapshot = try await db.collection("users").document(uid).collection("passes").getDocuments()
        return Set(snapshot.documents.map { $0.documentID })
    }

    // MARK: - Chat Messages

    func sendMessage(chatId: String, senderId: String, text: String) async throws {
        let messagesRef = db.collection("chats").document(chatId).collection("messages")
        try await messagesRef.addDocument(data: [
            "senderId": senderId,
            "text": text,
            "createdAt": FieldValue.serverTimestamp()
        ])

        try await db.collection("chats").document(chatId).updateData([
            "lastMessage": text,
            "lastMessageAt": FieldValue.serverTimestamp(),
            "lastSenderId": senderId
        ])
        AppLog.d("Firestore", "message sent chatId=\(chatId)")
    }

    func messagesListener(chatId: String, onChange: @escaping ([[String: Any]]) -> Void) -> ListenerRegistration {
        return db.collection("chats").document(chatId).collection("messages")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let messages = docs.map { $0.data().merging(["id": $0.documentID]) { _, new in new } }
                onChange(messages)
            }
    }

    // MARK: - Sessions

    private func parseSession(doc: DocumentSnapshot) -> Session? {
        guard let data = doc.data() else { return nil }
        let createdTs = data["createdAt"] as? Timestamp
        let updatedTs = data["updatedAt"] as? Timestamp
        let startTs = data["startAt"] as? Timestamp
        return Session(
            id: doc.documentID,
            chatId: data["chatId"] as? String ?? "",
            users: data["users"] as? [String] ?? [],
            createdBy: data["createdBy"] as? String ?? "",
            status: data["status"] as? String ?? "draft",
            confirmations: data["confirmations"] as? [String: Bool] ?? [:],
            title: data["title"] as? String ?? "",
            startAt: startTs?.dateValue(),
            durationMin: data["durationMin"] as? Int ?? 0,
            callLink: data["callLink"] as? String ?? "",
            createdAt: createdTs?.dateValue(),
            updatedAt: updatedTs?.dateValue()
        )
    }

    func findActiveSession(chatId: String, myUid: String) async throws -> Session? {
        let snapshot = try await db.collection("sessions")
            .whereField("chatId", isEqualTo: chatId)
            .whereField("users", arrayContains: myUid)
            .getDocuments()

        let active: Set<String> = ["draft", "proposed", "scheduled", "active"]
        return snapshot.documents
            .compactMap { parseSession(doc: $0) }
            .filter { active.contains($0.status) }
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
            .first
    }

    func createDraftSession(chatId: String, users: [String], createdBy: String) async throws -> Session {
        let sorted = users.sorted()
        let ref = try await db.collection("sessions").addDocument(data: [
            "chatId": chatId,
            "users": sorted,
            "createdBy": createdBy,
            "status": "draft",
            "confirmations": [String: Bool](),
            "title": "",
            "durationMin": 0,
            "callLink": "",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
        AppLog.i("Firestore", "draft session id=\(ref.documentID)")
        return Session(
            id: ref.documentID, chatId: chatId, users: sorted, createdBy: createdBy,
            status: "draft", confirmations: [:], title: "", startAt: nil,
            durationMin: 0, callLink: "", createdAt: Date(), updatedAt: Date()
        )
    }

    func getSession(sessionId: String) async throws -> Session? {
        let doc = try await db.collection("sessions").document(sessionId).getDocument()
        return parseSession(doc: doc)
    }

    func proposeSession(sessionId: String, title: String, startAt: Date,
                        durationMin: Int, proposerUid: String, users: [String]) async throws {
        var confirmations: [String: Bool] = [:]
        for uid in users { confirmations[uid] = false }
        confirmations[proposerUid] = true

        let ref = db.collection("sessions").document(sessionId)
        try await ref.updateData([
            "title": title,
            "startAt": Timestamp(date: startAt),
            "durationMin": durationMin,
            "status": "proposed",
            "confirmations": confirmations,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        AppLog.i("Firestore", "session proposed id=\(sessionId)")
    }

    func confirmSession(sessionId: String, uid: String) async throws {
        let ref = db.collection("sessions").document(sessionId)
        try await ref.updateData([
            "confirmations.\(uid)": true,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        let doc = try await ref.getDocument()
        if let data = doc.data(),
           let confirmations = data["confirmations"] as? [String: Bool],
           confirmations.values.allSatisfy({ $0 }) {
            try await ref.updateData([
                "status": "scheduled",
                "updatedAt": FieldValue.serverTimestamp()
            ])
            AppLog.i("Firestore", "session scheduled id=\(sessionId)")
        }
    }

    func cancelSession(sessionId: String) async throws {
        let ref = db.collection("sessions").document(sessionId)
        try await ref.updateData([
            "status": "cancelled",
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    func updateSessionCallLink(sessionId: String, callLink: String) async throws {
        let ref = db.collection("sessions").document(sessionId)
        try await ref.updateData([
            "callLink": callLink,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    func checkMyReviewExists(sessionId: String, myUid: String) async throws -> Bool {
        let doc = try await db.collection("sessions").document(sessionId)
            .collection("reviews").document(myUid).getDocument()
        return doc.exists
    }

    func submitReview(sessionId: String, myUid: String, toUid: String, stars: Int, text: String) async throws {
        // 1. Write review
        let reviewRef = db.collection("sessions").document(sessionId)
            .collection("reviews").document(myUid)
        try await reviewRef.setData([
            "toUid": toUid,
            "stars": stars,
            "text": text,
            "createdAt": FieldValue.serverTimestamp()
        ])

        // 2. Update receiver: ratingAvg, ratingCount, points +10
        let receiverRef = db.collection("users").document(toUid)
        try await db.runTransaction { tx, errorPointer in
            let snap: DocumentSnapshot
            do {
                snap = try tx.getDocument(receiverRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            let data = snap.data() ?? [:]
            let oldCount = data["ratingCount"] as? Int ?? 0
            let oldAvg = data["ratingAvg"] as? Double ?? (data["rating"] as? Double ?? 0.0)
            let oldPoints = data["points"] as? Int ?? 0

            let newCount = oldCount + 1
            let newAvg = (oldAvg * Double(oldCount) + Double(stars)) / Double(newCount)

            tx.updateData([
                "ratingAvg": newAvg,
                "ratingCount": newCount,
                "rating": newAvg,
                "points": oldPoints + 10
            ], forDocument: receiverRef)
            return nil
        }

        // 3. Reviewer gets +5 points
        let reviewerRef = db.collection("users").document(myUid)
        try await db.runTransaction { tx, errorPointer in
            let snap: DocumentSnapshot
            do {
                snap = try tx.getDocument(reviewerRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            let oldPoints = snap.data()?["points"] as? Int ?? 0
            tx.updateData(["points": oldPoints + 5], forDocument: reviewerRef)
            return nil
        }

        // 4. Check if both reviewed → status = "rated"
        let sessionRef = db.collection("sessions").document(sessionId)
        let sessionDoc = try await sessionRef.getDocument()
        if let users = sessionDoc.data()?["users"] as? [String] {
            let otherUid = users.first { $0 != myUid } ?? ""
            let otherReview = try await sessionRef.collection("reviews").document(otherUid).getDocument()
            if otherReview.exists {
                try await sessionRef.updateData(["status": "rated"])
            }
        }

        AppLog.i("Firestore", "review submitted session=\(sessionId) stars=\(stars)")
    }

    func getChats(uid: String) async throws -> [(chatId: String, otherUid: String, lastMessage: String)] {
        let snapshot = try await db.collection("chats")
            .whereField("users", arrayContains: uid)
            .getDocuments()

        let result: [(chatId: String, otherUid: String, lastMessage: String)] = snapshot.documents.compactMap { doc in
            guard let users = doc.data()["users"] as? [String] else { return nil }
            let otherUid = users.first { $0 != uid } ?? ""
            let lastMessage = doc.data()["lastMessage"] as? String ?? ""
            return (chatId: doc.documentID, otherUid: otherUid, lastMessage: lastMessage)
        }
        AppLog.d("Firestore", "chats loaded count=\(result.count)")
        return result
    }
}
