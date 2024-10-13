override MAKEFLAGS += -rR

ANSI_GREEN := \033[0;32m
ANSI_RESET := \033[0m

override KERNEL := kernel.elf

define DEFAULT_VAR =
    ifeq ($(origin $1),default)
        override $(1) := $(2)
    endif
    ifeq ($(origin $1),undefined)
        override $(1) := $(2)
    endif
endef

# Assumes default location using my amazing toolchain.sh
override DEFAULT_CC := ~/toolchain/x86_64-elf/bin/x86_64-elf-gcc
$(eval $(call DEFAULT_VAR,CC,$(DEFAULT_CC)))

override DEFAULT_LD := ~/toolchain/x86_64-elf/bin/x86_64-elf-ld
$(eval $(call DEFAULT_VAR,LD,$(DEFAULT_LD)))

override DEFAULT_AS := ~/toolchain/x86_64-elf/bin/x86_64-elf-as
$(eval $(call DEFAULT_VAR,AS,$(DEFAULT_AS)))

override DEFAULT_CFLAGS := -g -O2 -pipe
$(eval $(call DEFAULT_VAR,CFLAGS,$(DEFAULT_CFLAGS)))

override DEFAULT_CPPFLAGS :=
$(eval $(call DEFAULT_VAR,CPPFLAGS,$(DEFAULT_CPPFLAGS)))

override DEFAULT_CXXFLAGS := -g -O2 -pipe -std=c++17
$(eval $(call DEFAULT_VAR,CXXFLAGS,$(DEFAULT_CXXFLAGS)))

override DEFAULT_CXX := ~/toolchain/x86_64-elf/bin/x86_64-elf-g++
$(eval $(call DEFAULT_VAR,CXX,$(DEFAULT_CXX)))

override DEFAULT_NASMFLAGS := -F dwarf -g
$(eval $(call DEFAULT_VAR,NASMFLAGS,$(DEFAULT_NASMFLAGS)))

override DEFAULT_LDFLAGS :=
$(eval $(call DEFAULT_VAR,LDFLAGS,$(DEFAULT_LDFLAGS)))

override CFLAGS += \
    -Wall \
    -Wextra \
    -std=gnu11 \
    -ffreestanding \
    -fno-stack-protector \
    -fno-omit-frame-pointer \
    -fno-stack-check \
    -fno-lto \
    -fPIE \
    -m64 \
    -march=x86-64 \
    -mno-80387 \
    -mno-mmx \
    -mno-sse \
    -mno-sse2 \
    -mno-red-zone \
	-I . \
    -I ./inc \
    -I ./cfg \
    -Wno-trigraphs

override CPPFLAGS := \
    -I . \
    -I ./cfg \
    -I ./cfg \
    -fno-omit-frame-pointer \
    -Wno-packed-bitfield-compat \
    -I ./inc \
    $(CPPFLAGS) \
    -ffreestanding \
    -O2 \
    -Wall \
    -Wextra \
    -fPIE \
    -fno-exceptions \
    -fno-use-cxa-atexit -fno-rtti \
    -fno-rtti

override LDFLAGS += \
        -T cfg/linker.ld \
        -ffreestanding \
        -O2 \
        -nostdlib \
        -static \
        -no-pie \
        -lgcc

override NASMFLAGS += \
    -Wall \
    -f elf64

override CFILES := $(shell find -L * -type f -name '*.c')
override ASFILES := $(shell find -L * -type f -name '*.S')
override NASMFILES := $(shell find -L * -type f -name '*.asm')
override ASFILES := $(shell find -L * -type f -name '*.S')
override HEADER_DEPS := $(addprefix ../build/obj/,$(CFILES:.c=.c.d) $(ASFILES:.S=.S.d))
override CXXFILES := $(shell find -L * -type f -name '*.cpp')
override OBJ := $(addprefix ../build/obj/,$(CFILES:.c=.c.o) $(CXXFILES:.cpp=.cpp.o) $(ASFILES:.S=.S.o) $(NASMFILES:.asm=.asm.o))

.PHONY: all
all: ../build/$(KERNEL)

../build/$(KERNEL): GNUmakefile cfg/linker.ld $(OBJ) $(LIBC_OBJS)
	mkdir -p "$$(dirname $@)"
	@echo "$(ANSI_GREEN)LINKING$(ANSI_RESET) $@"
	@$(CC) $(OBJ) $(LIBC_OBJS) $(LDFLAGS) -o $@

-include $(HEADER_DEPS)

../build/obj/%.c.o: %.c GNUmakefile
	mkdir -p "$$(dirname $@)"
	@echo "$(ANSI_GREEN)COMPILING$(ANSI_RESET) $<"
	@$(CC) $(CFLAGS) -c $< -o $@

../build/obj/%.cpp.o: %.cpp GNUmakefile
	mkdir -p "$$(dirname $@)"
	@echo "$(ANSI_GREEN)COMPILING$(ANSI_RESET) $<"
	@$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c $< -o $@

../build/obj/%.S.o: %.S GNUmakefile
	mkdir -p "$$(dirname $@)"
	@echo "$(ANSI_GREEN)ASSEMBLING$(ANSI_RESET) $<"
	@$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

../build/obj/%.asm.o: %.asm GNUmakefile
	mkdir -p "$$(dirname $@)"
	@echo "$(ANSI_GREEN)ASSEMBLING$(ANSI_RESET) $<"
	@nasm $(NASMFLAGS) $< -o $@

.PHONY: clean
clean:
	rm -rf ../build/obj ../build/$(KERNEL)

.PHONY: distclean
distclean: clean
	rm -f limine.h
