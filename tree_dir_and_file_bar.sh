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

# Функция для отображения прогресс-бара
show_progress() {
    local current="$1"
    local total="$2"
    local width=40
    
    local percentage=$((current * 100 / total))
    if [ $percentage -gt 100 ]; then
        percentage=100
    fi
    
    local completed=$((current * width / total))
    if [ $completed -gt $width ]; then
        completed=$width
    fi
    
    local remaining=$((width - completed))
    
    printf "\r\033[K["
    printf "%*s" $completed | tr ' ' '='
    printf "%*s" $remaining | tr ' ' ' '
    printf "] %d%% (%d/%d)" $percentage $current $total
}

# Универсальная функция для подсчета элементов (используется для подсчета и построения)
count_and_build() {
    local dir="$1"
    local indent="$2"
    local current_count_ref="$3"
    local depth="$4"
    local mode="$5"  # "count" или "build"
    
    # Используем косвенное обращение к переменной
    eval "local current_count=\$$current_count_ref"
    
    # Проверяем глубину рекурсии
    if [ $depth -ge $MAX_DEPTH ]; then
        if [ "$mode" = "build" ]; then
            echo "${indent}└── [глубина ограничена: $MAX_DEPTH уровней]" >> "$OUTPUT_FILE"
        fi
        return
    fi
    
    # Получаем содержимое директории с обработкой ошибок
    local entries=()
    local ls_output
    ls_output=$(ls -A "$dir" 2>&1)
    local ls_exit_code=$?
    
    if [ $ls_exit_code -ne 0 ]; then
        if [ "$mode" = "build" ]; then
            echo "${indent}└── [ошибка доступа: ${ls_output//$dir\//}]" >> "$OUTPUT_FILE"
        fi
        return
    fi
    
    while IFS= read -r entry; do
        entries+=("$entry")
    done <<< "$ls_output"
    
    local count=${#entries[@]}
    local i=0
    
    for entry in "${entries[@]}"; do
        i=$((i+1))
        local path="$dir/$entry"
        
        # Увеличиваем счетчик для КАЖДОГО элемента
        current_count=$((current_count + 1))
        eval "$current_count_ref=$current_count"
        
        if [ "$mode" = "build" ]; then
            show_progress $current_count $TOTAL_ITEMS
            
            # Определяем префикс для отступов
            if [ $i -eq $count ]; then
                echo "${indent}└── $entry" >> "$OUTPUT_FILE"
                if [ -d "$path" ]; then
                    count_and_build "$path" "${indent}    " "$current_count_ref" $((depth + 1)) "build"
                fi
            else
                echo "${indent}├── $entry" >> "$OUTPUT_FILE"
                if [ -d "$path" ]; then
                    count_and_build "$path" "${indent}│   " "$current_count_ref" $((depth + 1)) "build"
                fi
            fi
        else
            # Режим подсчета - просто рекурсивно обходим
            if [ -d "$path" ]; then
                count_and_build "$path" "" "$current_count_ref" $((depth + 1)) "count"
            fi
        fi
    done
}

echo "Подсчет элементов в директории (максимальная глубина: $MAX_DEPTH)..."
CURRENT_COUNT=0
count_and_build "$TARGET_DIR" "" "CURRENT_COUNT" 0 "count"
TOTAL_ITEMS=$CURRENT_COUNT
echo "Найдено элементов: $TOTAL_ITEMS"
echo ""

# Создаем выходной файл
echo "Дерево каталогов для: $TARGET_DIR" > "$OUTPUT_FILE"
echo "Генерируется: $(date)" >> "$OUTPUT_FILE"
echo "Максимальная глубина: $MAX_DEPTH уровней" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "Генерация дерева каталогов (максимальная глубина: $MAX_DEPTH)..."

# Используем глобальную переменную для счетчика
CURRENT_COUNT=0
count_and_build "$TARGET_DIR" "" "CURRENT_COUNT" 0 "build"

# Завершаем прогресс-бар
printf "\n\n"

echo "Дерево каталогов сохранено в: $OUTPUT_FILE"
