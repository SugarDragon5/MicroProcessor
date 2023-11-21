#
# Coremark
#


# Coremark specific definition
ITERATIONS = 1
CLOCKS_PER_SEC = 1
FLAGS_STR = ""


CORE_FILES = \
	core_list_join.c \
	core_main.c \
	core_matrix.c \
	core_state.c \
	core_util.c \

PORT_DIR = barebones
PORT_FILES = \
	$(PORT_DIR)/core_portme.c \
	$(PORT_DIR)/ee_printf.c \


SRCS = $(CORE_FILES) $(PORT_FILES)
OBJS = $(SRCS:.c=.o)


# クロスコンパイル環境の読み込み
include ../tools/Makefile.inc


XCFLAGS = \
	-g \
	-DITERATIONS=$(ITERATIONS) \
	-DCLOCKS_PER_SEC=$(CLOCKS_PER_SEC) \
	-I ./ \
	-I $(PORT_DIR) \
	-DFLAGS_STR=\"$(FLAGS_STR)\" \


all: code.hex data.hex data_byte.hex


%.o: %.c Makefile
	$(CC) $(CFLAGS) $(XCFLAGS) -o $@ -c $<


# LD の際のオブジェクトの引数の順にアドレス空間に配置されるため，
# CRTOBJ は必ず先頭に置く必要がある
# また，$(LIBGCC) $(LIBC) -T$(LDSCRIPT) $(LDFLAGS) は $(OBJS) が依存しているため
# その後ろに置く必要がある．
prog.elf: $(OBJS) $(CRTOBJ) Makefile
	$(LD) $(CRTOBJ) $(OBJS) $(LIBGCC) $(LIBC) -T$(LDSCRIPT) $(LDFLAGS) -o prog.elf

prog.bin: prog.elf
	$(OBJDUMP) -D prog.elf > prog.dump
	$(OBJECT_FILE_CONVERTER) prog.dump $@

prog.hex: prog.bin
	$(BIN_TO_HEX) prog.bin $@ $(BIN_SIZE)

code.hex data.hex: prog.hex
	$(HEX_SPLITTER) prog.hex code.hex 0x8000 0x10000 data.hex 0x10000 0x18000

data_byte.hex: data.hex
	perl -nle 'for($$i=3;$$i>=0;$$i--){ print substr($$_, $$i*2, 2); }' <data.hex >data_byte.hex

.PHONY: clean
clean:
	rm $(OBJS) code.hex data.hex data_byte.hex prog.hex prog.dump prog.bin prog.elf crt.o -f
