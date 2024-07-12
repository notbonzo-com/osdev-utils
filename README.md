# Osdev Utils
A collection of hand-made utilities that might be useful for both aspiring and new and learning Operating System Developers.

## toolchain.sh

The `toolchain.sh` is a script that simplifies setting up the ELF-GCC toolchain for you. It supports both 32 and 64-bit versions.

**Quick install:**

    curl -L https://raw.githubusercontent.com/notbonzo-com/osdev-utils/main/toolchain.sh -o /tmp/toolchain.sh && chmod +x /tmp/toolchain.sh && /tmp/toolchain.sh

Alternatively, you can download the `toolchain.sh` script and run it from your terminal.

**Features**:
- Supports both 32 and 64-bit versions of GCC and Binutils.
- Customizable installation directory.
- Possibility to symlink the executables to `/bin`.
- Adds installation directory to the PATH (supports bash, zsh, and fish).

## fstruct.sh

The `fstruct.sh` script helps create the structure and build system for OS development projects. It supports different configurations for project types, languages, and build systems.

*When using the quick install, run it in the root of your project!*

**Quick install:**

    curl -L https://raw.githubusercontent.com/notbonzo-com/osdev-utils/main/fstruct.sh -o /tmp/fstruct.sh && chmod +x /tmp/fstruct.sh && /tmp/fstruct.sh

Alternatively, you can download the `fstruct.sh` script and run it from your terminal.

**Features**:
- Supports multiple project types: Limine Kernel, Grub Kernel, Kernel Only.
- Supports both C and C++ languages.
- Option to use predefined linker scripts.
- Sets up Make-based build systems with appropriate configurations for each project type.

### Usage

After running the `fstruct.sh` script, you will have a structured project setup ready for development. Follow the prompts to select your desired configuration:

**Example:**
1. Select project type (e.g., Limine Kernel, Grub Kernel, Kernel Only).
2. Select language (C or C++).
3. Option to use a predefined linker script.
4. Select the build system (Make) more build system support in the future.

**Project Structure:**
