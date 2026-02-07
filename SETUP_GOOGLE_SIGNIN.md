# Настройка Google Sign-In для Llinks

## Шаг 1: Добавление GoogleSignIn пакета через Xcode

1. Откройте проект в Xcode:
   ```bash
   open Llinks.xcodeproj
   ```

2. В Xcode:
   - File → Add Package Dependencies...
   - В поисковой строке введите:
     ```
     https://github.com/google/GoogleSignIn-iOS
     ```
   - Выберите версию: **Up to Next Major Version** (7.0.0 или новее)
   - Нажмите **Add Package**

3. В списке продуктов выберите:
   - ✅ **GoogleSignIn**
   - ✅ **GoogleSignInSwift** (опционально, если используете SwiftUI wrapper)

4. Нажмите **Add Package**

## Шаг 2: Проверка URL Types (уже должно быть настроено)

В Xcode:
- Выберите проект **Llinks** в Navigator
- Выберите Target **Llinks**
- Перейдите на вкладку **Info**
- Раскройте **URL Types**
- Проверьте наличие URL Scheme с **REVERSED_CLIENT_ID** из GoogleService-Info.plist

Формат: `com.googleusercontent.apps.XXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`

Если его нет, добавьте:
1. Нажмите `+` под URL Types
2. В поле **URL Schemes** вставьте значение REVERSED_CLIENT_ID из GoogleService-Info.plist

## Шаг 3: Сборка проекта

После добавления пакета соберите проект:

```bash
xcodebuild -project Llinks.xcodeproj -scheme Llinks -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Или в Xcode: `Cmd + B`

## Что уже сделано в коде:

✅ FirebaseApp.configure() в AppDelegate
✅ AuthService с Google Sign-In логикой
✅ LoginView с кнопкой входа
✅ Обработка URL callback через .onOpenURL
✅ Интеграция с AppState для навигации
✅ GoogleService-Info.plist добавлен в Target

## После успешной сборки

Приложение готово к тестированию Google Sign-In!
