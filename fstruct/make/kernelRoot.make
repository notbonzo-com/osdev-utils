all: builddir kernel

## This will just build your kernel, thats what you want right?

kernel:
	@make -C kernel

builddir:
	@mkdir -p build

clean:
	@clear
	@make -C kernel/
	@rm -rf build

reset:
	@make clean
	@clear
	@make

.PHONY: all kernel clean reset builddir