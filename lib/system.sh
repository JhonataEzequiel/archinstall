#!/bin/bash
# system.sh — Prerequisites, mirrors, preset selection, DE, base features, AUR

# ---------------------------------------------------------------------------
# Prerequisites & mirrors
# ---------------------------------------------------------------------------

check_prerequisites() {
    if [[ ! -f /etc/arch-release ]]; then
        echo "Error: This script is designed for Arch Linux only."
        exit 1
    fi
    install_pacman git
    for cmd in pacman sudo; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: $cmd is not installed."
            exit 1
        fi
    done
}

update_mirrors() {
    echo "Updating mirrorlist for faster downloads..."
    if ! command -v reflector &>/dev/null; then
        echo "Installing reflector..."
        install_pacman reflector
    fi

    # Detect country via IP for geographically closer mirrors.
    # Falls back to no --country flag (world-wide) if the lookup fails.
    local country country_arg=""
    install_pacman curl
    country=$(curl -sf --max-time 5 "https://ipapi.co/country" 2>/dev/null || true)
    if [[ -n "$country" && "$country" =~ ^[A-Z]{2}$ ]]; then
        echo "Detected country: ${country} — filtering mirrors accordingly."
        country_arg="--country ${country}"
    else
        echo "Could not detect country. Using worldwide mirror list."
    fi

    sudo reflector $country_arg --sort rate --latest 20 --protocol https --save /etc/pacman.d/mirrorlist
    echo "Mirrorlist updated."
    sudo pacman -Syy --noconfirm
}

# ---------------------------------------------------------------------------
# Mode / preset selection
# ---------------------------------------------------------------------------

set_variables() {
    echo "Choose your installation method:"
    echo "1) Manual (choose everything yourself)"
    echo "2) GNOME + gaming"
    echo "3) GNOME, no gaming"
    echo "4) KDE Plasma + gaming"
    echo "5) KDE Plasma, no gaming"
    echo "6) Hyprland + gaming"
    echo "7) Hyprland, no gaming"
    echo "8) Exit"
    read -p "Enter 1-8: " mode

    if [[ ! "$mode" =~ ^[1-8]$ ]]; then
        echo "Invalid input."
        exit 1
    fi

    [[ "$mode" == "8" ]] && exit 0

    # Defaults for every preset (including manual mode — guards against set -u crashes)
    choiceTE=6        # terminal emulator: kitty (default for Hyprland)
    choiceTPKG=1      # terminal packages: yes
    choiceTTE=1       # terminal text editor: nano
    choiceAUR=1       # extra AUR packages: yes
    choiceSHELL=1     # shell: bash
    choiceSS=1        # starship / shell customization: yes
    choiceBL=4        # bootloader: limine (safe default)
    choiceGRUB=7      # grub theme: none
    choiceCAO=2       # cachyos: no
    choiceWI=2        # wine: no
    choicePRIN=2      # printer: no
    choiceBAR=1       # bar: waybar
    choiceLAUNCHER=1  # launcher: wofi
    choiceSSTOOL=1    # screenshot tool: grimblast
    choiceGM=2        # gaming: no
    choiceZEN=2       # zen kernel: no

    case $mode in
        2) choiceDE=1; choiceGM=1; choiceTE=5 ;;
        3) choiceDE=1; choiceGM=2; choiceTE=5 ;;
        4) choiceDE=2; choiceGM=1; choiceTE=3 ;;
        5) choiceDE=2; choiceGM=2; choiceTE=3 ;;
        6) choiceDE=3; choiceGM=1; choiceTE=6 ;;
        7) choiceDE=3; choiceGM=2; choiceTE=6 ;;
    esac

    export mode choiceDE choiceTE choiceGM choiceTPKG choiceTTE \
           choiceAUR choiceSHELL choiceSS choiceBL choiceGRUB choiceCAO \
           choiceWI choicePRIN choiceBAR choiceLAUNCHER choiceSSTOOL choiceZEN
}

# ---------------------------------------------------------------------------
# Desktop Environment
# ---------------------------------------------------------------------------

choose_de() {
    while true; do
        if [[ "$mode" == "1" ]]; then
            echo "Choose your Desktop Environment:"
            echo "1) GNOME"
            echo "2) KDE Plasma"
            echo "3) Hyprland  [default]"
            echo "4) Exit"
            read -p "Enter 1-4 [3]: " choiceDE
            choiceDE=${choiceDE:-3}
        fi

        case $choiceDE in
            1)
                echo "Installing GNOME..."
                install_pacman "${gnome_packages[@]}" && break || { echo "GNOME installation failed."; exit 1; }
                ;;
            2)
                echo "Installing KDE Plasma..."
                install_pacman "${kde_packages[@]}" && break || { echo "KDE installation failed."; exit 1; }
                ;;
            3)
                echo "Installing Hyprland base packages..."
                remove_pacman pipewire-jack 2>/dev/null || true
                install_pacman "${hyprland_packages[@]}" && {
                    sudo systemctl enable polkit
                    break
                } || { echo "Hyprland installation failed."; exit 1; }
                ;;
            4)
                echo "Exiting."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please enter 1, 2, 3, or 4."
                ;;
        esac
    done

    echo "Configuring display manager..."

    if systemctl is-enabled gdm &>/dev/null || \
       systemctl is-enabled plasma-login-manager &>/dev/null || \
       systemctl is-enabled ly &>/dev/null; then
        echo "A display manager is already enabled. Skipping."
    else
        case $choiceDE in
            1) sudo systemctl enable gdm                   && echo "Enabled GDM." ;;
            2) sudo systemctl enable plasma-login-manager  && echo "Enabled Plasma Login Manager." ;;
            3) sudo systemctl enable ly                    && echo "Enabled LY." ;;
        esac
    fi

    export choiceDE
}

# ---------------------------------------------------------------------------
# Base system features
# ---------------------------------------------------------------------------

bluetooth_setup() {
    if lsmod | grep -qi bluetooth; then
        sudo systemctl enable --now bluetooth.service
    else
        remove_pacman bluez bluez-utils 2>/dev/null || true
    fi
}

printer_support() {
    case $choicePRIN in
        1)
            install_pacman "${printer[@]}"
            sudo systemctl enable --now cups.socket
            sudo systemctl enable --now avahi-daemon.service
            sudo sed -i.bak '/^hosts:/c\hosts: files mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns myhostname' /etc/nsswitch.conf
            sudo usermod -aG lp,sys,wheel "$USER"
            ;;
    esac
}

install_basic_features() {
    install_pacman "${base_packages[@]}"
    _ibus_setup

    install_pacman "${audio[@]}"
    systemctl --user enable --now pipewire
    systemctl --user enable --now wireplumber

    install_pacman "${rendering_packages[@]}"

    sudo systemctl enable paccache.timer
    sudo systemctl enable --now cronie.service
    sudo systemctl enable --now ufw.service

    bluetooth_setup

    if [[ "$mode" == "1" ]]; then
        echo "Do you want to install printer support?"
        echo "1) Yes  2) No"
        read -p "Enter 1-2: " choicePRIN
    fi
    printer_support
}

# ---------------------------------------------------------------------------
# IBus — input method for accented characters in all applications
# (fixes first accented uppercase char being dropped in Firefox/Electron)
# ---------------------------------------------------------------------------

_ibus_setup() {
    # Environment variables must be set before the graphical session starts.
    # Without GTK_IM_MODULE and XMODIFIERS, GTK/Qt apps use XIM instead of
    # ibus, causing the first composed character (e.g. "É") to be swallowed.
    local ENV_FILE="/etc/environment"
    local env_vars=(
        "GTK_IM_MODULE=ibus"
        "QT_IM_MODULE=ibus"
        "XMODIFIERS=@im=ibus"
    )
    for var in "${env_vars[@]}"; do
        grep -qF "$var" "$ENV_FILE" || echo "$var" | sudo tee -a "$ENV_FILE" > /dev/null
    done
    echo "IBus environment variables written to ${ENV_FILE}."

    # Autostart the ibus daemon depending on the chosen DE:
    #   GNOME  — ibus is integrated; gnome-session starts it automatically.
    #            We only need to ensure ibus-daemon is installed and the
    #            gsettings input-sources key includes ibus.
    #   KDE    — autostart via a .desktop entry in ~/.config/autostart/
    #   Hyprland — exec-once in hyprland.conf (written here, before dotfiles
    #              are copied so _hyprland_copy_dotfiles can override if needed)
    case $choiceDE in
        1)
            # GNOME handles ibus natively — nothing extra needed beyond the env vars.
            echo "GNOME detected — ibus will be started automatically by the session."
            ;;
        2)
            # KDE Plasma: drop an autostart .desktop
            local autostart_dir="$HOME/.config/autostart"
            mkdir -p "$autostart_dir"
            cat > "$autostart_dir/ibus-daemon.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=IBus Daemon
Exec=ibus-daemon -drx
X-KDE-AutostartScript=true
EOF
            echo "IBus autostart entry created for KDE Plasma."
            ;;
        3)
            # Hyprland: add exec-once — _hyprland_copy_dotfiles runs after this
            # and will respect whatever is already in the conf.
            local HYPRCONF="$HOME/.config/hypr/hyprland.conf"
            mkdir -p "$HOME/.config/hypr"
            grep -q 'exec-once = ibus-daemon' "$HYPRCONF" 2>/dev/null || \
                echo 'exec-once = ibus-daemon -drx' >> "$HYPRCONF"
            echo "IBus exec-once added to hyprland.conf."
            ;;
    esac
}

# ---------------------------------------------------------------------------
# AUR helper (yay) + Chaotic AUR
# ---------------------------------------------------------------------------

aur_setup() {
    if ! command -v yay &>/dev/null; then
        echo "Installing yay..."
        install_pacman base-devel
        git clone https://aur.archlinux.org/yay.git
        (cd yay && makepkg -si --noconfirm)
        rm -rf yay
    else
        echo "yay is already installed."
    fi

    if pacman -Qs chaotic-keyring &>/dev/null && \
       pacman -Qs chaotic-mirrorlist &>/dev/null && \
       grep -q '^\[chaotic-aur\]' /etc/pacman.conf; then
        echo "Chaotic AUR already configured."
    else
        echo "Setting up Chaotic AUR..."
        sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
        sudo pacman-key --lsign-key 3056513887B78AEB
        sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
        sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
        sudo tee -a /etc/pacman.conf > /dev/null << 'EOF'

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
        sudo pacman -Syu --noconfirm
    fi
}
