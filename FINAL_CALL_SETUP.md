# Audio Call Setup

## Текущее состояние
- Firestore сигналинг: РАБОТАЕТ (offer/answer/candidates/status)
- UI звонка: РАБОТАЕТ (исходящий + входящий)
- Реальное аудио: ТРЕБУЕТ GoogleWebRTC

## Как добавить GoogleWebRTC

1. Открыть `Llinks.xcodeproj` в Xcode
2. File → Add Package Dependencies
3. URL: `https://github.com/nicemixture/webrtc-ios` (или `https://github.com/nicemixture/WebRTC`)
4. Version: Latest
5. Add product `WebRTC` to target `Llinks`
6. В `CallManager.swift` раскомментировать WebRTC код (помечен `// TODO: WebRTC`)

## Firestore структура

```
chats/{chatId}/calls/{callId}
  ├── fromUid: String
  ├── toUid: String
  ├── status: "ringing" | "connecting" | "connected" | "ended"
  ├── offer: String (SDP)
  ├── answer: String (SDP)
  ├── createdAt: Timestamp
  ├── offerCandidates/{id}: { candidate, sdpMLineIndex, sdpMid }
  └── answerCandidates/{id}: { candidate, sdpMLineIndex, sdpMid }
```

## Тестирование (2 аккаунта)

1. Устройство A: войти аккаунт 1, открыть чат с матчем
2. Устройство B: войти аккаунт 2, открыть тот же чат
3. A: нажать 📞 → экран "Вызов..."
4. B: автоматически появится "Входящий звонок" → нажать "Принять"
5. Оба видят "На связи" + таймер
6. Любой нажимает "Сбросить" → оба возвращаются в чат

## Логи (Console)
- `CALL offer created: <callId>`
- `CALL answer set`
- `CALL connected`
- `CALL ended`

## Файлы
- `Llinks/Calls/CallSignaling.swift` — Firestore сигналинг
- `Llinks/Calls/CallManager.swift` — оркестратор
- `Llinks/Calls/CallView.swift` — UI
- `Llinks/Views/Matches/MatchChatView.swift` — кнопка + incoming listener
