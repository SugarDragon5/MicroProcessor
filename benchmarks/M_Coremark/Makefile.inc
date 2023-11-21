include ../tools/mk_config.inc

#
# コンパイラの設定
#
CC = $(GCC_NATIVE)/$(GCC_PREFIX)gcc
AS = $(GCC_NATIVE)/$(GCC_PREFIX)as
LD = $(GCC_NATIVE)/$(GCC_PREFIX)ld
OBJDUMP = $(GCC_NATIVE)/$(GCC_PREFIX)objdump


#
# コンパイルオプションとリンクオプション
#
CFLAGS = \
	-g \
	-O3 \
	-fno-stack-protector \
	-fno-zero-initialized-in-bss \
	-ffreestanding \
	-fno-builtin \
	-nostdlib \
	-nodefaultlibs \
	-nostartfiles \
	-mstrict-align \
	-march=rv32im \

ASFLAGS = \
  -march=rv32im \

LDFLAGS= \
    -static \

LIBC =
LIBGCC = \
  -L$(GCC_DIR)/lib/gcc/riscv32-unknown-elf/13.2.0 \
	-lgcc \
	-lgcov \
	-L$(GCC_DIR)/riscv32-unknown-elf/lib \
	-lm



# --------
# スタートアップルーチンとリンカスクリプト
#
CRTOBJ = $(TEST_CODE_ROOT)/crt.o
CRTASM = $(TEST_TOOL_ROOT)/crt.s
LDSCRIPT = $(TEST_TOOL_ROOT)/ld.script


# スタートアップルーチンのコンパイル
$(CRTOBJ): $(CRTASM)
	$(CC) $(CFLAGS) -o $@ -c $<

# このファイルをインクルードする Makefile 内でデフォルトターゲットを
# 指定するためにデフォルトターゲットをリセット
.DEFAULT_GOAL =


# --------
# テストコード生成ツール
#

# ELF を O
OBJECT_FILE_CONVERTER = \
	python3 $(TEST_TOOL_ROOT)/ObjectFileConverter.py

# バイナリファイルを、RSDのシミュレーションで使える形式のhexに変換
BIN_TO_HEX = \
	python3 $(TEST_TOOL_ROOT)/BinaryToHex.py

HEX_SPLITTER = \
	python3 $(TEST_TOOL_ROOT)/SplitDataAndCode.py

# 生成するバイナリファイルのサイズ
BIN_SIZE = 98304
