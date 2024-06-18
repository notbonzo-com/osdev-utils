# Define the number of CPU cores
CORES := $(shell nproc)

all: builddir kernel disk run

kernel:
	@make -C kernel/

disk:
	@mkdir -p build
	@dd if=/dev/zero of=build/kernel.img bs=512 count=93750
	@mkfs.ext2 -F build/kernel.img
	@mkdir -p iso_root/boot/grub
	@cp build/kernel.elf iso_root/boot/kernel.bin
	@cp kernel/cfg/grub.cfg iso_root/boot/grub/grub.cfg
	@grub-mkrescue -o build/kernel.iso iso_root

run:
	@clear
	@qemu-system-x86_64 -cdrom build/kernel.iso -m 512M

builddir:
	@mkdir -p build

clean:
	@clear
	@make -C kernel/ clean
	@rm -rf build iso_root

reset:
	@make clean
	@clear
	@make

.PHONY: all kernel disk run clean reset builddir