#!/bin/bash

source packages.sh

# Check if running on Arch Linux
if [[ ! -f /etc/arch-release ]]; then
    echo "Error: This script is designed for Arch Linux only."
    exit 1
fi

# Check for required commands
for cmd in pacman git sudo; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is not installed."
        exit 1
    fi
done

# Update mirrorlist using reflector
echo "Updating mirrorlist for faster downloads..."
if ! command -v reflector &> /dev/null; then
    echo "Installing reflector..."
    install_pacman reflector
fi
sudo reflector --sort rate --latest 20 --protocol https --save /etc/pacman.d/mirrorlist
echo "Mirrorlist updated successfully."

install_pacman -Syy

# Main Drivers
echo "Installing open-source video drivers"
install_pacman "${video_drivers[@]}"

# Choosing DE
while true; do
    echo "Choose your Desktop Environment:"
    echo "1) GNOME"
    echo "2) KDE Plasma"
    echo "3) Hyprland"
    echo "4) Exit the Script"
    read -p "Enter 1, 2, 3 or 4: " choiceDE

    case $choiceDE in
        1)
            echo "Installing GNOME and its base packages..."
            if install_pacman "${gnome_packages[@]}"; then
                echo "Finished Installing GNOME"
                break
            else
                echo "Error: GNOME installation failed. Please check your internet or repositories."
                exit 1
            fi
            ;;
        2)
            echo "Installing KDE Plasma and its base packages..."
            if install_pacman "${kde_packages[@]}"; then
                echo "Finished Installing KDE Plasma"
                break
            else
                echo "Error: KDE Plasma installation failed. Please check your internet or repositories."
                exit 1
            fi
            ;;
        3)
            echo "Installing Hyprland and its configs"
            if install_pacman "${hyprland_packages[@]}"; then
                echo "Finished Installing base Hyprland packages"
                break
            else
                echo "Error: Hyprland installation failed. Please check your internet or repositories."
                exit 1
            fi
            ;;
        4)
            echo "Exiting"
            exit 0
            ;;
        *)
            echo "Invalid Choice! Please enter 1, 2, or 3."
            ;;
    esac
done

echo "Installing base Packages"
install_pacman "${base_packages[@]}"
echo "Finished installing base packages"

echo "Do you wish to install additional packages that can be useful?"
echo "vlc libreoffice-still tealdeer fastfetch thunderbird"
echo "1) Yes"
echo "2) No"
read -p "Enter 1-2: " choicePKG
case $choicePKG in
    1)
        install_pacman "${additional_packages[@]}"
        ;;
    *)
        ;;
esac

echo "Installing Fonts for different Languages"
install_pacman "${font_packages[@]}"
echo "Finished installing fonts"

if lspci | grep -i nvidia &> /dev/null; then
    echo "NVIDIA hardware detected."
    echo "NVIDIA driver options:"
    echo "1) Proprietary: Better performance, closed-source."
    echo "2) Open: Open-source, may have lower performance."
    echo "3) No: Skip NVIDIA drivers."
    read -p "Enter 1, 2, or 3: " choiceNV
    case $choiceNV in
        1)
            echo "Installing proprietary drivers"
            install_pacman "${nvidia_proprietary[@]}"
            echo "Installed proprietary drivers"
            ;;
        2)
            echo "Installing open drivers"
            install_pacman "${nvidia_open[@]}"
            ;;
        *)
            ;;
    esac
else
    echo "No NVIDIA hardware detected. Skipping NVIDIA driver installation."
    choiceNV=3
fi

echo "Enabling Bluetooth, paccache, and timeshift"
sudo systemctl enable --now bluetooth.service
sudo systemctl enable paccache.timer
systemctl enable --now cronie.service

if command -v yay &> /dev/null; then
    echo "yay is already installed."
else
    echo "Installing yay as an AUR helper"
    install_pacman base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd ..
    rm -rf yay
fi

if [[ ! -f pacman.conf ]]; then
    touch /etc/pacman.conf
fi

echo "Installing chaotic-aur"
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
sudo cp pacman.conf /etc/pacman.conf
sudo pacman -Syu

echo "Installing ms-fonts"
install_yay "${ms_fonts[@]}"

case $choiceDE in
    3)
        install_yay "${hyprland_aur[@]}"
        cp -r kitty ~/.config/
        cp -r hypr ~/.config/
        cp -r waybar ~/.config/
        cp -r wofi ~/.config/
        sudo usermod -aG video $USER
        ;;
    *)
        ;;
esac

echo "Do you wish to add some extra packages? (Utility, editors, etc)"
echo "1) Yes"
echo "2) No"
read -p "Enter 1-2: " choiceAUR
case $choiceAUR in
    1)
        install_yay "${extra_aur[@]}"
        ;;
    *)
        ;;
esac

echo "Select a browser"
browsers=("firefox" "brave" "zen-browser-bin" "vivaldi" "chrome" "floorp" "librewolf" "chromium" "firedragon" "waterfox" "none")
for i in "${!browsers[@]}"; do
    echo "$((i+1))) ${browsers[i]}"
done
read -p "Enter 1-${#browsers[@]}: " choiceBR
if [[ "${browsers[choiceBR-1]}" != "none" ]]; then
    if [[ "${browsers[choiceBR-1]}" == "firefox" || "${browsers[choiceBR-1]}" == "vivaldi" ]]; then
        install_pacman "${browsers[choiceBR-1]}"
    else
        install_yay "${browsers[choiceBR-1]}"
    fi
    echo "${browsers[choiceBR-1]} installed."
fi

echo "Choose a Terminal (only kitty for hyprland is configured by default)"
terminals=("gnome-console" "ptyxis" "konsole" "alacritty" "ghostty" "kitty" "none")
for i in "${!terminals[@]}"; do
    echo "$((i+1))) ${terminals[i]}"
done
read -p "Enter 1-${#terminals[@]}: " choiceTE
case $choiceDE in
    3)
        ;;
    *)
        case $choiceTE in
            1|2|3|6)
                install_pacman "${terminals[choiceTE-1]}"
                ;;
            4|5)
                install_yay "${terminals[choiceTE-1]}"
                if [[ "${terminals[choiceTE-1]}" == "ghostty" ]]; then
                    echo "Do you want my ghostty customization?"
                    echo "1) Yes"
                    echo "2) No"
                    read -p "Enter 1-2: " choiceGH
                    case $choiceGH in
                        1)
                            cp -r ghostty ~/.config/
                            ;;
                        *)
                            ;;
                    esac
                fi
                ;;
            *)
                echo "Skipping terminal emulator installation"
                ;;
        esac
esac

echo "Do you wish to install a more beautiful bash?"
echo "1) Yes"
echo "2) No"
read -p "Enter 1 or 2: " choiceSS
case $choiceSS in
    1)
        curl -sS https://starship.rs/install.sh | sh
        sudo cp -r fastfetch ~/.config/
        sudo cp .bashrc ~/.bashrc
        echo "Done"
        ;;
    *)
        echo "Skipping bashrc and starship setup"
        ;;
esac

case $choiceDE in
    1)
        echo "Installing extension manager for gnome"
        install_yay extension-manager
        ;;
    *)
        ;;
esac

echo "Do you want to install gaming packages?"
echo "1) Yes"
echo "2) No"
read -p "Enter 1-2: " choiceGM
case $choiceGM in
    1)
        case $choiceNV in
            1)
                install_yay "${gaming_nvidia_proprietary[@]}"
                echo "Finished installing gaming packages"
                ;;
            2)
                install_yay "${gaming_nvidia_open[@]}"
                echo "Finished installing gaming packages"
                ;;
        esac
        ;;
    *)
        echo "Skipped gaming packages"
        ;;
esac

echo "Do you wish to add cachyos repos?"
echo "1) Yes"
echo "2) No"
read -p "Enter 1-2: " choiceCA
case $choiceCA in
    1)
        curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz
        tar xvf cachyos-repo.tar.xz
        cd cachyos-repo
        sudo ./cachyos-repo.sh
        cd ..
        rm -rf cachyos-repo cachyos-repo.tar.xz

        echo "Repos added"
        echo "Do you wish to add cachyos custom Kernels?"
        echo "1) Yes"
        echo "2) No"
        read -p "Enter 1-2: " choiceCK
        case $choiceCK in
            1)
                install_yay "${cachyos_kernels[@]}"
                echo "Custom kernel added"
                ;;
            *)
                echo "Skipped custom kernel"
                ;;
        esac
        ;;
    *)
        echo "Skipping Cachyos repos"
        ;;
esac

echo "Updating grub"
install_pacman update-grub
sudo update-grub

echo "Adding flatpak support"
install_pacman flatpak

echo "Do you want to install video game emulators?"
echo "1) Yes, via flatpak"
echo "2) Yes, via AUR packages"
echo "3) Yes, mix them up for better packages and updates (recommended)"
echo "4) No"
read -p "Enter 1-4: " choiceEM
case $choiceEM in
    1)
        install_flatpak "${emulators_flatpak_complete[@]}"
        ;;
    2)
        echo "Installing Emulators"
        install_yay "${emulators_aur[@]}"
        echo "Emulators Installed"
        ;;
    3)
        install_yay "${emulators_mixed_aur[@]}"
        install_flatpak "${emulators_flatpak[@]}"
        ;;
    *)
        echo "Skipped Emulators"
        ;;
esac

echo "Do you want to install some good flatpak packages?"
echo "1) Yes"
echo "2) No"
read -p "Enter 1-2: " choiceFP
case $choiceFP in
    1)
        install_flatpak "${flatpak_packages[@]}"
        ;;
    *)
        ;;
esac

if systemctl is-enabled gdm &> /dev/null || systemctl is-enabled sddm &> /dev/null; then
    echo "A display manager is already enabled. Skipping."
else
    sudo systemctl enable "${choiceDE == 1 ? gdm : sddm}"
fi

echo "Installation complete. Reboot required to apply changes."
read -p "Reboot now? (y/N): " reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    echo "Rebooting in 5 seconds..."
    sleep 5
    reboot
else
    echo "Please reboot manually to apply changes."
fi