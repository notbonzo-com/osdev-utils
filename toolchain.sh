#!/bin/bash

###
# NotBonzo's ultimate ELF-GCC Installer.
###
# @brief Build the toolchains for your OSDEV journey easily as a professional programmer.
###

echo "--------------------------"
echo "NotBonzo's ELF-GCC Installer"
echo "--------------------------"
echo ""

ARCHITECTURE="x86_64-elf"
INSTALL_DIR="$HOME/toolchain"
SYMLINK="neither"

BINUTILS_VERSION_1="2.42"
GCC_VERSION_1="14.1.0"
BINUTILS_VERSION_2="2.37"
GCC_VERSION_2="11.2.0"

function install_packages() {
    if [ -f "/etc/os-release" ]; then
        . /etc/os-release
    else
        echo "Error: /etc/os-release not found. Cannot determine distribution." >&2
        exit 0
    fi

    declare -A pkgs=(
        [curl]="curl"
        [tar]="tar"
        [make]="make"
        [gcc]="gcc"
        [gcc-c++]="g++"
        [bison]="bison"
        [flex]="flex"
        [gmp-devel]="libgmp-dev"
        [libmpc-devel]="libmpc-dev"
        [mpfr-devel]="libmpfr-dev"
        [texinfo]="texinfo"
        [nasm]="nasm"
    )

    if [[ $ID == "fedora" || $ID == "rhel" || $ID == "centos" ]]; then
        pkgs[gcc-c++]="gcc-c++"
        pkgs[gmp-devel]="gmp-devel"
        pkgs[libmpc-devel]="libmpc-devel"
        pkgs[mpfr-devel]="mpfr-devel"
    fi

    if [[ $ID == "arch" || $ID == "manjaro" ]]; then
        pkgs[gmp-devel]="gmp"
        pkgs[libmpc-devel]="libmpc"
        pkgs[mpfr-devel]="mpfr"
    fi

    packages="${pkgs[@]}"

    function execute_with_error_handling() {
        if ! $@; then
            echo "Error: Failed to execute '$@'" >&2
            exit 0
            # If you are wondering why I am using exit 0 everywhere, its so the quick command using `&&` deletes the script
        fi
    }

    case $ID in
        debian|ubuntu|pop)
            execute_with_error_handling sudo apt-get update
            execute_with_error_handling sudo apt-get install -y $packages
            ;;
        fedora|rhel|centos)
            execute_with_error_handling sudo dnf update -y
            execute_with_error_handling sudo dnf install -y $packages
            ;;
        arch|manjaro)
            execute_with_error_handling sudo pacman -Syu --noconfirm $packages
            ;;
        opensuse|opensuse-leap|opensuse-tumbleweed)
            execute_with_error_handling sudo zypper refresh
            execute_with_error_handling sudo zypper install -y $packages
            ;;
        *)
            echo "Error: Unsupported distribution '$ID'. Please install the required packages manually:" >&2
            echo "${!pkgs[@]}"
            exit 0
            ;;
    esac
}

function check_requirements() {
    for cmd in curl tar make gcc realpath g++ bison flex nasm; do
        if ! command -v $cmd &> /dev/null; then
            echo "Error: Required command '$cmd' is not installed." >&2
            read -p "Do you want to try to install it? (yes/no)" install
            if [ "$install" = "yes" ]; then
                install_packages
            else
                echo "Exiting. No changes made."
                exit 0
            fi
            return
        fi
    done
}

function show_menu() {
    echo "Please select the architecture:"
    echo "1) x86_64-elf"
    echo "2) i686-elf"
    read -p "Selection (1-2): " arch_choice
    case $arch_choice in
        1) ARCHITECTURE="x86_64-elf";;
        2) ARCHITECTURE="i686-elf";;
        *) echo "Invalid selection"; exit 0;;
    esac

    read -p "Enter installation directory [$INSTALL_DIR]: " input_install_dir
    INSTALL_DIR="${input_install_dir:-$INSTALL_DIR}"

    read -p "Do you want to symlink the executables to /bin, add to PATH, or neither? (symlink/path/neither) [$SYMLINK]: " action_choice
    case $action_choice in
        symlink|path|neither)
            SYMLINK=$action_choice
            ;;
        *)
            echo "Invalid selection. Defaulting to 'neither'."
            SYMLINK="neither"
            ;;
    esac

    if [ "$SYMLINK" = "path" ]; then
        DEFAULT_SHELL=$(basename "$SHELL")
        read -p "Detected shell is $DEFAULT_SHELL. Override if different (bash/zsh/fish) or press enter to accept: " input_shell
        USER_SHELL="${input_shell:-$DEFAULT_SHELL}"
    fi
    if [ "$SYMLINK" = "symlink" ]; then
        echo ""
    fi

    echo "Please select version of the toolchains:"
    echo "1) Binutils $BINUTILS_VERSION_1 and GCC $GCC_VERSION_1"
    echo "2) Binutils $BINUTILS_VERSION_2 and GCC $GCC_VERSION_2"
    read -p "Selection (1-2): " version_choice
    case $version_choice in
        1) 
            BINUTILS_VERSION=$BINUTILS_VERSION_1
            GCC_VERSION=$GCC_VERSION_1
            ;;
        2)
            BINUTILS_VERSION=$BINUTILS_VERSION_2
            GCC_VERSION=$GCC_VERSION_2
            ;;
        *)
            echo "Invalid selection"; exit 0;;
    esac

    echo "Configuration:"
    echo "Architecture: $ARCHITECTURE"
    echo "Installation Directory: $INSTALL_DIR"
    echo "Binutils Version: $BINUTILS_VERSION"
    echo "GCC Version: $GCC_VERSION"
    if [ "$SYMLINK" = "path" ]; then
        echo "Adding folder to path: Yes"
        echo "Shell: $USER_SHELL"
        echo "Symlink executables to /bin: No"
    fi
    if [ "$SYMLINK" = "symlink" ]; then
        echo "Adding folder to path: No"
        echo "Shell: irrelevant"
        echo "Symlink executables to /bin: Yes"
    fi
}

function confirm_and_proceed() {
    read -p "Are you sure you want to proceed with these settings? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Installation aborted."
        exit 0
    fi
}

function check_existing_installation() {
    if [ -d "$INSTALL_DIR/$ARCHITECTURE" ]; then
        echo "Warning: Toolchain already installed in $INSTALL_DIR/$ARCHITECTURE"
        read -p "Do you want to overwrite? (yes/no): " overwrite
        if [ "$overwrite" != "yes" ]; then
            echo "Exiting. No changes made."
            exit 0
        fi
        rm -rf "$INSTALL_DIR/$ARCHITECTURE"
    fi
}

function add_to_path() {
    local toolchain_path="$TOOLCHAIN_PREFIX/bin"
    case $USER_SHELL in
        bash)
            echo "export PATH=\$PATH:$toolchain_path" >> ~/.bashrc
            ;;
        zsh)
            echo "export PATH=\$PATH:$toolchain_path" >> ~/.zshrc
            ;;
        fish)
            echo "set -U fish_user_paths $toolchain_path \$fish_user_paths" >> ~/.config/fish/config.fish
            ;;
        *)
            echo "Unsupported shell. Please add $toolchain_path to your PATH manually."
            ;;
    esac
    echo "Please restart your terminal or source your shell configuration file to apply PATH changes."
}

function install_toolchain() {
    echo "Installing toolchain for $ARCHITECTURE in $INSTALL_DIR..."
    TOOLCHAIN_PREFIX=$(realpath -m "$INSTALL_DIR/$ARCHITECTURE")

    mkdir -p "$TOOLCHAIN_PREFIX"

    cd "$TOOLCHAIN_PREFIX" || { echo "Failed to change directory to $TOOLCHAIN_PREFIX"; exit 0; }

    MAKEFLAGS="-j$(nproc)"

    function fetch() {
        url="$1"
        filename="${url##*/}"
        if [ ! -f "$filename" ]; then
            echo "Downloading $filename..."
            curl -LO "$url" || { echo "Failed to download $filename"; exit 0; }
        fi
        if [ ! -s "$filename" ]; then
            echo "Error: Downloaded file $filename is empty." >&2
            exit 0
        fi
    }

    BINUTILS_URL="https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz"
    GCC_URL="https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz"

    fetch "$GCC_URL"
    fetch "$BINUTILS_URL"

    echo "Extracting GCC..."
    tar -xf "gcc-${GCC_VERSION}.tar.xz" || { echo "Failed to extract GCC."; exit 0; }
    echo "Extracting Binutils..."
    tar -xf "binutils-${BINUTILS_VERSION}.tar.xz" || { echo "Failed to extract Binutils."; exit 0; }

    mkdir -p "$TOOLCHAIN_PREFIX/build-binutils"
    mkdir -p "$TOOLCHAIN_PREFIX/build-gcc"

    pushd "$TOOLCHAIN_PREFIX/build-binutils" > /dev/null
    ../binutils-${BINUTILS_VERSION}/configure \
        --prefix="$TOOLCHAIN_PREFIX"              \
        --target=$ARCHITECTURE                    \
        --with-sysroot                            \
        --disable-nls                             \
        --disable-werror && make $MAKEFLAGS && make install
    popd > /dev/null

    pushd "$TOOLCHAIN_PREFIX/build-gcc" > /dev/null
    ../gcc-${GCC_VERSION}/configure \
        --prefix="$TOOLCHAIN_PREFIX"  \
        --target=$ARCHITECTURE        \
        --disable-nls                 \
        --enable-languages=c,c++      \
        --without-headers && make $MAKEFLAGS all-gcc all-target-libgcc && make install-gcc install-target-libgcc
    popd > /dev/null

    if [ "$SYMLINK" = "symlink" ]; then
        echo "Symlinking executables to /bin..."
        declare -a tools=("gcc" "ld" "as" "g++")
        for tool in "${tools[@]}"; do
            src="$TOOLCHAIN_PREFIX/bin/$ARCHITECTURE-$tool"
            dest="/usr/local/bin/$ARCHITECTURE-$tool"
            [ -L "$dest" ] && sudo rm "$dest"
            sudo ln -s "$src" "$dest" || { echo "Failed to create symlink for $tool"; exit 0; }
        done
    elif [ "$SYMLINK" = "path" ]; then
        add_to_path
        echo "Added $TOOLCHAIN_PREFIX/bin to your $USER_SHELL PATH."
    fi

    echo "Installation complete."
    echo "Run $ARCHITECTURE-gcc for the GNU C Compiler"
    echo "Run $ARCHITECTURE-ld for the GNU Linker"
    echo "Run $ARCHITECTURE-as for the GNU Assembler"
    echo "Run $ARCHITECTURE-g++ for the GNU C++ Compiler"
}

check_requirements
show_menu
confirm_and_proceed
check_existing_installation
install_toolchain
