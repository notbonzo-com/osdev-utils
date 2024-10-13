override MAKEFLAGS += -rR

ANSI_GREEN := \033[0;32m
ANSI_RESET := \033[0m

override KERNEL := kernel.elf

CORES := $(shell nproc)

all: builddir kernel bootloader disk run

kernel:
	@make -C kernel/

bootloader:
	@make -C bootloader/

disk:
	@dd if=/dev/zero bs=1M count=0 seek=64 of=build/image.hdd
	@sgdisk build/image.hdd -n 1:2048 -t 1:ef00

	@mformat -i build/image.hdd@@1M
	@mmd -i build/image.hdd@@1M ::/EFI ::/EFI/BOOT

	@mcopy -i build/image.hdd@@1M build/kernel.elf kernel/cfg/limine.cfg limine/limine-bios.sys ::/
	@mcopy -i build/image.hdd@@1M build/BOOTX64.EFI ::/EFI/BOOT

run:
	@clear
	@qemu-system-x86_64 -drive format=raw,file=build/image.hdd \
            -bios /usr/share/edk2/ia32/OVMF.fd \
			-m 4G -enable-kvm -cpu host -smp $(CORES) \
			-debugcon stdio \
			--no-reboot --no-shutdown \
			-serial file:build/serial_output.txt \
			-monitor file:build/monitor_output.txt \
			-d int -M smm=off \
			-device pci-bridge,chassis_nr=3,id=b2 \
			-D build/qemu_log.txt -d guest_errors,cpu_reset

builddir:
	@mkdir -p build

clean:
	@clear
	@make -C kernel/ clean
	@make -C bootloader/ clean
	@rm -rf build

reset:
	@make clean
	@clear
	@make

.PHONY: all kernel bootloader disk run clean reset builddir
