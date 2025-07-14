#!/bin/bash

# Проверяем, передан ли аргумент (путь к каталогу)
if [ -z "$1" ]; then
    echo "Использование: $0 <директория> [выходной_файл]"
    echo "Пример: $0 . tree.txt"
    exit 1
fi

# Устанавливаем целевую директорию
TARGET_DIR="$1"

# Устанавливаем выходной файл (по умолчанию tree.txt)
OUTPUT_FILE="${2:-tree.txt}"

# Проверяем существование директории
if [ ! -d "$TARGET_DIR" ]; then
    echo "Ошибка: директория '$TARGET_DIR' не существует"
    exit 1
fi

# Функция для построения дерева
build_tree() {
    local dir="$1"
    local indent="$2"
    
    # Получаем содержимое директории, отсортированное по имени
    local entries=()
    while IFS= read -r entry; do
        entries+=("$entry")
    done < <(ls -A "$dir")
    
    local count=${#entries[@]}
    local i=0
    
    for entry in "${entries[@]}"; do
        i=$((i+1))
        local path="$dir/$entry"
        
        # Определяем префикс для отступов
        if [ $i -eq $count ]; then
            echo "${indent}└── $entry"
            [ -d "$path" ] && build_tree "$path" "${indent}    "
        else
            echo "${indent}├── $entry"
            [ -d "$path" ] && build_tree "$path" "${indent}│   "
        fi
    done
}

# Записываем дерево в файл
echo "Дерево каталогов для: $TARGET_DIR" > "$OUTPUT_FILE"
echo "Генерируется: $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
build_tree "$TARGET_DIR" "" >> "$OUTPUT_FILE"

echo "Дерево каталогов сохранено в: $OUTPUT_FILE"