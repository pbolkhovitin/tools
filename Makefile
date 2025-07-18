# Compiler settings
CC = gcc
CFLAGS = -std=c11 -Wall -Werror -Wextra
SANITIZERS = -fsanitize=address -fsanitize=undefined -fsanitize=leak
DEBUG_FLAGS = -g
LDFLAGS = 

# Directories
BUILD_DIR = ../build
SRC_DIR = .
TEST_DIR = tests
GITIGNORE = ../.gitignore

# Formatting
CLANG_FORMAT_SRC := ../materials/linters/.clang-format
CLANG_FORMAT_DEST := ./.clang-format

# Targets
.PHONY: all clean clean_artifacts rebuild test valgrind cppcheck \
		format-check format-fix update_gitignore restore_gitignore \
		print_module documentation_module bst_create_test bst_insert_test bst_traverse_test help

all: update_gitignore print_module documentation_module bst_create_test bst_insert_test bst_traverse_test

# Common build directory rule
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR) && touch $(BUILD_DIR)/.gitkeep

$(BUILD_DIR)/print_module.o: print_module.c print_module.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@
	
# Quest 1: Print Module (без документации)
print_module: $(BUILD_DIR)/Quest_1

$(BUILD_DIR)/Quest_1: $(BUILD_DIR)/print_module.o $(BUILD_DIR)/main_print.o
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

$(BUILD_DIR)/main_print.o: main_module_entry_point.c print_module.h
	$(CC) $(CFLAGS) -c $< -o $@

# Quest 2: Documentation Module (полная версия)
documentation_module: $(BUILD_DIR)/Quest_2

$(BUILD_DIR)/Quest_2: $(BUILD_DIR)/print_module.o $(BUILD_DIR)/main_docs.o $(BUILD_DIR)/documentation_module.o
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

$(BUILD_DIR)/main_docs.o: main_module_entry_point.c print_module.h documentation_module.h
	$(CC) $(CFLAGS) -DDOCUMENTATION_MODULE -c $< -o $@

$(BUILD_DIR)/documentation_module.o: documentation_module.c documentation_module.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# BST Common Source
$(BUILD_DIR)/bst.o: bst.c bst.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Quest 3: BST Create Node
bst_create_test: $(BUILD_DIR)/Quest_3

$(BUILD_DIR)/Quest_3: $(BUILD_DIR)/bst_create_test.o $(BUILD_DIR)/bst.o | $(BUILD_DIR)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

$(BUILD_DIR)/bst_create_test.o: bst_create_test.c bst.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Quest 4: BST Insert
bst_insert_test: $(BUILD_DIR)/Quest_4

$(BUILD_DIR)/Quest_4: $(BUILD_DIR)/bst_insert_test.o $(BUILD_DIR)/bst.o | $(BUILD_DIR)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

$(BUILD_DIR)/bst_insert_test.o: bst_insert_test.c bst.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Quest 5: BST Traverse
bst_traverse_test: $(BUILD_DIR)/Quest_5

$(BUILD_DIR)/Quest_5: $(BUILD_DIR)/bst_traverse_test.o $(BUILD_DIR)/bst.o | $(BUILD_DIR)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

$(BUILD_DIR)/bst_traverse_test.o: bst_traverse_test.c bst.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Gitignore management
update_gitignore:
	@if [ ! -f $(GITIGNORE) ]; then touch $(GITIGNORE); fi
	@if ! grep -q "^# Build artifacts" $(GITIGNORE); then \
		if [ -s $(GITIGNORE) ] && [ "$(tail -c 1 $(GITIGNORE))" != "" ]; then \
			echo "" >> $(GITIGNORE); \
		fi; \
		echo "# Build artifacts" >> $(GITIGNORE); \
		echo "/build/*" >> $(GITIGNORE); \
		echo "!/build/.gitkeep" >> $(GITIGNORE); \
		echo "Quest_*" >> $(GITIGNORE); \
		echo "*.o" >> $(GITIGNORE); \
	fi

restore_gitignore:
	@if [ -f "$(GITIGNORE)" ]; then \
		if grep -q "^# Build artifacts" $(GITIGNORE); then \
			sed -i.bak '/^# Build artifacts/,/^*.o/d' $(GITIGNORE); \
			# Удаляем возможную пустую строку перед секцией \
			sed -i.bak -e :a -e '/^\n*$/{$d;N;ba' -e '}' $(GITIGNORE); \
			rm -f $(GITIGNORE).bak; \
		fi; \
	fi

# Clean targets
clean: clean_artifacts restore_gitignore
		@rm -f $(GITIGNORE).bak

clean_artifacts:
	@if [ -d "$(BUILD_DIR)" ]; then \
		find $(BUILD_DIR) -maxdepth 1 -type f \( -name '*.o' -o -name 'Quest_*' \) -exec rm -f {} +; \
	fi
	@rm -f src/.clang-format

clean_print:
	rm -f $(BUILD_DIR)/print_module.o $(BUILD_DIR)/main_print.o $(BUILD_DIR)/Quest_1

clean_docs:
	rm -f $(BUILD_DIR)/documentation_module.o $(BUILD_DIR)/main_documentation.o $(BUILD_DIR)/Quest_2

clean_bst_create:
	rm -f $(BUILD_DIR)/bst.o $(BUILD_DIR)/bst_create_test.o $(BUILD_DIR)/Quest_3

clean_bst_insert:
	rm -f $(BUILD_DIR)/bst.o $(BUILD_DIR)/bst_insert_test.o $(BUILD_DIR)/Quest_4

clean_bst_traverse:
	rm -f $(BUILD_DIR)/bst.o $(BUILD_DIR)/bst_traverse_test.o $(BUILD_DIR)/Quest_5

# Test targets with sanitizers
test: test_print test_docs test_bst_create test_bst_insert test_bst_traverse

test_print: CFLAGS += $(SANITIZERS) $(DEBUG_FLAGS)
test_print: LDFLAGS += $(SANITIZERS)
test_print: print_module
	@echo "=== Testing print_module with sanitizers ==="
	$(BUILD_DIR)/Quest_1

test_docs: CFLAGS += $(SANITIZERS) $(DEBUG_FLAGS)
test_docs: LDFLAGS += $(SANITIZERS)
test_docs: documentation_module
	@echo "=== Testing documentation_module with sanitizers ==="
	$(BUILD_DIR)/Quest_2

test_bst_create: CFLAGS += $(SANITIZERS) $(DEBUG_FLAGS)
test_bst_create: LDFLAGS += $(SANITIZERS)
test_bst_create: bst_create_test
	@echo "=== Testing bst_create with sanitizers ==="
	$(BUILD_DIR)/Quest_3

test_bst_insert: CFLAGS += $(SANITIZERS) $(DEBUG_FLAGS)
test_bst_insert: LDFLAGS += $(SANITIZERS)
test_bst_insert: bst_insert_test
	@echo "=== Testing bst_insert with sanitizers ==="
	$(BUILD_DIR)/Quest_4

test_bst_traverse: CFLAGS += $(SANITIZERS) $(DEBUG_FLAGS)
test_bst_traverse: LDFLAGS += $(SANITIZERS)
test_bst_traverse: bst_traverse_test
	@echo "=== Testing bst_traverse with sanitizers ==="
	$(BUILD_DIR)/Quest_5

# Valgrind checks
valgrind: all
	@echo "=== Running valgrind on print_module ==="
	valgrind --leak-check=full --track-origins=yes $(BUILD_DIR)/Quest_1
	@echo "=== Running valgrind on documentation_module ==="
	valgrind --leak-check=full --track-origins=yes $(BUILD_DIR)/Quest_2
	@echo "=== Running valgrind on bst_create ==="
	valgrind --leak-check=full --track-origins=yes $(BUILD_DIR)/Quest_3
	@echo "=== Running valgrind on bst_insert ==="
	valgrind --leak-check=full --track-origins=yes $(BUILD_DIR)/Quest_4
	@echo "=== Running valgrind on bst_traverse ==="
	valgrind --leak-check=full --track-origins=yes $(BUILD_DIR)/Quest_5

# Static analysis
cppcheck:
	cppcheck --enable=all --suppress=missingIncludeSystem $(SRC_DIR)

# Formatting
format-check:
	@echo "Copying .clang-format to src/..."
	@if [ -f "$(CLANG_FORMAT_SRC)" ]; then \
		cp "$(CLANG_FORMAT_SRC)" "$(CLANG_FORMAT_DEST)"; \
		echo "Checking code style with clang-format..."; \
		find . -name '*.c' -o -name '*.h' | xargs clang-format --dry-run --Werror; \
		rm -f "$(CLANG_FORMAT_DEST)"; \
		echo "Formatting check complete. Run 'make format-fix' to automatically fix issues. Remove .clang-format"; \
	else \
		echo "Error: .clang-format not found in $(CLANG_FORMAT_SRC)"; \
		echo "Please ensure the linters are installed in materials/linters/"; \
		exit 1; \
	fi

format-fix:
	@echo "Copying .clang-format to src/..."
	@if [ -f "$(CLANG_FORMAT_SRC)" ]; then \
		cp "$(CLANG_FORMAT_SRC)" "$(CLANG_FORMAT_DEST)"; \
		echo "Fixing code style with clang-format..."; \
		find . -name '*.c' -o -name '*.h' | xargs clang-format -i; \
		rm -f "$(CLANG_FORMAT_DEST)"; \
		echo "Formatting fixed."; \
	else \
		echo "Error: .clang-format not found in $(CLANG_FORMAT_SRC)"; \
		echo "Please ensure the linters are installed in materials/linters/"; \
		exit 1; \
	fi

# Rebuild targets
rebuild: clean all

rebuild_print: clean_print print_module
rebuild_docs: clean_docs documentation_module
rebuild_bst_create: clean_bst_create bst_create_test
rebuild_bst_insert: clean_bst_insert bst_insert_test
rebuild_bst_traverse: clean_bst_traverse bst_traverse_test

# Help target
.PHONY: help
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@echo "  all                      Build all targets (default)"
	@echo "  print_module             Build print module (Quest_1)"
	@echo "  documentation_module     Build documentation module (Quest_2)"
	@echo "  bst_create_test          Build BST create node test (Quest_3)"
	@echo "  bst_insert_test          Build BST insert test (Quest_4)"
	@echo "  bst_traverse_test        Build BST traverse test (Quest_5)"
	@echo "  test                     Run all tests with sanitizers"
	@echo "  test_print               Test print module with sanitizers"
	@echo "  test_docs                Test documentation module with sanitizers"
	@echo "  test_bst_create          Test BST create with sanitizers"
	@echo "  test_bst_insert          Test BST insert with sanitizers"
	@echo "  test_bst_traverse        Test BST traverse with sanitizers"
	@echo "  valgrind                 Run all targets under valgrind"
	@echo "  cppcheck                 Run static analysis with cppcheck"
	@echo "  format-check             Check code style (copies .clang-format to src/ temporarily)"
	@echo "  format-fix               Fix code style (copies .clang-format to src/ temporarily)"
	@echo "  clean                    Remove all build artifacts"
	@echo "  clean_print              Clean print module artifacts"
	@echo "  clean_docs               Clean documentation module artifacts"
	@echo "  clean_bst_create         Clean BST create test artifacts"
	@echo "  clean_bst_insert         Clean BST insert test artifacts"
	@echo "  clean_bst_traverse       Clean BST traverse test artifacts"
	@echo "  rebuild                  Clean and rebuild all"
	@echo "  rebuild_print            Clean and rebuild print module"
	@echo "  rebuild_docs             Clean and rebuild documentation module"
	@echo "  rebuild_bst_create       Clean and rebuild BST create test"
	@echo "  rebuild_bst_insert       Clean and rebuild BST insert test"
	@echo "  rebuild_bst_traverse     Clean and rebuild BST traverse test"
	@echo "  help                     Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make                     # Build everything"
	@echo "  make test                # Build and run all tests"
	@echo "  make print_module        # Build only print module"
	@echo "  make clean && make all   # Full clean rebuild"
