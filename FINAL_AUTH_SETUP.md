# Финальная настройка Google Sign-In для Llinks

## ✅ Что уже сделано:

### 1. Создана полная инфраструктура авторизации

**Модели:**
- `AuthUser.swift` - модель авторизованного пользователя

**Services:**
- `AuthService.swift` - сервис авторизации с:
  - Google Sign-In логикой
  - Auth state listener (Firebase)
  - Обработкой ошибок
  - Методами signInWithGoogle() и signOut()

**Views:**
- `LoginView.swift` - красивый экран входа с кнопкой Google Sign-In
- Обработка ошибок через Alert
- Индикатор загрузки

**Интеграция:**
- `AppState.swift` - обновлен для поддержки авторизации
- `LlinksApp.swift` - добавлен AuthService и логика навигации:
  - Не авторизован → LoginView
  - Авторизован → основной flow (Launch/Onboarding/Main)
- `LaunchView.swift` - обновлен для работы с AuthService
- AppDelegate с обработкой URL callback для Google Sign-In

### 2. Firebase настроен
✅ FirebaseApp.configure() вызывается при старте
✅ GoogleService-Info.plist в проекте
✅ FirebaseAuth и FirebaseCore импортированы

## ⚠️ ОСТАЛОСЬ СДЕЛАТЬ ВРУЧНУЮ:

### Шаг 1: Добавить GoogleSignIn пакет через Xcode

**ВАЖНО:** GoogleSignIn пакет не может быть добавлен через command line, его нужно добавить через Xcode UI.

1. Откройте проект в Xcode:
   ```bash
   cd /Users/rodion/Desktop/Llinks
   open Llinks.xcodeproj
   ```

2. В Xcode:
   - **File → Add Package Dependencies...**
   - В поисковой строке введите:
     ```
     https://github.com/google/GoogleSignIn-iOS
     ```
   - Выберите версию: **Up to Next Major Version** → **8.0.0**
   - Нажмите **Add Package**

3. В списке продуктов выберите:
   - ✅ **GoogleSignIn**
   - Нажмите **Add Package**

4. Проверьте что пакет появился:
   - В Project Navigator слева должна появиться папка **Package Dependencies**
   - В ней должен быть **GoogleSignIn-iOS**

### Шаг 2: Проверить URL Types (должно быть уже настроено)

В Xcode:
1. Выберите проект **Llinks** в Navigator
2. Выберите Target **Llinks**
3. Вкладка **Info**
4. Раскройте **URL Types**
5. Проверьте наличие URL Scheme

**Должен быть:** REVERSED_CLIENT_ID из GoogleService-Info.plist
Формат: `com.googleusercontent.apps.665865727155-XXXXXXXXXXXXXXXXXXXXXXXXXXXX`

Если его нет:
1. Нажмите `+`
2. **Identifier**: `com.googleusercontent.apps.reversedclientid`
3. **URL Schemes**: скопируйте значение `REVERSED_CLIENT_ID` из GoogleService-Info.plist (без "REVERSED_CLIENT_ID" - только значение)

### Шаг 3: Проверить GoogleService-Info.plist Target Membership

1. Выберите файл **GoogleService-Info.plist** в Navigator
2. В File Inspector справа проверьте **Target Membership**
3. Убедитесь что галочка стоит напротив **Llinks**

### Шаг 4: Собрать проект

В Xcode нажмите **Cmd + B** или:
```bash
xcodebuild -project Llinks.xcodeproj -scheme Llinks -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Должно быть: **BUILD SUCCEEDED**

## Тестирование на симуляторе/устройстве

### На симуляторе:
1. Запустите приложение: **Cmd + R**
2. При первом запуске появится **LoginView** с кнопкой "Войти через Google"
3. Нажмите кнопку - откроется Safari с страницей входа Google
4. Введите credentials тестового Google аккаунта
5. После успешного входа вернётесь в приложение
6. Должен показаться OnboardingView (если первый вход) или MainTabView

### На реальном устройстве:
1. Подключите iPhone
2. Выберите устройство в Xcode
3. Запустите приложение
4. Google Sign-In будет работать через установленное приложение Google или Safari

## Проверка что всё работает:

### В консоли Xcode должны появиться логи:
```
Firebase configured successfully
User authenticated: your-email@gmail.com
```

### Навигация:
- **Не авторизован** → LoginView
- **Авторизован, первый вход** → OnboardingView
- **Авторизован, онбординг пройден** → MainTabView

### Кнопка Выход:
В ProfileView есть возможность сброса онбординга для тестирования потоков навигации.

## Troubleshooting

### Ошибка "Client ID не найден"
- Проверьте что GoogleService-Info.plist добавлен в Target Membership
- Убедитесь что файл содержит CLIENT_ID

### Ошибка "Unable to find module dependency: 'GoogleSignIn'"
- Пакет GoogleSignIn не добавлен - выполните Шаг 1

### Ошибка callback URL
- Проверьте URL Types (Шаг 2)
- REVERSED_CLIENT_ID должен совпадать с значением в GoogleService-Info.plist

### Приложение открывает Safari но не возвращается
- Проверьте обработку .onOpenURL в LlinksApp.swift (уже настроено)
- Проверьте URL Scheme configuration

## Структура файлов

```
Llinks/
├── Models/
│   └── AuthUser.swift                           ✅ создан
├── Services/
│   └── AuthService.swift                        ✅ создан
├── ViewModels/Auth/                             ✅ папка создана
├── Views/Auth/
│   └── LoginView.swift                          ✅ создан
├── App/
│   ├── AppState.swift                           ✅ обновлен
│   └── AppFlow.swift
├── LlinksApp.swift                              ✅ обновлен
└── GoogleService-Info.plist                     ✅ есть

Llinks.xcodeproj/project.pbxproj                 ✅ подготовлен для GoogleSignIn
```

## Что делает каждый компонент:

**AuthService:**
- Слушает изменения auth state через Firebase
- Обновляет `@Published var isAuthenticated`
- Выполняет Google Sign-In flow
- Обрабатывает ошибки

**AppState:**
- Управляет навигацией приложения
- Связан с AuthService
- Определяет текущий flow (launch/onboarding/main)

**LlinksApp:**
- Инициализирует Firebase и AuthService
- Определяет root view на основе isAuthenticated
- Обрабатывает URL callbacks

**LoginView:**
- Красивый UI для входа
- Кнопка Google Sign-In
- Alert для ошибок

После выполнения Шага 1 (добавления GoogleSignIn пакета) проект будет полностью готов к использованию!
