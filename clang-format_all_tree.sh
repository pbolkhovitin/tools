#!/bin/bash

# Проверяем, установлен ли clang-format
if ! command -v clang-format &> /dev/null; then
    echo "Ошибка: clang-format не установлен. Пожалуйста, установите его сначала."
    exit 1
fi

# Путь к файлу .clang-format в текущей директории
CLANG_FORMAT_FILE=".clang-format"
# Путь к исходному файлу .clang-format
SOURCE_CLANG_FORMAT="../materials/linters/.clang-format"

# Проверяем наличие .clang-format в текущей папке
if [ ! -f "$CLANG_FORMAT_FILE" ]; then
    echo "Файл .clang-format не найден в текущей директории."

    # Проверяем наличие исходного файла
    if [ -f "$SOURCE_CLANG_FORMAT" ]; then
        echo "Копирую .clang-format из $SOURCE_CLANG_FORMAT..."
        cp "$SOURCE_CLANG_FORMAT" "$CLANG_FORMAT_FILE"

        if [ $? -ne 0 ]; then
            echo "Ошибка при копировании .clang-format"
            exit 1
        fi
    else
        echo "Ошибка: исходный файл $SOURCE_CLANG_FORMAT не найден."
        exit 1
    fi
fi

# Ищем все файлы .c и .h в текущей директории и поддиректориях
files=$(find . -type f \( -name "*.c" -o -name "*.h" \))

if [ -z "$files" ]; then
    echo "Не найдено файлов .c или .h для проверки."
    exit 0
fi

echo "Проверка форматирования файлов с помощью clang-format..."

has_errors=0

for file in $files; do
    # Проверяем, нужно ли форматирование
    if ! clang-format --style=file --dry-run --Werror "$file" &> /dev/null; then
        echo "Ошибка форматирования в файле: $file"
        has_errors=1
    fi
done

if [ $has_errors -eq 0 ]; then
    echo "Все файлы соответствуют clang-format."
    exit 0
else
    echo ""
    echo "Найдены файлы, не соответствующие clang-format:"
    for file in $files; do
        if ! clang-format --style=file --dry-run --Werror "$file" &> /dev/null; then
            echo "  $file"
        fi
    done
    echo ""

    read -p "Хотите автоматически отформатировать эти файлы? (y/n): " choice
    case "$choice" in
        y|Y)
            echo "Форматирование файлов..."
            for file in $files; do
                if ! clang-format --style=file --dry-run --Werror "$file" &> /dev/null; then
                    clang-format --style=file -i "$file"
                    echo "Отформатирован: $file"
                fi
            done
            echo "Форматирование завершено."
            ;;
        n|N)
            echo "Форматирование отменено. Файлы остались без изменений."
            ;;
        *)
            echo "Неверный ввод. Форматирование отменено."
            ;;
    esac

    exit 1
fi
