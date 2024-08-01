CORES := $(shell nproc)

all: builddir kernel disk run

kernel:
	@make -C kernel/

disk:
	@dd if=/dev/zero bs=1M count=0 seek=64 of=build/image.hdd
	@sgdisk build/image.hdd -n 1:2048 -t 1:ef00

	@./limine/limine bios-install build/image.hdd
	@mformat -i build/image.hdd@@1M
	@mmd -i build/image.hdd@@1M ::/EFI ::/EFI/BOOT

	@mcopy -i build/image.hdd@@1M build/kernel.elf kernel/cfg/limine.cfg limine/limine-bios.sys ::/
	@mcopy -i build/image.hdd@@1M limine/BOOTX64.EFI ::/EFI/BOOT
	@mcopy -i build/image.hdd@@1M limine/BOOTIA32.EFI ::/EFI/BOOT

limine:
	@git clone https://github.com/limine-bootloader/limine.git --branch=v7.x-binary --depth=1
	@make -C limine

reinstall-limine:
	@rm -rf limine/
	@make limine

run:
	@clear
	@qemu-system-x86_64 -drive format=raw,file=build/image.hdd \
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
	@rm -rf build/image.hdd build/image.iso iso_root/
	@rm -rf build/serial_output.txt

reset:
	@make clean
	@clear
	@make

.PHONY: all kernel disk run clean reset reinstall-limine builddir