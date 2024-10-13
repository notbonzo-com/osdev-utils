#!/bin/bash

BASE_URL="https://raw.githubusercontent.com/notbonzo-com/osdev-utils/main"
LINKER_BASE_URL="$BASE_URL/fstruct/linker"
MAKE_BASE_URL="$BASE_URL/fstruct/make"

download_file() {
    local url="$1"
    local destination="$2"
    wget "$url" -O "$destination"
}

echo "------------------------------------"
echo "NotBonzo's Project Structure Creator"
echo "------------------------------------"
echo ""

echo "Select project type:"
echo "1. Limine Kernel"
echo "2. Grub Kernel"
echo "3. Kernel Only"
echo "4. Custom UEFI Bootloader"
read -p "Enter the number: " project

case $project in
    1) project="limine" ;;
    2) project="grub" ;;
    3) project="kernel" ;;
    4) project="custom" ;;
    *) echo "Invalid project type"; exit 1 ;;
esac

read -p "Do you want to use a predefined linker.ld? (y/n): " use_linker

echo "Select build system:"
echo "1. Make"
read -p "Enter the number: " build_system

mkdir -p kernel/{src,inc,cfg}

if [ "$project" == "custom" ]; then
    mkdir -p bootloader/{src,inc,cfg}
fi

if [ "$use_linker" == "y" ]; then
    if [ "$project" == "custom" ]; then
        download_file "${LINKER_BASE_URL}/limine-c++.ld" "kernel/cfg/linker.ld"
        download_file "${LINKER_BASE_URL}/boot-c++.ld" "bootloader/cfg/linker.ld"
    else
        download_file "${LINKER_BASE_URL}/${project}-c++.ld" "kernel/cfg/linker.ld"
    fi
fi

if [ "$build_system" == "1" ]; then
    case $project in
        "limine")
            download_file "${MAKE_BASE_URL}/${project}Root.make" "GNUmakefile"
            download_file "${MAKE_BASE_URL}/${project}Kernel.make" "kernel/GNUmakefile"
            download_file "${BASE_URL}/fstruct/limine.cfg" "kernel/cfg/limine.cfg"
            ;;
        "grub")
            download_file "${MAKE_BASE_URL}/${project}Root.make" "GNUmakefile"
            download_file "${MAKE_BASE_URL}/${project}Kernel.make" "kernel/GNUmakefile"
            download_file "${BASE_URL}/fstruct/grub.cfg" "kernel/cfg/grub.cfg"
            ;;
        "kernel")
            download_file "${MAKE_BASE_URL}/${project}Root.make" "GNUmakefile"
            download_file "${MAKE_BASE_URL}/${project}Kernel.make" "kernel/GNUmakefile"
            ;;
        "custom")
            download_file "${MAKE_BASE_URL}/customRoot.make" "GNUmakefile"
            download_file "${MAKE_BASE_URL}/customKernel.make" "kernel/GNUmakefile"
            download_file "${MAKE_BASE_URL}/customBootloader.make" "bootloader/GNUmakefile"
            ;;
    esac
fi

echo "Project structure and build system setup complete."
echo "Write some code and run \`make\` to compile, build, and run"
echo "or \`make kernel\`, \`make disk\`, or \`make run\` to do only one!"

if [ "$project" == "limine" ]; then
    make limine
fi
