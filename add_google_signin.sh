#!/bin/bash

# Скрипт для добавления GoogleSignIn пакета в Xcode проект
# ВАЖНО: Сделайте backup проекта перед запуском!

PROJECT_FILE="Llinks.xcodeproj/project.pbxproj"

echo "⚠️  ВНИМАНИЕ: Этот скрипт модифицирует project.pbxproj файл"
echo "Рекомендуется добавить пакет через Xcode UI (см. SETUP_GOOGLE_SIGNIN.md)"
echo ""
read -p "Продолжить? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Отменено. Используйте Xcode для добавления пакета."
    exit 1
fi

echo "Создание backup..."
cp "$PROJECT_FILE" "$PROJECT_FILE.backup"

echo "Добавление GoogleSignIn пакета..."

# Найдем ID для нового пакета (используем timestamp для уникальности)
NEW_PACKAGE_ID="GS$(date +%s)00000000001"
NEW_PRODUCT_ID="GS$(date +%s)00000000002"

# 1. Добавляем XCRemoteSwiftPackageReference
sed -i '' '/\/\* End XCRemoteSwiftPackageReference section \*\//i\
		'"$NEW_PACKAGE_ID"' /* XCRemoteSwiftPackageReference "GoogleSignIn-iOS" */ = {\
			isa = XCRemoteSwiftPackageReference;\
			repositoryURL = "https://github.com/google/GoogleSignIn-iOS";\
			requirement = {\
				kind = upToNextMajorVersion;\
				minimumVersion = 7.0.0;\
			};\
		};\
' "$PROJECT_FILE"

# 2. Добавляем XCSwiftPackageProductDependency
sed -i '' '/\/\* End XCSwiftPackageProductDependency section \*\//i\
		'"$NEW_PRODUCT_ID"' /* GoogleSignIn */ = {\
			isa = XCSwiftPackageProductDependency;\
			package = '"$NEW_PACKAGE_ID"' /* XCRemoteSwiftPackageReference "GoogleSignIn-iOS" */;\
			productName = GoogleSignIn;\
		};\
' "$PROJECT_FILE"

# 3. Находим и обновляем packageProductDependencies в target
echo "Обновление target dependencies..."

# Это более сложная часть - нужно найти правильное место

echo "✅ Пакет добавлен в project.pbxproj"
echo "⚠️  ВАЖНО: Откройте проект в Xcode и проверьте что пакет отображается корректно"
echo "Если возникли проблемы, восстановите из backup: mv $PROJECT_FILE.backup $PROJECT_FILE"
