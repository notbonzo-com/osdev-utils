#!/bin/bash
# Ultimate ELF Cross-Compiler Toolchain Installer
# Non-interactive when configuration variables are preset.
# TODO Add cmdline switches instead of relying on environment variables.

set -e

ARCHITECTURE=${ARCHITECTURE:-"x86_64-elf"}
INSTALL_DIR=${INSTALL_DIR:-"$HOME/toolchain"}
SYMLINK=${SYMLINK:-"neither"}
USER_SHELL=${USER_SHELL:-""}
CUSTOM_GCC_WITH_ARCH=${CUSTOM_GCC_WITH_ARCH:-""}
CUSTOM_GCC_WITH_TUNE=${CUSTOM_GCC_WITH_TUNE:-""}
CUSTOM_GCC_DISABLE_SIMD=${CUSTOM_GCC_DISABLE_SIMD:-""}
ENABLE_LANGUAGES=${ENABLE_LANGUAGES:-"c,c++"}

declare -A ARCH_OPTIONS=(
    [1]="x86_64-elf"
    [2]="i686-elf"
    [3]="i386-elf"
    [4]="i486-elf"
    [5]="i586-elf"
    [6]="arm-none-eabi"
    [7]="riscv64-elf"
)

declare -A VERSION_OPTIONS=(
    [1]="2.42 14.1.0"
    [2]="2.37 11.2.0"
)

CACHE_DIR="/tmp/toolchain_cache"
mkdir -p "$CACHE_DIR"

function detect_distro() {
    if [ -f "/etc/os-release" ]; then
        . /etc/os-release
    else
        echo "Warning: /etc/os-release not found. Using generic settings."
        ID="generic"
        ID_LIKE=""
    fi
}

function install_dependencies() {
    detect_distro

    declare -A pkgs=(
        [curl]="curl"
        [tar]="tar"
        [make]="make"
        [gcc]="gcc"
        [g++]="g++"
        [bison]="bison"
        [flex]="flex"
        [gmp]="libgmp-dev"
        [mpc]="libmpc-dev"
        [mpfr]="libmpfr-dev"
        [texinfo]="texinfo"
        [nasm]="nasm"
    )

    if [[ "$ID" == "fedora" || "$ID" == "rhel" || "$ID" == "centos" || "$ID_LIKE" =~ "rhel" ]]; then
        pkgs[g++]="gcc-c++"
        pkgs[gmp]="gmp-devel"
        pkgs[mpc]="libmpc-devel"
        pkgs[mpfr]="mpfr-devel"
    elif [[ "$ID" == "arch" || "$ID_LIKE" =~ "arch" ]]; then
        pkgs[gmp]="gmp"
        pkgs[mpc]="libmpc"
        pkgs[mpfr]="mpfr"
    fi

    packages="${pkgs[@]}"

    run_cmd() {
        if ! "$@"; then
            echo "Warning: Command '$*' failed. Please check manually."
        fi
    }

    case "$ID" in
        debian|ubuntu|pop|linuxmint)
            run_cmd sudo apt-get update
            run_cmd sudo apt-get install -y $packages
            ;;
        fedora|rhel|centos)
            run_cmd sudo dnf update -y
            run_cmd sudo dnf install -y $packages
            ;;
        arch|manjaro)
            run_cmd sudo pacman -Syu --noconfirm $packages
            ;;
        opensuse* )
            run_cmd sudo zypper refresh
            run_cmd sudo zypper install -y $packages
            ;;
        *)
            echo "Unsupported distro '$ID'. Please install the following packages manually:" >&2
            echo "${pkgs[@]}"
            ;;
    esac
}

function validate_commands() {
    for cmd in curl tar make gcc realpath g++ bison flex nasm; do
        if ! command -v "$cmd" > /dev/null; then
            echo "Error: '$cmd' is not installed."
            read -p "Attempt to install dependencies? (yes/no): " response
            if [ "$response" = "yes" ]; then
                install_dependencies
            else
                echo "Exiting. Please install missing tools and try again."
                exit 1
            fi
        fi
    done
}

function prompt_configuration() {
    echo "--------------------------"
    echo "ELF Cross-Compiler Installer"
    echo "--------------------------"
    echo ""

    if [ -z "$ARCH_FROM_ENV" ] && [ -z "${ARCH_SET}" ]; then
        echo "Select target architecture:"
        for key in "${!ARCH_OPTIONS[@]}"; do
            echo "$key) ${ARCH_OPTIONS[$key]}"
        done
        read -p "Selection (number): " arch_choice
        ARCHITECTURE="${ARCH_OPTIONS[$arch_choice]}"
        if [ -z "$ARCHITECTURE" ]; then
            echo "Invalid selection. Exiting."
            exit 1
        fi
    fi

    if [ -z "${INSTALL_DIR_SET}" ]; then
        read -p "Installation directory [$INSTALL_DIR]: " input_install
        INSTALL_DIR="${input_install:-$INSTALL_DIR}"
    fi

    if [ -z "${SYMLINK_SET}" ]; then
        read -p "Symlink executables to /usr/local/bin, add to PATH, or neither? (symlink/path/neither) [$SYMLINK]: " action_choice
        case $action_choice in
            symlink|path|neither)
                SYMLINK=$action_choice
                ;;
            *)
                echo "Invalid selection. Defaulting to 'neither'."
                SYMLINK="neither"
                ;;
        esac
    fi

    if [ "$SYMLINK" = "path" ]; then
        if [ -z "$USER_SHELL" ]; then
            DEFAULT_SHELL=$(basename "$SHELL")
            read -p "Detected shell is $DEFAULT_SHELL. Enter shell (bash/zsh/fish) or press enter to accept: " shell_input
            USER_SHELL="${shell_input:-$DEFAULT_SHELL}"
        fi
    fi

    echo "Select toolchain version:"
    for key in "${!VERSION_OPTIONS[@]}"; do
        read BINUTILS_VER GCC_VER <<< "${VERSION_OPTIONS[$key]}"
        echo "$key) Binutils $BINUTILS_VER and GCC $GCC_VER"
    done
    read -p "Selection (number): " version_choice
    if [ -z "${VERSION_OPTIONS[$version_choice]}" ]; then
        echo "Invalid selection. Exiting."
        exit 1
    fi
    read BINUTILS_VERSION GCC_VERSION <<< "${VERSION_OPTIONS[$version_choice]}"

    read -p "Enter custom '--with-arch' value for GCC (or leave empty for default): " input_gcc_arch
    CUSTOM_GCC_WITH_ARCH="${input_gcc_arch:-$CUSTOM_GCC_WITH_ARCH}"
    read -p "Enter custom '--with-tune' value for GCC (or leave empty for default): " input_gcc_tune
    CUSTOM_GCC_WITH_TUNE="${input_gcc_tune:-$CUSTOM_GCC_WITH_TUNE}"
    read -p "Disable SIMD support in GCC? (yes/no) [no]: " simd_choice
    if [ "$simd_choice" = "yes" ]; then
        CUSTOM_GCC_DISABLE_SIMD="--disable-simd"
    fi

    read -p "Enter comma-separated list of languages to enable for GCC (--enable-languages) [${ENABLE_LANGUAGES}]: " input_languages
    ENABLE_LANGUAGES="${input_languages:-$ENABLE_LANGUAGES}"

    echo ""
    echo "Configuration Summary:"
    echo "  Architecture:         $ARCHITECTURE"
    echo "  Installation Dir:     $INSTALL_DIR"
    echo "  Binutils Version:     $BINUTILS_VERSION"
    echo "  GCC Version:          $GCC_VERSION"
    echo "  Enabled Languages:    $ENABLE_LANGUAGES"
    [ -n "$CUSTOM_GCC_WITH_ARCH" ] && echo "  GCC --with-arch:      $CUSTOM_GCC_WITH_ARCH"
    [ -n "$CUSTOM_GCC_WITH_TUNE" ] && echo "  GCC --with-tune:      $CUSTOM_GCC_WITH_TUNE"
    [ -n "$CUSTOM_GCC_DISABLE_SIMD" ] && echo "  GCC SIMD support:     Disabled"
    if [ "$SYMLINK" = "path" ]; then
        echo "  PATH update:          Yes (Shell: $USER_SHELL)"
    elif [ "$SYMLINK" = "symlink" ]; then
        echo "  Symlink executables:  Yes (to /usr/local/bin)"
    else
        echo "  PATH/symlink:         No changes"
    fi
}

function confirm_configuration() {
    read -p "Proceed with these settings? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Installation aborted."
        exit 0
    fi
}

function check_existing_installation() {
    if [ -d "$INSTALL_DIR/$ARCHITECTURE" ]; then
        echo "Warning: Toolchain already exists at $INSTALL_DIR/$ARCHITECTURE."
        read -p "Overwrite existing installation? (yes/no): " overwrite
        if [ "$overwrite" != "yes" ]; then
            echo "Exiting without changes."
            exit 0
        fi
        rm -rf "$INSTALL_DIR/$ARCHITECTURE"
    fi
}

function add_to_path() {
    local toolchain_bin="$TOOLCHAIN_PREFIX/bin"
    case "$USER_SHELL" in
        bash)
            echo "export PATH=\$PATH:$toolchain_bin" >> ~/.bashrc
            ;;
        zsh)
            echo "export PATH=\$PATH:$toolchain_bin" >> ~/.zshrc
            ;;
        fish)
            echo "set -U fish_user_paths $toolchain_bin \$fish_user_paths" >> ~/.config/fish/config.fish
            ;;
        *)
            echo "Unsupported shell. Please add $toolchain_bin to your PATH manually."
            ;;
    esac
    echo "Reload your shell configuration to update PATH."
}

function fetch_file() {
    local url="$1"
    local filename="${url##*/}"
    local cache_file="$CACHE_DIR/$filename"
    if [ -f "$cache_file" ] && [ -s "$cache_file" ]; then
        echo "Using cached $filename from $CACHE_DIR"
    else
        echo "Downloading $filename..."
        curl -Lo "$cache_file" "$url" || { echo "Error: Failed to download $filename"; exit 1; }
    fi
    [ ! -f "$filename" ] && cp "$cache_file" .
}

function build_toolchain() {
    echo "Building toolchain for $ARCHITECTURE in $INSTALL_DIR..."
    TOOLCHAIN_PREFIX=$(realpath -m "$INSTALL_DIR/$ARCHITECTURE")
    mkdir -p "$TOOLCHAIN_PREFIX"
    cd "$TOOLCHAIN_PREFIX" || { echo "Cannot access directory $TOOLCHAIN_PREFIX"; exit 1; }
    MAKEFLAGS="-j$(nproc)"

    local binutils_url="https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz"
    local gcc_url="https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz"

    fetch_file "$binutils_url"
    fetch_file "$gcc_url"

    echo "Extracting sources..."
    tar -xf "binutils-${BINUTILS_VERSION}.tar.xz" || { echo "Extraction failed for Binutils."; exit 1; }
    tar -xf "gcc-${GCC_VERSION}.tar.xz" || { echo "Extraction failed for GCC."; exit 1; }

    mkdir -p build-binutils build-gcc

    pushd build-binutils > /dev/null
    ../binutils-${BINUTILS_VERSION}/configure \
        --prefix="$TOOLCHAIN_PREFIX" \
        --target="$ARCHITECTURE" \
        --with-sysroot \
        --disable-nls \
        --disable-werror && make $MAKEFLAGS && make install
    popd > /dev/null

    pushd build-gcc > /dev/null
    GCC_CONFIG_OPTS="--prefix=$TOOLCHAIN_PREFIX --target=$ARCHITECTURE --disable-nls --enable-languages=${ENABLE_LANGUAGES} --without-headers"
    [ -n "$CUSTOM_GCC_WITH_ARCH" ] && GCC_CONFIG_OPTS+=" --with-arch=$CUSTOM_GCC_WITH_ARCH"
    [ -n "$CUSTOM_GCC_WITH_TUNE" ] && GCC_CONFIG_OPTS+=" --with-tune=$CUSTOM_GCC_WITH_TUNE"
    [ -n "$CUSTOM_GCC_DISABLE_SIMD" ] && GCC_CONFIG_OPTS+=" $CUSTOM_GCC_DISABLE_SIMD"
    ../gcc-${GCC_VERSION}/configure $GCC_CONFIG_OPTS && make $MAKEFLAGS all-gcc all-target-libgcc && make install-gcc install-target-libgcc
    popd > /dev/null

    if [ "$SYMLINK" = "symlink" ]; then
        echo "Creating symlinks in /usr/local/bin..."
        for tool in gcc ld as g++; do
            local src="$TOOLCHAIN_PREFIX/bin/$ARCHITECTURE-$tool"
            local dest="/usr/local/bin/$ARCHITECTURE-$tool"
            [ -L "$dest" ] && sudo rm "$dest"
            sudo ln -s "$src" "$dest" || { echo "Symlink failed for $tool."; exit 1; }
        done
    elif [ "$SYMLINK" = "path" ]; then
        add_to_path
    fi

    echo "Installation complete. Use ${ARCHITECTURE}-gcc, ${ARCHITECTURE}-ld, ${ARCHITECTURE}-as, and ${ARCHITECTURE}-g++ to invoke the toolchain."
}

validate_commands
prompt_configuration
confirm_configuration
check_existing_installation
build_toolchain
