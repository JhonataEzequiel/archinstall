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
    echo "Hyprland is currently unavailable in automatic mode because I'm still working on it"
    read -p "Enter 1-6: " mode

    if [[ ! "$mode" =~ ^[1-6]$ ]]; then
        echo "Invalid input. Please enter a number between 1 and 6."
        exit 1
    fi

    choiceTE=1
    choiceTPKG=1
    choiceTTE=1
    choiceAUR=1
    choiceBR=3
    choiceSS=1
    choiceGRUB=4

    case $mode in
        2)
            choiceDE=1
            choiceGM=1
            choiceEM=3
            choiceTE=5
            ;;
        3)
            choiceDE=1
            choiceGM=2
            choiceEM=4
            choiceTE=5
            ;;
        4)
            choiceDE=2
            choiceGM=1
            choiceEM=3
            choiceTE=3
            ;;
        5)
            choiceDE=2
            choiceGM=2
            choiceEM=4
            choiceTE=3
            ;;
        6)
            exit 1
            ;;
        *)
            ;;
    esac
    export mode choiceDE choiceTE choiceGM choiceEM choiceTPKG choiceTTE choiceAUR choiceBR choiceSS choiceGRUB
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
                ;;
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

    install_pacman "${rendering_packages[@]}"
    
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
        makepkg -si --noconfirm
        cd ..
        rm -rf yay
    fi

    if [[ ! -f /etc/pacman.conf ]]; then
        touch /etc/pacman.conf
    fi

    if pacman -Qs chaotic-keyring > /dev/null && pacman -Qs chaotic-mirrorlist > /dev/null && grep -q '^\[chaotic-aur\]' /etc/pacman.conf; then
        echo "Chaotic AUR is already installed and configured."
    else
        echo "Installing chaotic-aur"
        sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
        sudo pacman-key --lsign-key 3056513887B78AEB
        sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'  # Add --noconfirm
        sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'  # Add --noconfirm
        sudo cp pacman.conf /etc/pacman.conf
        sudo pacman -Syu --noconfirm
    fi
}

terminal_text_editors_setup(){
    if [ "$mode" = "1" ]; then
        echo "Choose one or more Terminal text editors (enter numbers separated by spaces, e.g., '1 3 4')"
        terminal_text_editors=("nano" "vim" "micro" "neovim" "none")
        for i in "${!terminal_text_editors[@]}"; do
            echo "$((i+1))) ${terminal_text_editors[i]}"
        done
        read -p "Enter numbers (1-${#terminal_text_editors[@]}): " -a choicesTE  # Read multiple inputs into an array

        # Check if "none" (option 5) is selected
        none_selected=false
        for choice in "${choicesTE[@]}"; do
            if [ "$choice" -eq 5 ]; then
                none_selected=true
                break
            fi
        done

        if $none_selected; then
            echo "Skipping text editor installation (none selected)."
        else
            # Process each selected editor
            for choice in "${choicesTE[@]}"; do
                # Validate input
                if [ "$choice" -ge 1 ] && [ "$choice" -le "${#terminal_text_editors[@]}" ]; then
                    editor="${terminal_text_editors[$((choice-1))]}"
                    if [ "$editor" != "none" ]; then
                        echo "Installing $editor..."
                        sudo pacman -S --noconfirm "$editor"  # Install using pacman
                    fi
                else
                    echo "Invalid choice: $choice. Skipping."
                fi
            done
        fi
    else
        case $choiceTTE in
            1)
                install_pacman nano
                ;;
            2)
                install_pacman vim
                ;;
            3)
                install_pacman micro
                ;;
            4)
                install_pacman neovim
                ;;
            *)
                ;;
        esac
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
                    if [[ "$terminal_choice" == "ghostty" && "$mode" = "1" ]]; then
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
                    elif [[ "$terminal_choice" == "ghostty" && "$mode" !- "1" ]]; then
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
                curl -sS https://starship.rs/install.sh | sh -- --y
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
    else
        case $choiceSS in
            1)
                curl -sS https://starship.rs/install.sh | sh -- --y
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
    install_pacman "${base_drivers[@]}"

    # Detect GPU(s) using lspci
    if ! command -v lspci &> /dev/null; then
        install_pacman pciutils
    fi

    GPU_INFO=$(lspci | grep -iE "VGA|3D|Display" || true)
    HAS_INTEL=$(echo "$GPU_INFO" | grep -i intel || true)
    HAS_AMD=$(echo "$GPU_INFO" | grep -i amd || true)
    HAS_NVIDIA=$(echo "$GPU_INFO" | grep -i nvidia || true)
    IS_HYBRID=false
    if [[ -n "$HAS_NVIDIA" && ( -n "$HAS_INTEL" || -n "$HAS_AMD" ) ]]; then
        IS_HYBRID=true
    fi

    # --- Intel drivers ---
    if [[ -n "$HAS_INTEL" ]]; then
        install_pacman "${intel_drivers[@]}"
    fi

    # --- AMD drivers ---
    if [[ -n "$HAS_AMD" ]]; then
        install_pacman "${amd_drivers[@]}"
    fi
    if [[ -n "$HAS_NVIDIA" ]]; then
        if [ "$mode" = "1" ]; then
            echo "Detected NVIDIA GPU."
            echo "NVIDIA driver options:"
            echo "1) Proprietary: Better performance, closed-source."
            echo "2) Open: Open-source, may have lower performance."
            read -p "Enter 1 or 2: " choiceNV
        else
            choiceNV=1
        fi
        case $choiceNV in
            1)
                install_pacman "${nvidia_proprietary[@]}"
                install_pacman "${nvidia_common_utils[@]}"
                ;;
            2)
                install_pacman "${nvidia_open[@]}"
                install_pacman "${nvidia_common_utils[@]}"
                ;;
            *)
                ;;
        esac
        nvidia_setup
    else
        sudo cp grub/grub /etc/default/grub
        choiceNV=3
    fi
    # Check if running in VMware
    if lspci | grep -i vmware &> /dev/null; then
        install_pacman "${vmware_drivers[@]}"
    fi

    # Export choiceNV for use in install.sh
    export choiceNV
}

nvidia_setup(){
    sudo mkdir -p /etc/modprobe.d
    echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf > /dev/null

    if [[ -n "$IS_HYBRID" ]]; then
        if grep -qE '^MODULES=.*\bnvidia\b' /etc/mkinitcpio.conf; then
            echo "Skipping Hybrid Config"
        else
            sudo sed -i '/^MODULES=/ s/)/ nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
        fi
    fi

    echo -e "GBM_BACKEND=nvidia-drm\n__GLX_VENDOR_LIBRARY_NAME=nvidia\nLIBVA_DRIVER_NAME=nvidia\nNVIDIA_PRIME_RENDER_OFFLOAD=1" | sudo tee -a /etc/environment
    sudo cp grub/grubnvidia /etc/default/grub

    sudo nvidia-xconfig --cool-bits=28

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
            sed -i 's|whiptail --title "Shader Booster" --msgbox "No valid shell found." 8 78|echo "Shader Booster: No valid shell found."|g' patcher.sh
            sed -i 's|whiptail --title "Shader Booster" --msgbox "Success! Reboot to apply." 8 78|echo "Shader Booster: Success! Reboot to apply."|g' patcher.sh
            sed -i 's|whiptail --title "Shader Booster" --msgbox "No compatible GPU found to patch." 8 78|echo "Shader Booster: No compatible GPU found to patch."|g' patcher.sh
            sed -i 's|whiptail --title "Shader Booster" --msgbox "System already patched." 8 78|echo "Shader Booster: System already patched."|g' patcher.sh
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
            esac
            sudo usermod -aG gamemode $USER
            sudo mkdir /usr/share/gamemode/
            choiceGAMEMODE="2"
            if [[ "$mode" == "1" ]]; then
                echo "Do you want my gamemode.ini config? Suitable for a laptop with an intel igpu and a nvidia gpu"
                echo "1) Yes\n2)No"
                read -p "Enter 1-2: " choiceGAMEMODE
            fi
            case $choiceGAMEMODE in
                1)
                    sudo cp -r gamemode/gamemode_my_settings.ini /usr/share/gamemode/gamemode.ini
                    ;;
                *)
                    ;;
            esac 
            sudo cp gamemode/gamemode.ini /usr/share/gamemode/.
            systemctl --user enable --now gamemoded
            case $choiceDE in
                1)
                    cd gamemode/ && sed -i '$ s/^#//' gamemode.ini && sed -i "$(wc -l < gamemode.ini | xargs -I {} expr {} - 1) s/^#//" gamemode.ini && cd ..
                    ;;
                *)
                    ;;
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
        echo "Do you want to install zen kernel? (REQUIRES AT LEAST 2GB FOR THE BOOT PARTITION, IF YOU DON'T WANT TO REMOVE THE NORMAL KERNEL FIRST)"
        echo -e "1) Yes \n2) No"
        read -p "Enter 1-2: " choiceZEN
        choiceZEN=${choiceZEN:-2}
        case $choiceZEN in
            1)
                install_pacman linux-zen linux-zen-headers
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
            case $choiceDE in
                1)
                    install_yay "${gnome_extra[@]}" && remove_yay gnome-software
                    gsettings set org.gnome.mutter check-alive-timeout 0
                    ;;
                *)
                    ;;
            esac
            ;;
        *)
            ;;
    esac

    if [ "$mode" = "1" ]; then
        echo "Select a browser"
        browsers=("firefox" "brave" "zen-browser-bin" "vivaldi" "chrome" "floorp" "librewolf" "chromium" "firedragon" "waterfox" "qutebrowser" "none")
        for i in "${!browsers[@]}"; do
            echo "$((i+1))) ${browsers[i]}"
        done
        read -p "Enter 1-${#browsers[@]}: " choiceBR
    fi

    if [[ "${browsers[choiceBR-1]}" != "none" ]]; then
        install_yay "${browsers[choiceBR-1]}"
        echo "${browsers[choiceBR-1]} installed."
    fi
}

hyprland_setup(){
    case $choiceDE in
        3)
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

grub_setup(){
    # Check for other bootloaders
    other_bootloaders=()

    if pacman -Qs systemd-boot > /dev/null; then
        other_bootloaders+=("systemd-boot")
    fi

    if pacman -Qs limine > /dev/null; then
        other_bootloaders+=("limine")
    fi

    if pacman -Qs grub > /dev/null; then
        echo "GRUB is already installed. Updating GRUB packages..."
        install_yay "${grub_packages[@]}"
    else
        echo "Installing GRUB and related packages..."
        install_yay "${grub_packages[@]}"
        
        # Install GRUB to the EFI System Partition (ESP)
        sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
        
        # Enable Btrfs snapshot support for GRUB
        sudo systemctl enable --now grub-btrfsd
    fi

    # Generate GRUB configuration
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    sudo update-grub

    # Set GRUB as the default boot entry
    if command -v efibootmgr >/dev/null; then
        grub_entry=$(efibootmgr | grep -i "GRUB" | head -n 1 | awk '{print $1}' | sed 's/Boot//;s/*//')
        if [ -n "$grub_entry" ]; then
            echo "Setting GRUB as default boot entry..."
            sudo efibootmgr -o "$grub_entry"
    fi

    # Remove other bootloaders if present
    if [ ${#other_bootloaders[@]} -gt 0 ]; then
        for bootloader in "${other_bootloaders[@]}"; do
            case "$bootloader" in
                "systemd-boot")
                    sudo bootctl remove
                    remove_pacman systemd-boot
                    sudo rm -rf /boot/loader /boot/loader.efi
                    ;;
                "limine")
                    # Limine doesn't have a native uninstall command; remove manually
                    limine_entry=$(efibootmgr | grep -i "Limine" | head -n 1 | awk '{print $1}' | sed 's/Boot//;s/*//')
                    if [ -n "$limine_entry" ]; then
                        sudo efibootmgr -B -b "$limine_entry"
                    fi
                    sudo rm -rf /boot/limine /boot/limine.cfg
                    remove_yay limine
                    ;;
            esac
        done
    fi
}

grub_theme_selection(){
    if [[ "$mode" = "1" ]]; then
        echo "Want theme do you want for grub?"
        echo "1) Lain Theme (Made for 1080p displays) (credits: https://github.com/uiriansan)"
        echo "2) Tela (credits: https://github.com/vinceliuice/grub2-themes.git)"
        echo "3) Stylish (credits: https://github.com/vinceliuice/grub2-themes.git)"
        echo "4) Vimix (credits: https://github.com/vinceliuice/grub2-themes.git)"
        echo "5) WhiteSur (credits: https://github.com/vinceliuice/grub2-themes.git)"
        echo "6) Fallout (credits: https://github.com/shvchk/fallout-grub-theme)"
        echo "7) No"
        read -p "Enter 1-5: " choiceGRUB
    fi
    case $choiceGRUB in
        1)
            git clone --depth=1 https://github.com/uiriansan/LainGrubTheme && cd LainGrubTheme && ./install.sh && ./patch_entries.sh
            cd ..
            rm -rf LainGrubTheme
            ;;
        2|3|4|5)
            git clone https://github.com/vinceliuice/grub2-themes.git
            cd grub2-themes
            chmod +x install.sh
            RESOLUTION="1080p"
            if [[ "$mode" = "1" ]]; then
                echo "What's your display resolution?"
                resolution=("1080p" "2k" "4k" "ultrawide" "ultrawide2k" "Custom" "none")
                for i in "${!resolution[@]}"; do
                    echo "$((i+1))) ${resolution[i]}"
                done
                read -p "Enter 1-${#resolution[@]} (or press Enter for 1080p): " resolution_choice
                if [[ -n "$resolution_choice" && "$resolution_choice" -ge 1 && "$resolution_choice" -le "${#resolution[@]}" ]]; then
                    RESOLUTION="${resolution[$((resolution_choice-1))]}"
                fi
            fi
            case $choiceGRUB in
                2)
                    sudo ./install.sh -t tela -s "$RESOLUTION"
                    ;;
                3)
                    sudo ./install.sh -t stylish -s "$RESOLUTION"
                    ;;
                4)
                    sudo ./install.sh -t vimix -s "$RESOLUTION"
                    ;;
                5)
                    sudo ./install.sh -t whitesur -s "$RESOLUTION"
                    ;;
            esac
            cd ..
            rm -rf grub2-themes
            ;;
        6)
            git clone https://github.com/shvchk/fallout-grub-theme.git
            cd fallout-grub-theme
            chmod +x install.sh
            ./install.sh
            cd ..
            rm -rf fallout-grub-theme
            ;;
        *)
            ;;
    esac
}