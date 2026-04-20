#!/bin/bash
# software.sh — Wine, CachyOS, gaming, Zen kernel, extra packages & browser

# ---------------------------------------------------------------------------
# Wine
# ---------------------------------------------------------------------------

wine_setup() {
    if [[ "$mode" == "1" ]]; then
        echo "Install Wine and its dependencies?"
        echo "1) Yes  2) No"
        read -p "Enter 1-2: " choiceWI
    fi
    [[ "$choiceWI" == "1" ]] && install_yay "${wine_and_dependencies[@]}"
}

# ---------------------------------------------------------------------------
# CachyOS kernel & repos
# ---------------------------------------------------------------------------

cachyos_setup() {
    if [[ "$mode" == "1" ]]; then
        echo "Install CachyOS kernel and optimizations?"
        echo "1) Yes  2) No"
        read -p "Enter 1-2: " choiceCAO
    fi

    if [[ "$choiceCAO" == "1" ]]; then
        curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz
        tar xvf cachyos-repo.tar.xz && cd cachyos-repo
        yes | sudo ./cachyos-repo.sh
        cd .. && rm -rf cachyos-repo cachyos-repo.tar.xz
        install_pacman "${cachyos_packages[@]}"
        remove_pacman linux linux-headers
    fi
}

# ---------------------------------------------------------------------------
# Gaming
# ---------------------------------------------------------------------------

gaming_setup() {
    if [[ "$mode" == "1" ]]; then
        echo "Install gaming packages and Shader Booster (credits: psygreg)?"
        echo "1) Yes  2) No"
        read -p "Enter 1-2: " choiceGM
    fi

    if [[ "$choiceGM" == "1" ]]; then
        echo "vm.max_map_count = 2147483642" | sudo tee /etc/sysctl.d/80-gamecompatibility.conf
        wget https://github.com/psygreg/shader-booster/releases/latest/download/patcher.sh
        chmod +x patcher.sh
        sed -i 's|whiptail --title "Shader Booster" --msgbox "No valid shell found." 8 78|echo "Shader Booster: No valid shell found."|g' patcher.sh
        sed -i 's|whiptail --title "Shader Booster" --msgbox "Success! Reboot to apply." 8 78|echo "Shader Booster: Success! Reboot to apply."|g' patcher.sh
        sed -i 's|whiptail --title "Shader Booster" --msgbox "No compatible GPU found to patch." 8 78|echo "Shader Booster: No compatible GPU found to patch."|g' patcher.sh
        sed -i 's|whiptail --title "Shader Booster" --msgbox "System already patched." 8 78|echo "Shader Booster: System already patched."|g' patcher.sh
        ./patcher.sh && rm patcher.sh
        install_yay "${gaming[@]}"
        sudo usermod -aG gamemode "$USER"
        sudo mkdir -p /usr/share/gamemode/
        sudo cp gamemode/gamemode.ini /usr/share/gamemode/
        systemctl --user enable --now gamemoded
        echo "Gaming packages installed."
    else
        echo "Skipped gaming packages."
    fi

    if [[ "$mode" == "1" ]]; then
        echo "Install video game emulators?"
        echo "1) Flatpak (recommended, easy updates)"
        echo "2) AUR only"
        echo "3) Mix — best of both (recommended)"
        echo "4) No"
        read -p "Enter 1-4: " choiceEM
    fi

    case $choiceEM in
        1) install_flatpak "${emulators_flatpak_complete[@]}" ;;
        2) install_yay "${emulators_aur[@]}" ;;
        3) install_yay "${emulators_mixed_aur[@]}" && install_flatpak "${emulators_mixed_flatpak[@]}" ;;
        *) echo "Skipped emulators." ;;
    esac
}

# ---------------------------------------------------------------------------
# Zen kernel
# ---------------------------------------------------------------------------

zen_kernel_setup() {
    if [[ "$mode" == "1" ]]; then
        echo "Install linux-zen kernel? (requires ≥2 GB on /boot if keeping default kernel)"
        echo "1) Yes  2) No"
        read -p "Enter 1-2: " choiceZEN
        choiceZEN=${choiceZEN:-2}
        [[ "$choiceZEN" == "1" ]] && install_pacman linux-zen linux-zen-headers
    fi
}

# ---------------------------------------------------------------------------
# Extra packages, fonts, browser
# ---------------------------------------------------------------------------

extra_setup() {
    echo "Installing fonts..."
    install_pacman "${font_packages[@]}"

    if [[ "$mode" == "1" ]]; then
        echo "Install extra packages? (editors, utilities, media apps, etc.)"
        echo "1) Yes  2) No"
        read -p "Enter 1-2: " choiceAUR
    fi

    if [[ "$choiceAUR" == "1" ]]; then
        install_yay "${extra[@]}"
        if [[ "$choiceDE" == "1" ]]; then
            install_yay "${gnome_extra[@]}"
            remove_yay gnome-software
            gsettings set org.gnome.mutter check-alive-timeout 0
            sudo ./gnome_logo.sh
        fi
    fi

    if [[ "$mode" == "1" ]]; then
        local browsers=("firefox" "brave-bin" "zen-browser-bin" "vivaldi" "google-chrome" "floorp" "librewolf" "chromium" "firedragon" "waterfox-bin" "qutebrowser" "none")
        echo "Select a browser:"
        for i in "${!browsers[@]}"; do
            echo "$((i+1))) ${browsers[i]}"
        done
        read -p "Enter 1-${#browsers[@]}: " choiceBR
        local browser="${browsers[$((choiceBR-1))]}"
        if [[ -n "$browser" && "$browser" != "none" ]]; then
            install_yay "$browser"
            echo "$browser installed."
        fi
    fi
}
