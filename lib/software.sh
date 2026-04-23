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


gaming_setup() {
    if [[ "$mode" == "1" ]]; then
        echo "Install gaming packages? (Steam, Proton, MangoHud...)"
        echo "1) Yes  2) No"
        read -p "Enter 1-2: " choiceGM
    fi

    if [[ "$choiceGM" == "1" ]]; then
        echo "vm.max_map_count = 2147483642" | sudo tee /etc/sysctl.d/80-gamecompatibility.conf
        install_yay "${gaming[@]}"
        echo "Gaming packages installed."
    else
        echo "Skipped gaming packages."
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
