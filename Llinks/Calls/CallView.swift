//
//  CallView.swift
//  Llinks
//

import SwiftUI

struct CallView: View {
    @ObservedObject var manager: CallManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Name
                Text(manager.otherName.isEmpty ? "Собеседник" : manager.otherName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // Status
                Text(statusText)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))

                // Duration
                if manager.status == .connected {
                    Text(manager.formattedDuration())
                        .font(.system(.title2, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Incoming controls
                if !manager.isCaller && manager.status == .ringing {
                    HStack(spacing: 60) {
                        CallActionButton(icon: "phone.down.fill", color: .red, label: "Отклонить") {
                            manager.declineCall()
                            dismiss()
                        }
                        CallActionButton(icon: "phone.fill", color: .green, label: "Принять") {
                            manager.acceptCall()
                        }
                    }
                } else if manager.status != .ended {
                    // Active call controls
                    HStack(spacing: 40) {
                        CallActionButton(
                            icon: manager.isMuted ? "mic.slash.fill" : "mic.fill",
                            color: manager.isMuted ? .red : .white.opacity(0.3),
                            label: "Микрофон"
                        ) {
                            manager.toggleMute()
                        }

                        CallActionButton(icon: "phone.down.fill", color: .red, label: "Сбросить") {
                            manager.endCall()
                        }

                        CallActionButton(
                            icon: manager.isSpeaker ? "speaker.wave.3.fill" : "speaker.fill",
                            color: manager.isSpeaker ? .blue : .white.opacity(0.3),
                            label: "Динамик"
                        ) {
                            manager.toggleSpeaker()
                        }
                    }
                } else {
                    // Ended
                    Text("Звонок завершён")
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 20)

                    Button("Закрыть") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(25)
                }

                Spacer().frame(height: 40)
            }
        }
        .onAppear {
            if manager.isCaller && manager.status == .idle {
                manager.startCall()
            }
        }
        .onChange(of: manager.status) { _, newStatus in
            if newStatus == .ended {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }

    private var statusText: String {
        switch manager.status {
        case .idle: return "Подготовка..."
        case .ringing: return manager.isCaller ? "Вызов..." : "Входящий звонок"
        case .connecting: return "Подключение..."
        case .connected: return "На связи"
        case .ended: return "Завершён"
        }
    }
}

struct CallActionButton: View {
    let icon: String
    let color: Color
    let label: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(color))
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

#Preview {
    CallView(manager: CallManager(
        chatId: "test", myUid: "a", otherUid: "b",
        otherName: "Тест", isCaller: true
    ))
}
