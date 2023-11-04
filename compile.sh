#!/bin/bash

# Check prerequisites
available_space=$(df -BG / | awk 'NR==2 {print $4}' | grep -o '[0-9]*')
if [[ $available_space -lt 15 ]]; then
    echo "Not enough disk space. You need at least 15GB. Exiting."
    exit 1
fi

# Update system
read -p "Do you want to update system packages? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Updating system packages..."
    if ! sudo pacman -Syu; then
        echo "System update failed. Exiting."
        exit 1
    fi
else
    echo "Skipping system update."
fi

# Install required packages
echo "Installing required packages..."
if ! sudo pacman -S --needed base-devel git bc; then
    echo "Failed to install necessary packages. Exiting."
    exit 1
fi

# Clone Linux kernel source
echo "Cloning Linux kernel source..."
if ! git clone https://github.com/torvalds/linux.git; then
    echo "Git clone failed. Exiting."
    exit 1
fi
cd linux || { echo "Changing directory failed. Exiting."; exit 1; }

# Ask if the user wants to modify the kernel source
read -p "Would you like to modify the kernel's source code before compiling? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Make your changes and press any key to continue..."
    read -n 1 -r
fi

# Compile the kernel
echo "Starting kernel compilation..."
make menuconfig
if ! sudo make -j"$(nproc)"; then
    echo "Kernel compilation failed. Exiting."
    exit 1
fi
echo "Installing kernel modules..."
sudo make modules_install
echo "Installing the kernel..."
sudo make install

# Ask how to set up the bootloader
read -p "Do you want automatic bootloader setup? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Setting up bootloader..."
    # Update bootloader config
    if [ -d /boot/grub ]; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    elif [ -d /boot/loader ]; then
        # Assuming systemd-boot
        KERNEL_VERSION=$(make kernelrelease)
        sudo cp arch/x86/boot/bzImage "/boot/vmlinuz-$KERNEL_VERSION"
        echo -e "title Linux $KERNEL_VERSION\nefi /vmlinuz-$KERNEL_VERSION" | sudo tee "/boot/loader/entries/$KERNEL_VERSION.conf"
        sudo bootctl update
    else
        echo "Neither GRUB nor systemd-boot detected. Manual bootloader configuration needed."
    fi
else
    echo "Skipping automatic bootloader setup. Manual configuration required."
fi

# Optional cleanup
read -p "Do you want to clean the kernel source tree (y), remove the cloned repository (r), or keep everything (k)? (y/r/k) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    make clean
    echo "Cleaned the kernel source tree."
elif [[ $REPLY =~ ^[Rr]$ ]]; then
    cd .. && rm -rf linux
    echo "Removed the cloned repository."
else
    echo "Kept everything as is."
fi
