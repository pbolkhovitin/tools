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

# Задержка анимации прогресс-бара (в секундах)
ANIMATION_DELAY=0.3

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
    
    # Добавляем задержку для плавности анимации
    sleep $ANIMATION_DELAY
}

# Функция для подсчета элементов (только подсчет)
count_items() {
    local dir="$1"
    local depth="$2"
    local count_ref="$3"
    
    # Проверяем глубину рекурсии
    if [ $depth -ge $MAX_DEPTH ]; then
        return
    fi
    
    # Используем косвенное обращение к переменной
    eval "local current_count=\$$count_ref"
    
    # Получаем содержимое директории с обработкой ошибок
    local entries=()
    local ls_output
    ls_output=$(ls -A "$dir" 2>&1)
    local ls_exit_code=$?
    
    if [ $ls_exit_code -ne 0 ]; then
        return
    fi
    
    while IFS= read -r entry; do
        entries+=("$entry")
    done <<< "$ls_output"
    
    # Увеличиваем счетчик для элементов текущего уровня
    current_count=$((current_count + ${#entries[@]}))
    eval "$count_ref=$current_count"
    
    # Рекурсивно подсчитываем элементы в поддиректориях
    for entry in "${entries[@]}"; do
        local path="$dir/$entry"
        if [ -d "$path" ]; then
            count_items "$path" $((depth + 1)) "$count_ref"
        fi
    done
}

# Функция для построения дерева
build_tree() {
    local dir="$1"
    local indent="$2"
    local depth="$3"
    local current_item_ref="$4"
    
    # Используем косвенное обращение к переменной
    eval "local current_item=\$$current_item_ref"
    
    # Проверяем глубину рекурсии
    if [ $depth -ge $MAX_DEPTH ]; then
        echo "${indent}└── [глубина ограничена: $MAX_DEPTH уровней]" >> "$OUTPUT_FILE"
        return
    fi
    
    # Получаем содержимое директории с обработкой ошибок
    local entries=()
    local ls_output
    ls_output=$(ls -A "$dir" 2>&1)
    local ls_exit_code=$?
    
    if [ $ls_exit_code -ne 0 ]; then
        echo "${indent}└── [ошибка доступа: ${ls_output//$dir\//}]" >> "$OUTPUT_FILE"
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
        
        # Обновляем прогресс-бар только для элементов верхнего уровня (depth == 0)
        if [ $depth -eq 0 ]; then
            current_item=$((current_item + 1))
            eval "$current_item_ref=$current_item"
            show_progress $current_item $TOP_LEVEL_ITEMS
        fi
        
        # Определяем префикс для отступов
        if [ $i -eq $count ]; then
            echo "${indent}└── $entry" >> "$OUTPUT_FILE"
            if [ -d "$path" ]; then
                build_tree "$path" "${indent}    " $((depth + 1)) "$current_item_ref"
            fi
        else
            echo "${indent}├── $entry" >> "$OUTPUT_FILE"
            if [ -d "$path" ]; then
                build_tree "$path" "${indent}│   " $((depth + 1)) "$current_item_ref"
            fi
        fi
    done
}

echo "Подсчет элементов в директории (максимальная глубина: $MAX_DEPTH)..."
TOTAL_COUNT=0
count_items "$TARGET_DIR" 0 "TOTAL_COUNT"
echo "Найдено элементов: $TOTAL_COUNT"
echo ""

# Подсчитываем элементы только верхнего уровня для прогресс-бара
echo "Подсчет элементов верхнего уровня..."
TOP_LEVEL_ITEMS=0
count_top_level_items() {
    local dir="$1"
    local ls_output
    ls_output=$(ls -A "$dir" 2>&1)
    if [ $? -eq 0 ]; then
        while IFS= read -r entry; do
            TOP_LEVEL_ITEMS=$((TOP_LEVEL_ITEMS + 1))
        done <<< "$ls_output"
    fi
}
count_top_level_items "$TARGET_DIR"
echo "Элементов верхнего уровня: $TOP_LEVEL_ITEMS"
echo "Задержка анимации: ${ANIMATION_DELAY}с"
echo ""

# Создаем выходной файл
echo "Дерево каталогов для: $TARGET_DIR" > "$OUTPUT_FILE"
echo "Генерируется: $(date)" >> "$OUTPUT_FILE"
echo "Максимальная глубина: $MAX_DEPTH уровней" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "Генерация дерева каталогов (максимальная глубина: $MAX_DEPTH)..."
echo "Прогресс отображается по элементам верхнего уровня:"

# Используем глобальную переменную для счетчика элементов верхнего уровня
CURRENT_TOP_ITEM=0
build_tree "$TARGET_DIR" "" 0 "CURRENT_TOP_ITEM"

# Завершаем прогресс-бар
printf "\n\n"

echo "Дерево каталогов сохранено в: $OUTPUT_FILE"
echo "Всего элементов обработано: $TOTAL_COUNT"
