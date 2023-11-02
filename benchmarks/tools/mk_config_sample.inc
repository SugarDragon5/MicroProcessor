# コピーして書き換え、mk_config.incとして保存すること。

# クロスコンパイラ環境の設定
GCC_DIR = $(HOME)/opt/riscv
GCC_PREFIX = riscv32-unknown-elf-
GCC_NATIVE = $(GCC_DIR)/bin

# プロジェクトの場所
PROJECT_ROOT = $(HOME)/exp/b3exp
TEST_CODE_ROOT = .
TEST_TOOL_ROOT = $(PROJECT_ROOT)/benchmarks/tools