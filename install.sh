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

sudo pacman -Syy

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
                sudo systemctl enable polkit
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

echo "Do you want to install video codecs and rendering packages?"
echo -e "1) Yes \n2) No"
read -p "Enter 1-2: " choiceREND
case $choiceREND in
    1)
        install_pacman "${rendering_packages[@]}"
        ;;
    *)
        ;;
esac

echo "Do you want to install zen kernel?"
echo "WARNING: If your boot partition is small <2G, remove the main kernel with sudo pacman -S linux linux-headers"
echo -e "1) Yes \n2) No"
read -p "Enter 1-2: " choiceZEN
case $choiceZEN in
    1)
        install_pacman linux-zen linux-zen-headers
        ;;
    *)
        ;;
esac

echo "Install basic packages for daily use?"
echo "vlc libreoffice-still thunderbird"
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

if [ "$choiceDE" = "3" ]; then
    install_pacman ${terminal_packages[@]}
    tldr --update
    cp -r yazi ~/.config/
    choiceTPKG=1
else
    echo "Do you want some terminal packages?"
    echo "dysk tealdeer btop fastfetch bat fd eza fzf zoxide ripgrep yazi wl-clipboard"
    echo "1) yes"
    echo "2) no"
    read -p "Enter 1-2: " choiceTPKG
    case $choiceTPKG in
        1)
            install_pacman "${terminal_packages[@]}"
            tldr --update
            cp -r yazi ~/.config/
            ;;
        *)
            ;;
    esac
fi

echo "choose your terminal text editor"
echo "1) nano"
echo "2) vim"
echo "3) micro"
echo "4) neovim"
echo "5) all of them"
echo "6) skip it (not recommended)"
read -p "Enter 1-6: " choiceTTE
case $choiceTTE in
    1)
        install_pacman ${terminal_text_editors[0]}
        ;;
    2)
        install_pacman ${terminal_text_editors[1]}
        ;;
    3)
        install_pacman ${terminal_text_editors[2]}
        ;;
    4)
        install_pacman ${terminal_text_editors[3]}
        ;;
    5)
        install_pacman ${terminal_text_editors[@]}
        ;;
    *)
        ;;
esac

echo "Installing Fonts for different Languages"
install_pacman "${font_packages[@]}"
echo "Finished installing fonts"

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

case $choiceTPKG in
    1)
        install_yay resvg
        ;;
    *)
        ;;
esac

echo "Installing ms-fonts"
install_yay "${ms_fonts[@]}"

echo "Do you wish to add some extra packages? (Utility, editors, etc)"
echo "1) Yes"
echo "2) No"
read -p "Enter 1-2: " choiceAUR
case $choiceAUR in
    1)
        install_yay "${extra[@]}"
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

echo "Choose a Terminal"
terminals=("gnome-console" "ptyxis" "konsole" "alacritty" "ghostty" "kitty" "none")
for i in "${!terminals[@]}"; do
    echo "$((i+1))) ${terminals[i]}"
done

read -p "Enter 1-${#terminals[@]}: " choiceTE

# Validate terminal choice
if ! [[ "$choiceTE" =~ ^[1-7]$ ]]; then
    echo "Invalid selection. Skipping terminal installation."
    choiceTE=7  # set to "none"
fi

terminal_choice="${terminals[$((choiceTE - 1))]}"

case $choiceDE in
    3)
        ;;
    *)
        case $choiceTE in
            1|2|3|6)
                install_pacman "$terminal_choice"
                ;;
            4|5)
                install_yay "$terminal_choice"
                if [[ "$terminal_choice" == "ghostty" ]]; then
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

case $choiceDE in
    3)
        install_yay "${hyprland_aur[@]}"
        if [[ "$terminal_choice" == "kitty" ]]; then
            mkdir -p ~/.config/kitty/
            echo "background_opacity 0.5" >> ~/.config/kitty/kitty.conf
        fi
        cp -r hypr ~/.config/
        cp -r waybar ~/.config/
        cp -r wofi ~/.config/
        sudo usermod -aG video "$USER"
        ;;
    *)
        ;;
esac

echo "Do you wish to install a more beautiful bash?"
echo "1) Yes"
echo "2) No"
read -p "Enter 1 or 2: " choiceSS
case $choiceSS in
    1)
        curl -sS https://starship.rs/install.sh | sh
        sudo cp -r fastfetch ~/.config/
        case $choiceTPKG in
            1)
                sudo cp .betterbash ~/.bashrc
                ;;
            *)
                sudo cp .bashrc ~/.bashrc
                ;;
        esac
        echo "Done"
        ;;
    *)
        echo "Skipping bashrc and starship setup"
        ;;
esac

case $choiceDE in
    1)
        install_yay "${gnome_extra[@]}"
        gsettings set org.gnome.mutter check-alive-timeout 0
        ;;
    *)
        ;;
esac

echo "Do you want to install gaming packages and apply shader booster (credits to psygreg)?"
echo "1) Yes"
echo "2) No"
read -p "Enter 1-2: " choiceGM
case $choiceGM in
    1)
        case $choiceNV in
            1)
                install_yay "${gaming_nvidia_proprietary[@]}"
                wget https://github.com/psygreg/shader-booster/releases/latest/download/patcher.sh
                chmod +x patcher.sh
                ./patcher.sh
                rm patcher.sh
                echo "Finished installing gaming packages"
                ;;
            *)
                install_yay "${gaming[@]}"
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
        echo "1) Yes - Cachyos Kernel"
        echo "2) Yes - Cachyos Bore Kernel (better optmized)"
        echo "3) Yes, both"
        echo "4) No"
        read -p "Enter 1-2: " choiceCK
        case $choiceCK in
            1)
                install_yay "${cachyos_kernel[@]}"
                install_yay "${cachyos_base[@]}"
                echo "Custom kernel added"
                ;;
            2)
                install_yay "${cachyos_bore_kernel[@]}"
                install_yay "${cachyos_base[@]}"
                echo "Bore kernel added"
                ;;
            3)
                install_yay "${cachyos_kernel[@]}"
                install_yay "${cachyos_bore_kernel[@]}"
                install_yay "${cachyos_base[@]}"
                echo "Bore and custom kernel added"
                ;;
            *)
                echo "Skipping custom kernel installation"
                ;;
        esac
        ;;
    *)
        echo "Skipping Cachyos repos"
        ;;
esac

install_video_drivers

if pacman -Qs grub > /dev/null; then
    install_yay grub-btrfs inotify-tools
    sudo systemctl enable --now grub-btrfsd
    sudo grub-mkconfig
    sudo update-grub
fi

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

if systemctl is-enabled gdm &> /dev/null || systemctl is-enabled sddm &> /dev/null; then
    echo "A display manager is already enabled. Skipping."
else
    case $choiceDE in
        1)
            sudo systemctl enable gdm
            case $choiceCK in
                1)
                    sudo -u gdm dbus-launch gsettings set org.gnome.login-screen logo ''
                    ;;
                *)
                    ;;
            esac 
            ;;
        2|3)
            sudo systemctl enable sddm
            ;;
        *)
            echo "Error: Invalid choiceDE value: $choiceDE. Please set to 1 (GNOME), 2 (KDE), or 3 (Hyprland)."
            exit 1
            ;;
    esac
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