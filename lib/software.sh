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

    if [[ "$choiceWI" == "1" ]]; then
        install_yay "${wine_and_dependencies[@]}"
    else
        echo "Skipped Wine."
    fi
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
        tar xvf cachyos-repo.tar.xz
        (cd cachyos-repo && yes | sudo ./cachyos-repo.sh)
        rm -rf cachyos-repo cachyos-repo.tar.xz
        if install_pacman "${cachyos_packages[@]}"; then
            remove_pacman linux linux-headers
        else
            echo "ERROR: linux-cachyos installation failed. Keeping default kernel."
            return 1
        fi
    else
        echo "Skipped CachyOS."
    fi
}

# ---------------------------------------------------------------------------
# Gaming
# ---------------------------------------------------------------------------

gaming_setup() {
    if [[ "$mode" == "1" ]]; then
        echo "Install gaming packages? (Steam, Proton, MangoHud, gamemode...)"
        echo "1) Yes  2) No"
        read -p "Enter 1-2: " choiceGM
    fi

    if [[ "$choiceGM" == "1" ]]; then
        echo "vm.max_map_count = 2147483642" | sudo tee /etc/sysctl.d/80-gamecompatibility.conf
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

        if [[ "$choiceZEN" == "1" ]]; then
            install_pacman linux-zen linux-zen-headers
        else
            echo "Skipped Zen kernel."
        fi
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
    else
        echo "Skipped extra packages."
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
        else
            echo "Skipped browser installation."
        fi
    fi
}
