#!/bin/bash

# =============================================================================
# @file tree_dir_and_file_bar.sh
# @brief Рекурсивное построение дерева каталогов с прогресс-баром
# @version 1.0
# @usage ./tree_dir_and_file_bar.sh <директория> [выходной_файл] [максимальная_глубина]
# @example ./tree_dir_and_file_bar.sh . tree.txt
# @example ./tree_dir_and_file_bar.sh . tree.txt 10
# =============================================================================

# =============================================================================
# @section CONFIGURATION Настройки скрипта
# =============================================================================

# @var TARGET_DIR Целевая директория для сканирования
TARGET_DIR="$1"

# @var OUTPUT_FILE Выходной файл для сохранения дерева (по умолчанию: tree.txt)
OUTPUT_FILE="${2:-tree.txt}"

# @var MAX_DEPTH Максимальная глубина рекурсии (по умолчанию: 20)
MAX_DEPTH="${3:-20}"

# @var ANIMATION_DELAY Задержка анимации прогресс-бара в секундах
ANIMATION_DELAY=0.3

# =============================================================================
# @section VALIDATION Проверка входных параметров
# =============================================================================

# @function validate_parameters
# @brief Проверяет корректность переданных параметров
validate_parameters() {
    # @check Проверка обязательного параметра директории
    if [ -z "$1" ]; then
        echo "Использование: $0 <директория> [выходной_файл] [максимальная_глубина]"
        exit 1
    fi

    # @check Существование целевой директории
    if [ ! -d "$TARGET_DIR" ]; then
        echo "Ошибка: директория '$TARGET_DIR' не существует"
        exit 1
    fi

    # @check Корректность значения максимальной глубины
    if ! [[ "$MAX_DEPTH" =~ ^[0-9]+$ ]] || [ "$MAX_DEPTH" -lt 1 ]; then
        echo "Ошибка: максимальная глубина должна быть положительным числом"
        exit 1
    fi
}

# Вызов проверки параметров
validate_parameters "$@"

# =============================================================================
# @section PROGRESS_BAR Функции прогресс-бара
# =============================================================================

# @function show_progress
# @brief Отображает анимированный прогресс-бар в терминале
# @param $1 current Текущее количество обработанных элементов
# @param $2 total Общее количество элементов для обработки
# @param $3 width Ширина прогресс-бара в символах (по умолчанию: 40)
# @output Прогресс-бар в формате: [====      ] 40% (200/500)
show_progress() {
    local current="$1"
    local total="$2"
    local width="${3:-40}"
    
    local percentage=$((current * 100 / total))
    [ $percentage -gt 100 ] && percentage=100
    
    local completed=$((current * width / total))
    [ $completed -gt $width ] && completed=$width
    
    local remaining=$((width - completed))
    
    printf "\r\033[K["
    printf "%*s" $completed | tr ' ' '='
    printf "%*s" $remaining | tr ' ' ' '
    printf "] %d%% (%d/%d)" $percentage $current $total
    
    sleep $ANIMATION_DELAY
}

# =============================================================================
# @section TREE_TRAVERSAL Функции обхода дерева каталогов
# =============================================================================

# @function count_items
# @brief Рекурсивно подсчитывает общее количество элементов в дереве каталогов
# @algorithm Depth-First Search (DFS) с ограничением глубины
# @param $1 dir Путь к текущей директории
# @param $2 depth Текущая глубина рекурсии
# @param $3 count_ref Имя переменной для аккумуляции результата
# @side_effect Изменяет значение переменной, переданной по ссылке
count_items() {
    local dir="$1"
    local depth="$2"
    local count_ref="$3"
    
    # @exit_condition Достигнута максимальная глубина рекурсии
    [ $depth -ge $MAX_DEPTH ] && return
    
    eval "local current_count=\$$count_ref"
    
    local entries=()
    local ls_output
    ls_output=$(ls -A "$dir" 2>&1)
    local ls_exit_code=$?
    
    # @error_handling Пропуск директорий с ошибками доступа
    [ $ls_exit_code -ne 0 ] && return
    
    while IFS= read -r entry; do
        entries+=("$entry")
    done <<< "$ls_output"
    
    current_count=$((current_count + ${#entries[@]}))
    eval "$count_ref=$current_count"
    
    # @recursion Рекурсивный обход поддиректорий
    for entry in "${entries[@]}"; do
        local path="$dir/$entry"
        if [ -d "$path" ]; then
            count_items "$path" $((depth + 1)) "$count_ref"
        fi
    done
}

# @function count_top_level_items
# @brief Подсчитывает элементы только верхнего уровня (для прогресс-бара)
# @param $1 dir Путь к корневой директории
# @var TOP_LEVEL_ITEMS Глобальная переменная с результатом подсчета
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

# =============================================================================
# @section TREE_BUILDING Функции построения дерева
# =============================================================================

# @function build_tree
# @brief Рекурсивно строит визуальное дерево каталогов
# @visualization Использует Unicode-символы для древовидной структуры
# @param $1 dir Текущая директория
# @param $2 indent Строка отступа для визуализации
# @param $3 depth Текущая глубина рекурсии
# @param $4 current_item_ref Ссылка на счетчик элементов верхнего уровня
# @output Записывает дерево в OUTPUT_FILE
build_tree() {
    local dir="$1"
    local indent="$2"
    local depth="$3"
    local current_item_ref="$4"
    
    eval "local current_item=\$$current_item_ref"
    
    # @exit_condition Превышена максимальная глубина
    if [ $depth -ge $MAX_DEPTH ]; then
        echo "${indent}└── [глубина ограничена: $MAX_DEPTH уровней]" >> "$OUTPUT_FILE"
        return
    fi
    
    local entries=()
    local ls_output
    ls_output=$(ls -A "$dir" 2>&1)
    local ls_exit_code=$?
    
    # @error_handling Ошибка доступа к директории
    if [ $ls_exit_code -ne 0 ]; then
        echo "${indent}└── [ошибка доступа: ${ls_output//$dir\//}]" >> "$OUTPUT_FILE"
        return
    fi
    
    while IFS= read -r entry; do
        entries+=("$entry")
    done <<< "$ls_output"
    
    local count=${#entries[@]}
    local i=0
    
    # @loop Обработка каждого элемента в директории
    for entry in "${entries[@]}"; do
        i=$((i+1))
        local path="$dir/$entry"
        
        # @progress_update Обновление прогресс-бара только для корневого уровня
        if [ $depth -eq 0 ]; then
            current_item=$((current_item + 1))
            eval "$current_item_ref=$current_item"
            show_progress $current_item $TOP_LEVEL_ITEMS
        fi
        
        # @branching_logic Определение символов ветвления
        if [ $i -eq $count ]; then
            echo "${indent}└── $entry" >> "$OUTPUT_FILE"
            [ -d "$path" ] && build_tree "$path" "${indent}    " $((depth + 1)) "$current_item_ref"
        else
            echo "${indent}├── $entry" >> "$OUTPUT_FILE"
            [ -d "$path" ] && build_tree "$path" "${indent}│   " $((depth + 1)) "$current_item_ref"
        fi
    done
}

# =============================================================================
# @section MAIN Основная логика выполнения
# =============================================================================

# @step 1 Подсчет общего количества элементов
echo "Подсчет элементов в директории (максимальная глубина: $MAX_DEPTH)..."
TOTAL_COUNT=0
count_items "$TARGET_DIR" 0 "TOTAL_COUNT"
echo "Найдено элементов: $TOTAL_COUNT"
echo ""

# @step 2 Подсчет элементов верхнего уровня для прогресс-бара
echo "Подсчет элементов верхнего уровня..."
TOP_LEVEL_ITEMS=0
count_top_level_items "$TARGET_DIR"
echo "Элементов верхнего уровня: $TOP_LEVEL_ITEMS"
echo "Задержка анимации: ${ANIMATION_DELAY}с"
echo ""

# @step 3 Инициализация выходного файла
echo "Дерево каталогов для: $TARGET_DIR" > "$OUTPUT_FILE"
echo "Генерируется: $(date)" >> "$OUTPUT_FILE"
echo "Максимальная глубина: $MAX_DEPTH уровней" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# @step 4 Построение дерева с прогресс-баром
echo "Генерация дерева каталогов (максимальная глубина: $MAX_DEPTH)..."
echo "Прогресс отображается по элементам верхнего уровня:"

CURRENT_TOP_ITEM=0
build_tree "$TARGET_DIR" "" 0 "CURRENT_TOP_ITEM"

# @step 5 Завершение работы
printf "\n\n"
echo "Дерево каталогов сохранено в: $OUTPUT_FILE"
echo "Всего элементов обработано: $TOTAL_COUNT"

# =============================================================================
# @endscript
# =============================================================================
