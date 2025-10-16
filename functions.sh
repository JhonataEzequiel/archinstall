#!/bin/bash

source packages.sh

check_prerequisites(){
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
}

update_mirrors(){
    # Update mirrorlist using reflector
    echo "Updating mirrorlist for faster downloads, please wait a moment and ignore the warnings"
    if ! command -v reflector &> /dev/null; then
        echo "Installing reflector..."
        install_pacman reflector
    fi
    sudo reflector --sort rate --latest 20 --protocol https --save /etc/pacman.d/mirrorlist
    echo "Mirrorlist updated successfully."
    sudo pacman -Syy
}

set_variables(){
    echo "Choose your installation method:"
    echo "1) Manual"
    echo "2) Gnome w/gaming packages and emulators"
    echo "3) Gnome without/gaming packages and emulators"
    echo "4) KDE w/gaming packages and emulators"
    echo "5) KDE without/gaming packages and emulators"
    echo "6) Exit"
    read -p "Enter 1-6: " mode

    if [[ ! "$mode" =~ ^[1-6]$ ]]; then
        echo "Invalid input. Please enter a number between 1 and 6."
        exit 1
    fi

    choiceTE=1
    choiceREND=1
    choiceTPKG=1
    choiceTTE=5
    choiceAUR=1
    choiceBR=1
    choiceSS=1

    case $mode in
        2)
            choiceDE=1
            choiceGM=1
            choiceEM=3
            ;;
        3)
            choiceDE=1
            choiceGM=2
            choiceEM=4
            ;;
        4)
            choiceDE=2
            choiceGM=1
            choiceEM=3
            ;;
        5)
            choiceDE=2
            choiceGM=2
            choiceEM=4
            ;;
        6)
            exit 1
            ;;
        *)
            ;;
    esac
    export mode choiceDE choiceTE choiceGM choiceEM choiceREND choiceTPKG choiceTTE choiceAUR choiceBR choiceSS 
}

bluetooth_setup() {
    if lsmod | grep -qi bluetooth; then
        sudo systemctl enable --now bluetooth.service
    else
        remove_pacman bluez bluez-utils
    fi
}

choose_de(){
    while true; do
        if [ "$mode" = "1" ]; then
            echo "Choose your Desktop Environment:"
            echo "1) GNOME"
            echo "2) KDE Plasma"
            echo "3) Hyprland"
            echo "4) Exit the Script"
            read -p "Enter 1, 2, 3 or 4: " choiceDE
        fi
            
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
    if systemctl is-enabled gdm &> /dev/null || systemctl is-enabled sddm &> /dev/null; then
        echo "A display manager is already enabled. Skipping."
    else
        case $choiceDE in
            1)
                sudo systemctl enable gdm
            2|3)
                sudo systemctl enable ly
                ;;
            *)
                echo "Error: Invalid choiceDE value: $choiceDE. Please set to 1 (GNOME), 2 (KDE), or 3 (Hyprland)."
                exit 1
                ;;
        esac
    fi
    export choiceDE
}

install_basic_features(){
    install_pacman "${base_packages[@]}"
    ibus-daemon -drx
    install_pacman "${audio[@]}"
    systemctl --user enable --now pipewire
    systemctl --user enable --now wireplumber

    if [ "$mode" = "1" ]; then
        echo "Do you want to install video codecs and rendering packages?"
        echo -e "1) Yes \n2) No"
        read -p "Enter 1-2: " choiceREND
        choiceREND=${choiceREND:-1}
    fi

    case $choiceREND in
        1)
            install_pacman "${rendering_packages[@]}"
            ;;
        *)
            ;;
    esac
    
    sudo systemctl enable paccache.timer
    sudo systemctl enable --now cronie.service
    sudo systemctl enable --now ufw.service
}

aur_setup(){
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

    if pacman -Qs chaotic-keyring > /dev/null && pacman -Qs chaotic-mirrorlist > /dev/null && grep -q '^\[chaotic-aur\]' /etc/pacman.conf; then
        echo "Chaotic AUR is already installed and configured."
    else
        echo "Installing chaotic-aur"
        sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
        sudo pacman-key --lsign-key 3056513887B78AEB
        sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
        sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
        sudo cp pacman.conf /etc/pacman.conf
        sudo pacman -Syu --noconfirm
    fi
}

terminal_setup(){
    if [ "$choiceDE" = "3" ]; then
        choiceTPKG=1
    fi

    if [ "$mode" = "1" ]; then
        echo "Do you want some terminal packages?"
        echo "dysk tealdeer btop fastfetch bat fd eza fzf zoxide ripgrep yazi wl-clipboard"
        echo "1) yes"
        echo "2) no"
        read -p "Enter 1-2: " choiceTPKG
    fi

    case $choiceTPKG in
        1)
            install_pacman "${terminal_packages[@]}"
            tldr --update
            cp -r yazi ~/.config/
            ;;
        *)
            ;;
    esac

    if [ "$mode" = "1" ]; then
        echo "choose your terminal text editor"
        echo "1) nano"
        echo "2) vim"
        echo "3) micro"
        echo "4) neovim"
        echo "5) all of them"
        echo "6) skip it (not recommended)"
        read -p "Enter 1-6: " choiceTTE
    fi
    case $choiceTTE in
        1)
            install_pacman "${terminal_text_editors[0]}"
            ;;
        2)
            install_pacman "${terminal_text_editors[1]}"
            ;;
        3)
            install_pacman "${terminal_text_editors[2]}"
            ;;
        4)
            install_pacman "${terminal_text_editors[3]}"
            ;;
        5)
            install_pacman "${terminal_text_editors[@]}"
            ;;
        *)
            ;;
    esac
    case $choiceTPKG in
        1)
            install_yay resvg
            ;;
        *)
            ;;
    esac
    if [ "$mode" = "1" ]; then
        echo "Choose a Terminal"
        terminals=("gnome-console" "ptyxis" "konsole" "alacritty" "ghostty" "kitty" "none")
        for i in "${!terminals[@]}"; do
            echo "$((i+1))) ${terminals[i]}"
        done
        read -p "Enter 1-${#terminals[@]}: " choiceTE
    fi

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

    if [ "$mode" = "1" ]; then
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
    fi
}

install_video_drivers(){
    # Install base drivers
    echo "Installing base video drivers"
    install_pacman "${base_drivers[@]}"

    # Detect GPU(s) using lspci
    if ! command -v lspci &> /dev/null; then
        echo "lspci not found, installing pciutils"
        install_pacman pciutils
    fi

    GPU_INFO=$(lspci | grep -iE "VGA|3D|Display" || true)
    HAS_INTEL=$(echo "$GPU_INFO" | grep -i intel || true)
    HAS_AMD=$(echo "$GPU_INFO" | grep -i amd || true)
    HAS_NVIDIA=$(echo "$GPU_INFO" | grep -i nvidia || true)
    IS_HYBRID=false
    if [[ -n "$HAS_NVIDIA" && ( -n "$HAS_INTEL" || -n "$HAS_AMD" ) ]]; then
        IS_HYBRID=true
        echo "Hybrid GPU system detected (NVIDIA + Intel/AMD)."
    fi

    # --- Intel drivers ---
    if [[ -n "$HAS_INTEL" ]]; then
        echo "Detected Intel GPU, installing Intel drivers..."
        install_pacman "${intel_drivers[@]}"
    fi

    # --- AMD drivers ---
    if [[ -n "$HAS_AMD" ]]; then
        echo "Detected AMD GPU, installing AMD drivers..."
        install_pacman "${amd_drivers[@]}"
    fi
    if [[ -n "$HAS_NVIDIA" ]]; then
        if [ "$mode" = "1" ]; then
            echo "Detected NVIDIA GPU."
            echo "NVIDIA driver options:"
            echo "1) Proprietary: Better performance, closed-source."
            echo "2) Open: Open-source, may have lower performance."
            echo "3) Minimal: Install only basic NVIDIA support."
            read -p "Enter 1, 2, or 3: " choiceNV
        else
            choiceNV=1
        fi
        case $choiceNV in
            1)
                echo "Installing proprietary NVIDIA drivers"
                install_pacman "${nvidia_proprietary[@]}"
                install_pacman "${nvidia_common_utils[@]}"
                nvidia_setup
                ;;
            2)
                echo "Installing open-source NVIDIA drivers"
                install_pacman "${nvidia_open[@]}"
                install_pacman "${nvidia_common_utils[@]}"
                install_pacman xf86-video-nouveau vulkan-nouveau
                nvidia_setup
                ;;
            *)
                echo "Installing minimal NVIDIA support"
                install_pacman "${nvidia_drivers[@]}"
                install_pacman "${nvidia_common_utils[@]}"
                install_pacman xf86-video-nouveau vulkan-nouveau
                nvidia_setup
                ;;
        esac
    else
        echo "No NVIDIA hardware detected. Skipping NVIDIA driver installation."
        sudo cp /grub/grub /etc/default/grub
        choiceNV=3
    fi
    # Check if running in VMware
    if lspci | grep -i vmware &> /dev/null; then
        echo "Detected VMware environment, installing VMware drivers"
        install_pacman "${vmware_drivers[@]}"
    fi

    # Export choiceNV for use in install.sh
    export choiceNV
}

nvidia_setup(){
    sudo mkdir -p /etc/modprobe.d
    echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf > /dev/null
    echo "Wrote /etc/modprobe.d/nvidia.conf (options nvidia_drm modeset=1)."

    if [[ -n "$IS_HYBRID" ]]; then
        if grep -qE '^MODULES=.*\bnvidia\b' /etc/mkinitcpio.conf; then
            echo "NVIDIA modules already present in MODULES, skipping modification."
        else
            sudo sed -i '/^MODULES=/ s/)/ nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
        fi
    fi

    echo "Setting NVIDIA-related environment variables for Wayland..."
    echo -e "GBM_BACKEND=nvidia-drm\n__GLX_VENDOR_LIBRARY_NAME=nvidia\nLIBVA_DRIVER_NAME=nvidia\nNVIDIA_PRIME_RENDER_OFFLOAD=1" | sudo tee -a /etc/environment
    sudo cp grub/grubnvidia /etc/default/grub
    # DE-specific configurations
    if [[ "$choiceDE" == "1" ]]; then
        sudo sed -i '/exit 0/i /usr/bin/prime-run' /etc/gdm/Init/Default
    elif [[ "$choiceDE" == "3" ]]; then
        mkdir -p "${HOME}/.config/hypr"
        # Append env entries only if not already present
        HYPRCONF="${HOME}/.config/hypr/hyprland.conf"
        touch "$HYPRCONF"
        grep -q '^env = GBM_BACKEND,nvidia-drm' "$HYPRCONF" || echo 'env = GBM_BACKEND,nvidia-drm' >> "$HYPRCONF"
        grep -q '^env = LIBVA_DRIVER_NAME,nvidia' "$HYPRCONF" || echo 'env = LIBVA_DRIVER_NAME,nvidia' >> "$HYPRCONF"
        grep -q '^env = __GLX_VENDOR_LIBRARY_NAME,nvidia' "$HYPRCONF" || echo 'env = __GLX_VENDOR_LIBRARY_NAME,nvidia' >> "$HYPRCONF"
        # WLR_NO_HARDWARE_CURSORS=1 is sometimes recommended for NVIDIA+Wayland (Hyprland)
        grep -q '^env = WLR_NO_HARDWARE_CURSORS,1' "$HYPRCONF" || echo 'env = WLR_NO_HARDWARE_CURSORS,1' >> "$HYPRCONF"
    fi
    sudo mkinitcpio -P
}

gaming_setup(){
    if [ "$mode" = "1" ]; then
        echo "Do you want to install gaming packages and apply shader booster (credits to psygreg)?"
        echo "1) Yes"
        echo "2) No"
        read -p "Enter 1-2: " choiceGM
    fi

    case $choiceGM in
        1)
            echo "vm.max_map_count = 2147483642" | sudo tee /etc/sysctl.d/80-gamecompatibility.conf
            wget https://github.com/psygreg/shader-booster/releases/latest/download/patcher.sh
            chmod +x patcher.sh
            ./patcher.sh
            rm patcher.sh
            case $choiceNV in
                1)
                    install_yay "${gaming_nvidia_proprietary[@]}"
                    echo "Finished installing gaming packages"
                    ;;
                *)
                    install_yay "${gaming[@]}"
                    echo "Finished installing gaming packages"
                    ;;
            sudo usermod -aG gamemode $USER
            sudo mkdir /usr/share/gamemode/
            sudo cp gamemode/gamemode.ini /usr/share/gamemode/.
            systemctl --user enable --now gamemoded
            esac
            ;;
        *)
            echo "Skipped gaming packages"
            ;;
    esac

    if [ "$mode" = "1" ]; then
        echo "Do you want to install video game emulators?"
        echo "1) Yes, via flatpak"
        echo "2) Yes, via AUR packages"
        echo "3) Yes, mix them up for better packages and updates (recommended)"
        echo "4) No"
        read -p "Enter 1-4: " choiceEM
    fi
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
            install_flatpak "${emulators_mixed_flatpak[@]}"
            ;;
        *)
            echo "Skipped Emulators"
            ;;
    esac
}

zen_kernel_setup(){
    if [ "$mode" = "1" ]; then
        echo "Do you want to install zen kernel? It will remove the basic kernel because the boot partition needs to be at least 2GB to use both"
        echo -e "1) Yes \n2) No"
        read -p "Enter 1-2: " choiceZEN
        choiceZEN=${choiceZEN:-2}
        case $choiceZEN in
            1)
                install_pacman linux-zen linux-zen-headers
                remove_pacman linux linux-headers
                ;;
            *)
                ;;
        esac
    fi
}

extra_setup(){
    echo "Installing Fonts for different Languages and microsoft fonts"
    install_pacman "${font_packages[@]}"
    echo "Finished installing fonts"

    if [ "$mode" = "1" ]; then
        echo "Do you wish to add some extra packages? (Utility, editors, etc)"
        echo "1) Yes"
        echo "2) No"
        read -p "Enter 1-2: " choiceAUR
    fi
    case $choiceAUR in
        1)
            install_yay "${extra[@]}"
            ;;
        *)
            ;;
    esac

    if [ "$mode" = "1" ]; then
        echo "Select a browser"
        browsers=("firefox" "brave" "zen-browser-bin" "vivaldi" "chrome" "floorp" "librewolf" "chromium" "firedragon" "waterfox" "none")
        for i in "${!browsers[@]}"; do
            echo "$((i+1))) ${browsers[i]}"
        done
        read -p "Enter 1-${#browsers[@]}: " choiceBR
    fi

    if [[ "${browsers[choiceBR-1]}" != "none" ]]; then
        if [[ "${browsers[choiceBR-1]}" == "firefox" || "${browsers[choiceBR-1]}" == "vivaldi" ]]; then
            install_pacman "${browsers[choiceBR-1]}"
        else
            install_yay "${browsers[choiceBR-1]}"
        fi
        echo "${browsers[choiceBR-1]} installed."
    fi

    case $choiceDE in
        1)
            install_yay "${gnome_extra[@]}"
            gsettings set org.gnome.mutter check-alive-timeout 0
            ;;
        *)
            ;;
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
}

grup_setup(){
    if pacman -Qs grub > /dev/null; then
        install_yay "${grub_packages[@]}"
    fi

    sudo systemctl enable --now grub-btrfsd
    sudo grub-mkconfig
    sudo update-grub
}