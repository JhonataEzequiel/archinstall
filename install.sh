#!/bin/bash

# Update mirrorlist using reflector
echo "Updating Mirrorlist for a faster download!"
if ! sudo pacman -S --needed reflector || ! sudo reflector --sort rate --latest 20 --protocol https --save /etc/pacman.d/mirrorlist; then
    echo "Error: Failed to update mirrorlist. Please check your internet connection or permissions."
    exit 1
fi
echo "Done updating mirrorlist"

# Choosing DE
while true; do
    echo "Choose your Desktop Environment:"
    echo "1) GNOME"
    echo "2) KDE Plasma"
    echo "3) Exit the Script"
    read -p "Enter 1, 2 or 3: " choiceDE

    case $choiceDE in
        1)
            echo "Installing GNOME and its base packages..."
            if sudo pacman -S --needed gdm xdg-user-dirs-gtk power-profiles-daemon xorg-server nautilus gedit file-roller evince adwaita-icon-theme xdg-desktop-portal-gnome baobab gnome-shell gnome-control-center gnome-settings-daemon gnome-session gnome-tweaks gnome-calculator gnome-disk-utility gnome-online-accounts gvfs-google gvfs loupe gnome-menus gnome-software; then
                echo "Finished Installing GNOME"
                break
            else
                echo "Error: GNOME installation failed. Please check your internet or repositories."
                exit 1
            fi
            ;;
        2)
            echo "Installing KDE Plasma and its base packages..."
            if sudo pacman -S --needed sddm xdg-user-dirs plasma-desktop dolphin kate spectacle plasma-nm plasma-pa powerdevil kscreen kinfocenter breeze-icons xdg-desktop-portal-kde kcalc ark partitionmanager systemsettings plasma-workspace plasma-systemmonitor kde-gtk-config bluedevil discover filelight kdeplasma-addons okular xorg-server gwenview sddm-kcm dolphin-plugins elisa; then
                echo "Finished Installing KDE Plasma"
                break
            else
                echo "Error: KDE Plasma installation failed. Please check your internet or repositories."
                exit 1
            fi
            ;;
        3)
            echo "Exiting"
            exit 1
            break
            ;;
        *)
            echo "Invalid Choice! Please enter 1 or 2."
            ;;
    esac
done

echo "Installing base Packages"
sudo pacman -S --needed dconf bluez bluez-utils nano git curl wget tealdeer timeshift fastfetch htop pacman-contrib discord telegram-desktop vlc libreoffice-still gimp kdenlive qbittorrent audacity dconf-editor obs-studio unzip unrar p7zip tar python-pip os-prober ufw
echo "Finished installing base packages"

echo "Installing Fonts for different Languages"
sudo pacman -S --needed noto-fonts-cjk noto-fonts adobe-source-code-pro-fonts noto-fonts-emoji otf-font-awesome ttf-droid ttf-fira-code ttf-jetbrains-mono-nerd
echo "Finished installing fonts"

echo "Do you wish to install nvidia drivers?"
echo "1) Yes, proprietary drivers"
echo "2) Yes, open drivers"
echo "3) No"
read -p "Enter 1, 2, or 3: " choiceNV
case $choiceNV in
    1)
        echo "Installing proprietary drivers"
        sudo pacman -S egl-gbm egl-x11 nvidia-dkms nvidia-utils nvidia-prime
        echo "Installed proprietary drivers"
        ;;
    2)
        echo "Installing open drivers"
        sudo pacman -S egl-gbm egl-x11 nvidia-open-dkms nvidia-utils nvidia-prime
        ;;
    *)
        ;;
esac

echo "Enabling Bluetooth, paccache, and timeshift"
sudo systemctl enable --now bluetooth.service && sudo systemctl enable paccache.timer && systemctl enable --now cronie.service

echo "Installing yay as an AUR helper"
sudo pacman -S --needed base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si && cd && rm -rf yay

echo "Installing chaotic-aur"
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
cat pacman.conf > /etc/pacman.conf
sudo pacman -Syu

echo "Installing ms-fonts"
yay -S --needed ttf-ms-fonts ttf-tahoma ttf-vista-fonts

echo "Select a browser"
echo "1) Firefox"
echo "2) Brave"
echo "3) Zen"
echo "4) Don't want to install a browser"
read -p "Enter 1-4: " choiceBrowser
case choiceBrowser in
    1)
        sudo pacman -S firefox
        "Firefox Installed"
        ;;
    2)
        yay -S brave
        "Brave Installed"
        ;;
    3)
        yay -S zen-browser-bin
        "Zen Installed"
        ;;
    *)
        echo "Skipped browser installation"
        ;;
esac

echo "Choose a Terminal"
echo "1) gnome-console"
echo "2) ptyxis"
echo "3) konsole"
echo "4) alacritty"
echo "5) ghostyy"
read -p "Enter 1-5: " choiceTE
case choiceTE in
    1)
        sudo pacman -S gnome-console
        ;;
    2)
        sudo pacman -S ptyxis
        ;;
    3)
        sudo pacman -S konsole
        ;;
    4)
        yay -S alacritty
        ;;
    5)
        yay -S ghostty
        ;;
    *)
        echo "skipping terminal emulator installation"
        ;;
esac

echo "Do you wish to install starship and a better bashrc?"
echo "1) Yes"
echo "2) No"
read -p "Enter 1 or 2: " choiceSS
case choiceSS in
    1)
        curl -sS https://starship.rs/install.sh | sh
        cat bashrc.txt > ~/.bashrc
        echo "Done"
        ;;
    *)
        echo "Skipping bashrc and starship setup"
        ;;
esac

case choiceDE in
     1)
        echo "Installing extension manager for gnome"
        yay -S --needed extension-manager
        ;;
    *)
        ;;
esac

echo "Do you want to install gaming packages?"
echo "1) Yes"
echo "2) No"
read -p "Enter 1-2: " choiceGM
case choiceGM in
    1)
        yay -S --needed heroic-games-launcher-bin steam lutris gamescope mangohud wine winetricks vkd3d lib32-nvidia-utils glfw goverlay-bin wqy-zenhei protonplus gamemode jdk21-openjdk
        echo "Finished installing gaming packages"
        ;;
    *)
        echo "Skipped gaming packages"
        ;;
esac

echo "Do you want to install emulators from the aur? (Experimental, and can take a long time)"
echo "1) Yes"
echo "2) No"
read -p "Enter 1-2: " choiceEMU
case choiceEMU in
    1)
        echo "Installing Emulators"
        yay -S --needed melonds-git azahar shadps4-git mgba-qt-git rpcs3-git pcsx2-git duckstation-git ryujinx-canary cemu-git dolphin-emu-git kega-fusion ppsspp-git vita3k-git mesen2-git
        echo "Emulators Installed"
        ;;
    *)
        echo "Skipped Emulators"
        ;;
esac

echo "Do you wish to add cachyos repos?"
echo "1) Yes"
echo "2) No"
read -p "Enter 1-2: " choiceCA
case choiceCA in
    1)
        curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz && tar xvf cachyos-repo.tar.xz && cd cachyos-repo && sudo ./cachyos-repo.sh && cd && rm -rf cachyos-repo cachyos-repo.tar.xz
        echo "Repos added"
        echo "Do you wish to add cachyos custom Kernels?"
        echo "1) Yes"
        echo "2) No"
        read -p "Enter 1-2: " choiceCK
        case choiceCK in
            1)
                yay -S --needed linux-cachyos linux-cachyos-headers
                echo "custom kernel added"
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

echo "updating grub"
sudo update-grub

echo "adding flatpak support"
sudo pacman -S --needed flatpak

