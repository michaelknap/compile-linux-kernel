# Linux Kernel Compilation Script

This Bash script automates the process of downloading, compiling, and installing the Linux kernel on Arch or Arch based systems. It also handles bootloader setup for both GRUB and systemd-boot.

## Usage

```bash
cd /tmp # (optional)
git clone https://github.com/michaelknap/compile-linux-kernel.git
cd compile-linux-kernel
chmod +x compile.sh
./compile.sh
```
## Features

- Updates system packages (optional).
- Installs required packages.
- Downloads Linux kernel source from the official repository.
- Provides option to modify kernel source before compilation.
- Compiles and installs the kernel.
- Automatically sets up the bootloader (optional).
- Provides an option to clean up after installation.