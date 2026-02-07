//
//  CallManager.swift
//  Llinks
//

import Foundation
import Combine
import FirebaseFirestore

enum CallStatus: String {
    case idle, ringing, connecting, connected, ended
}

class CallManager: ObservableObject {
    @Published var status: CallStatus = .idle
    @Published var isMuted = false
    @Published var isSpeaker = false
    @Published var duration: Int = 0

    let chatId: String
    let myUid: String
    let otherUid: String
    let otherName: String
    let isCaller: Bool

    private var signaling: CallSignaling
    private var timer: Timer?

    init(chatId: String, myUid: String, otherUid: String, otherName: String, isCaller: Bool, callId: String? = nil) {
        self.chatId = chatId
        self.myUid = myUid
        self.otherUid = otherUid
        self.otherName = otherName
        self.isCaller = isCaller
        self.signaling = CallSignaling(chatId: chatId)
        if let cid = callId {
            self.signaling.callId = cid
        }
    }

    // MARK: - Caller

    func startCall() {
        status = .ringing
        Task {
            do {
                let cid = try await signaling.createCall(fromUid: myUid, toUid: otherUid)
                // Stub offer SDP
                try await signaling.writeOffer("stub-offer-sdp-\(cid)")
                AppLog.d("Call", "offer created: \(cid)")

                signaling.listenForStatus { [weak self] s in
                    DispatchQueue.main.async {
                        switch s {
                        case "connecting":
                            self?.status = .connecting
                        case "connected":
                            self?.status = .connected
                            self?.startTimer()
                            AppLog.d("Call", "connected")
                        case "ended":
                            self?.status = .ended
                            AppLog.d("Call", "ended")
                        default: break
                        }
                    }
                }

                signaling.listenForAnswer { [weak self] answer in
                    DispatchQueue.main.async {
                        AppLog.d("Call", "answer set")
                        self?.status = .connected
                        self?.startTimer()
                    }
                }
            } catch {
                AppLog.e("Call", "error: \(error.localizedDescription)")
                await MainActor.run { self.status = .ended }
            }
        }
    }

    // MARK: - Callee

    func acceptCall() {
        status = .connecting
        Task {
            do {
                guard let cid = signaling.callId else { return }
                // Stub answer SDP
                try await signaling.writeAnswer("stub-answer-sdp-\(cid)")
                AppLog.d("Call", "answer set")

                // Mark connected
                try await signaling.callDoc(cid).updateData(["status": "connected"])

                signaling.listenForStatus { [weak self] s in
                    DispatchQueue.main.async {
                        if s == "ended" {
                            self?.status = .ended
                            AppLog.d("Call", "ended")
                        }
                    }
                }

                await MainActor.run {
                    self.status = .connected
                    self.startTimer()
                    AppLog.d("Call", "connected")
                }
            } catch {
                AppLog.e("Call", "error: \(error.localizedDescription)")
                await MainActor.run { self.status = .ended }
            }
        }
    }

    func declineCall() {
        Task {
            try? await signaling.endCall()
        }
        status = .ended
    }

    // MARK: - End

    func endCall() {
        timer?.invalidate()
        timer = nil
        signaling.removeAllListeners()
        Task {
            try? await signaling.endCall()
        }
        status = .ended
        AppLog.d("Call", "ended")
    }

    // MARK: - Controls

    func toggleMute() {
        isMuted.toggle()
    }

    func toggleSpeaker() {
        isSpeaker.toggle()
    }

    // MARK: - Timer

    private func startTimer() {
        timer?.invalidate()
        duration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.duration += 1
            }
        }
    }

    func formattedDuration() -> String {
        let m = duration / 60
        let s = duration % 60
        return String(format: "%02d:%02d", m, s)
    }

    deinit {
        timer?.invalidate()
        signaling.removeAllListeners()
    }
}

