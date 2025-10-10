# Makefile Description

## Overview
This Makefile is designed for building, testing, and maintaining a C project with multiple modules (`print_module`, `documentation_module`, and BST-related tests: `bst_create`, `bst_insert`, `bst_traverse`). It is optimized for scalability, supporting large projects with minimal manual configuration. The Makefile automates source file detection, dependency management, debugging, and code quality checks.

## Key Features
- **Modular Build System**: Automatically detects `.c` files and generates object files, supporting easy addition of new modules via the `MODULES` list.
- **Debug/Release Modes**: Use `BUILD_TYPE=debug` for sanitizers (`-fsanitize=address,undefined,leak`) and debugging symbols, or `BUILD_TYPE=release` for optimized builds (`-O2`).
- **Automatic Dependencies**: Generates and includes `.d` files for header dependencies using `-MMD -MP`.
- **Testing and Validation**: Includes targets for running tests (`test`), memory leak checks with `valgrind`, and static analysis with `cppcheck`.
- **Code Formatting**: Supports `clang-format` for style checking (`format-check`) and auto-fixing (`format-fix`).
- **Gitignore Management**: Automatically updates `.gitignore` for build artifacts (`update_gitignore`) and restores it (`restore_gitignore`).
- **Tool Verification**: Ensures required tools (`gcc`/`clang`, `valgrind`, `cppcheck`, `clang-format`) are installed (`check-tools`).
- **Parallel Builds**: Optimized for parallel execution with `make -j$(nproc)`.
- **Extensive Documentation**: Comprehensive comments explain each section, variable, and target for easy maintenance.

## Usage
### Prerequisites
Ensure the following tools are installed:
- `gcc` or `clang` (compiler)
- `valgrind` (memory leak detection)
- `cppcheck` (static analysis)
- `clang-format` (code formatting, config at `../materials/linters/.clang-format`)

### Common Commands
```bash
make                    # Build all modules (Quest_1 to Quest_5)
make BUILD_TYPE=debug   # Build with debug flags and sanitizers
make -j$(nproc)         # Parallel build with max jobs
make test               # Run all tests with sanitizers
make valgrind           # Run memory leak checks on all modules
make cppcheck           # Run static analysis
make format-check       # Check code style
make format-fix         # Auto-fix code style
make clean              # Remove all build artifacts
make rebuild            # Clean and rebuild
make help               # Show detailed help
```

### Customization
- **Add New Module**: Append the module number to `MODULES` and define its objects (e.g., `OBJS_6 = new_module.o main_new.o`) in the Makefile.
- **Change Compiler**: Use `make CC=clang` to switch to `clang`.
- **Custom Paths**: Override `BUILD_DIR`, `SRC_DIR`, or `CLANG_FORMAT_SRC` (e.g., `make BUILD_DIR=./build`).

## Directory Structure
- `../build/`: Output directory for object files (`.o`) and binaries (`Quest_X`).
- `./`: Source files (`.c`, `.h`) and tests.
- `../materials/linters/.clang-format`: Code style configuration.

## Notes
- Run `make -n` for a dry-run to preview commands.
- For large projects, add new modules by extending the `MODULES` variable and defining their dependencies.
- Ensure `.clang-format` exists in the specified path or override `CLANG_FORMAT_SRC`.

This Makefile is designed for scalability and ease of use, making it suitable for both small and large C projects. For issues or contributions, please open a GitHub issue or pull request.