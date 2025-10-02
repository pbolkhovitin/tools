#!/bin/bash

# Проверяем, передан ли аргумент (путь к каталогу)
if [ -z "$1" ]; then
    echo "Использование: $0 <директория> [выходной_файл] [максимальная_глубина]"
    echo "Пример: $0 . tree.txt"
    echo "Пример с глубиной: $0 . tree.txt 10"
    exit 1
fi

# Устанавливаем целевую директорию
TARGET_DIR="$1"

# Устанавливаем выходной файл (по умолчанию tree.txt)
OUTPUT_FILE="${2:-tree.txt}"

# Устанавливаем максимальную глубину рекурсии (по умолчанию 20)
MAX_DEPTH="${3:-20}"

# Проверяем существование директории
if [ ! -d "$TARGET_DIR" ]; then
    echo "Ошибка: директория '$TARGET_DIR' не существует"
    exit 1
fi

# Проверяем, что максимальная глубина - положительное число
if ! [[ "$MAX_DEPTH" =~ ^[0-9]+$ ]] || [ "$MAX_DEPTH" -lt 1 ]; then
    echo "Ошибка: максимальная глубина должна быть положительным числом"
    echo "Получено: '$MAX_DEPTH'"
    exit 1
fi

# Функция для построения дерева
build_tree() {
    local dir="$1"
    local indent="$2"
    local depth="$3"
    
    # Проверяем глубину рекурсии
    if [ $depth -ge $MAX_DEPTH ]; then
        echo "${indent}└── [глубина ограничена: $MAX_DEPTH уровней]"
        return
    fi
    
    # Получаем содержимое директории, отсортированное по имени
    local entries=()
    while IFS= read -r entry; do
        entries+=("$entry")
    done < <(ls -A "$dir" 2>/dev/null)
    
    local count=${#entries[@]}
    local i=0
    
    for entry in "${entries[@]}"; do
        i=$((i+1))
        local path="$dir/$entry"
        
        # Определяем префикс для отступов
        if [ $i -eq $count ]; then
            echo "${indent}└── $entry"
            [ -d "$path" ] && build_tree "$path" "${indent}    " $((depth + 1))
        else
            echo "${indent}├── $entry"
            [ -d "$path" ] && build_tree "$path" "${indent}│   " $((depth + 1))
        fi
    done
}

# Записываем дерево в файл
echo "Дерево каталогов для: $TARGET_DIR" > "$OUTPUT_FILE"
echo "Генерируется: $(date)" >> "$OUTPUT_FILE"
echo "Максимальная глубина: $MAX_DEPTH уровней" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "Генерация дерева каталогов..."
echo "Целевая директория: $TARGET_DIR"
echo "Выходной файл: $OUTPUT_FILE"
echo "Максимальная глубина: $MAX_DEPTH уровней"
echo ""

build_tree "$TARGET_DIR" "" 0 >> "$OUTPUT_FILE"

echo "Дерево каталогов сохранено в: $OUTPUT_FILE"
echo "Максимальная глубина: $MAX_DEPTH уровней"
