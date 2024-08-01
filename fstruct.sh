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
read -p "Enter the number: " project

echo "Select language:"
echo "1. C/C++ Cross Compiler"
echo "2. C/C++ Native"
read -p "Enter the number: " language

read -p "Do you want to use a predefined linker.ld? (y/n): " use_linker

echo "Select build system:"
echo "1. Make"
read -p "Enter the number: " build_system

case $project in
    1) project="limine" ;;
    2) project="grub" ;;
    3) project="kernel" ;;
    *) echo "Invalid project type"; exit 1 ;;
esac

mkdir -p kernel/{src,inc,cfg}

if [ "$use_linker" == "y" ]; then
    download_file "${LINKER_BASE_URL}/${project}-c++.ld" "kernel/cfg/linker.ld"
fi

if [ "$language" == "2" ]; then
    project2="${project}Native"
fi

if [ "$build_system" == "1" ]; then
    case $project in
        "limine")
            download_file "${MAKE_BASE_URL}/${project2}Root.make" "GNUmakefile"
            download_file "${MAKE_BASE_URL}/${project2}Kernel.make" "kernel/GNUmakefile"
            download_file "${BASE_URL}/fstruct/limine.cfg" "kernel/cfg/limine.cfg"
            ;;
        "grub")
            download_file "${MAKE_BASE_URL}/${project2}Root.make" "GNUmakefile"
            download_file "${MAKE_BASE_URL}/${project2}Kernel.make" "kernel/GNUmakefile"
            download_file "${BASE_URL}/fstruct/grub.cfg" "kernel/cfg/grub.cfg"
            ;;
        "kernel")
            download_file "${MAKE_BASE_URL}/${project2}Root.make" "GNUmakefile"
            download_file "${MAKE_BASE_URL}/${project2}Kernel.make" "kernel/GNUmakefile"
            ;;
    esac
fi

echo "Project structure and build system setup complete."
echo "Write some code and run \`make\` to compile, build, and run"
echo "or \`make kernel\`, \`make disk\`, or \`make run\` to do only one!"

if [ "$project" == "limine" ]; then
    make limine
fi