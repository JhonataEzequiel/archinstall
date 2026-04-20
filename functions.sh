#!/bin/bash

source packages.sh

# ---------------------------------------------------------------------------
# Prerequisites & mirrors
# ---------------------------------------------------------------------------

check_prerequisites() {
    if [[ ! -f /etc/arch-release ]]; then
        echo "Error: This script is designed for Arch Linux only."
        exit 1
    fi

    for cmd in pacman git sudo; do
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
    sudo reflector --sort rate --latest 20 --protocol https --save /etc/pacman.d/mirrorlist
    echo "Mirrorlist updated."
    sudo pacman -Syy --noconfirm
}

# ---------------------------------------------------------------------------
# Mode / preset selection
# ---------------------------------------------------------------------------

set_variables() {
    echo "Choose your installation method:"
    echo "1) Manual (choose everything yourself)"
    echo "2) GNOME + gaming + emulators"
    echo "3) GNOME, no gaming / emulators"
    echo "4) KDE Plasma + gaming + emulators"
    echo "5) KDE Plasma, no gaming / emulators"
    echo "6) Exit"
    read -p "Enter 1-6: " mode

    if [[ ! "$mode" =~ ^[1-6]$ ]]; then
        echo "Invalid input."
        exit 1
    fi

    [[ "$mode" == "6" ]] && exit 0

    # Defaults for every preset
    choiceTE=1      # terminal emulator (gnome-console)
    choiceTPKG=1    # terminal packages: yes
    choiceTTE=1     # terminal text editor: nano
    choiceAUR=1     # extra AUR packages: yes
    choiceSHELL=1   # shell: bash
    choiceSS=1      # starship / shell customization: yes
    choiceBL=5      # bootloader: skip
    choiceGRUB=7    # grub theme: none
    choiceCAO=2     # cachyos: no
    choiceWI=2      # wine: no
    choicePRIN=2    # printer: no
    choiceBAR=1     # bar: waybar

    case $mode in
        2) choiceDE=1; choiceGM=1; choiceEM=3; choiceTE=5 ;;
        3) choiceDE=1; choiceGM=2; choiceEM=4; choiceTE=5 ;;
        4) choiceDE=2; choiceGM=1; choiceEM=3; choiceTE=3 ;;
        5) choiceDE=2; choiceGM=2; choiceEM=4; choiceTE=3 ;;
    esac

    export mode choiceDE choiceTE choiceGM choiceEM choiceTPKG choiceTTE \
           choiceAUR choiceSHELL choiceSS choiceBL choiceGRUB choiceCAO \
           choiceWI choicePRIN choiceBAR
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
            echo "3) Hyprland"
            echo "4) Exit"
            read -p "Enter 1-4: " choiceDE
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
    ibus-daemon -drx

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
# AUR helper (yay) + Chaotic AUR
# ---------------------------------------------------------------------------

aur_setup() {
    if ! command -v yay &>/dev/null; then
        echo "Installing yay..."
        install_pacman base-devel
        git clone https://aur.archlinux.org/yay.git
        cd yay && makepkg -si --noconfirm && cd .. && rm -rf yay
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
        sudo cp pacman.conf /etc/pacman.conf
        sudo pacman -Syu --noconfirm
    fi
}

# ---------------------------------------------------------------------------
# Terminal text editors
# ---------------------------------------------------------------------------

terminal_text_editors_setup() {
    if [[ "$mode" == "1" ]]; then
        local editors=("${terminal_text_editors[@]}" "none")
        echo "Choose one or more terminal text editors (space-separated numbers, e.g. '1 3'):"
        for i in "${!editors[@]}"; do
            echo "$((i+1))) ${editors[i]}"
        done
        read -p "Enter numbers (1-${#editors[@]}): " -a choicesTE

        for choice in "${choicesTE[@]}"; do
            if [[ "$choice" -eq "${#editors[@]}" ]]; then
                echo "Skipping text editors."
                return
            fi
        done

        for choice in "${choicesTE[@]}"; do
            local editor="${editors[$((choice-1))]}"
            if [[ -n "$editor" && "$editor" != "none" ]]; then
                echo "Installing $editor..."
                install_pacman "$editor"
            fi
        done
    else
        case $choiceTTE in
            1) install_pacman nano    ;;
            2) install_pacman vim     ;;
            3) install_pacman micro   ;;
            4) install_pacman neovim  ;;
        esac
    fi
}

# ---------------------------------------------------------------------------
# Terminal emulator
# ---------------------------------------------------------------------------

terminal_setup() {
    # Hyprland always gets terminal packages
    [[ "$choiceDE" == "3" ]] && choiceTPKG=1

    if [[ "$mode" == "1" ]]; then
        echo "Install terminal utilities? (dysk tealdeer btop fastfetch bat fd eza fzf zoxide ripgrep yazi wl-clipboard)"
        echo "1) Yes  2) No"
        read -p "Enter 1-2: " choiceTPKG
    fi

    if [[ "$choiceTPKG" == "1" ]]; then
        install_yay "${terminal_packages[@]}"
        tldr --update
        mkdir -p ~/.config/yazi
        cp -r yazi ~/.config/
    fi

    if [[ "$mode" == "1" ]]; then
        local terminals=("gnome-console" "ptyxis" "konsole" "alacritty" "ghostty" "kitty" "none")
        echo "Choose a terminal emulator:"
        for i in "${!terminals[@]}"; do
            echo "$((i+1))) ${terminals[i]}"
        done
        read -p "Enter 1-${#terminals[@]}: " choiceTE
        if ! [[ "$choiceTE" =~ ^[1-9]$ ]] || [[ "$choiceTE" -gt "${#terminals[@]}" ]]; then
            echo "Invalid selection. Skipping terminal installation."
            choiceTE="${#terminals[@]}"
        fi
    fi

    local terminals=("gnome-console" "ptyxis" "konsole" "alacritty" "ghostty" "kitty" "none")
    terminal_choice="${terminals[$((choiceTE-1))]}"

    if [[ "$choiceDE" != "3" ]]; then
        case $terminal_choice in
            gnome-console|ptyxis|konsole|kitty)
                install_pacman "$terminal_choice"
                ;;
            alacritty|ghostty)
                install_yay "$terminal_choice"
                if [[ "$terminal_choice" == "ghostty" ]]; then
                    echo "Apply ghostty customization from dotfiles?"
                    echo "1) Yes  2) No"
                    read -p "Enter 1-2: " choiceGH
                    [[ "$choiceGH" == "1" ]] && mkdir -p ~/.config/ghostty && cp -r ghostty ~/.config/
                fi
                ;;
            none)
                echo "Skipping terminal emulator installation."
                ;;
        esac
    fi

    export terminal_choice
}

# ---------------------------------------------------------------------------
# Shell setup (bash / zsh / fish)
# ---------------------------------------------------------------------------

shell_setup() {
    if [[ "$mode" == "1" ]]; then
        echo "Choose your shell:"
        echo "1) Bash (keep current)"
        echo "2) Zsh"
        echo "3) Fish"
        read -p "Enter 1-3: " choiceSHELL
    fi

    case $choiceSHELL in
        2)
            install_pacman zsh
            chsh -s "$(which zsh)" "$USER"
            echo "Zsh installed and set as default shell."
            ;;
        3)
            install_pacman fish
            chsh -s "$(which fish)" "$USER"
            echo "Fish installed and set as default shell."
            ;;
        *)
            echo "Keeping Bash."
            ;;
    esac

    if [[ "$mode" == "1" ]]; then
        echo "Apply shell customizations? (Starship prompt, aliases, functions)"
        echo "1) Yes  2) No"
        read -p "Enter 1-2: " choiceSS
    fi

    [[ "$choiceSS" != "1" ]] && return

    # Install starship for bash and zsh (fish has its own prompt but starship works too)
    curl -sS https://starship.rs/install.sh | sh -s -- --yes

    case $choiceSHELL in
        1) _apply_bash_config  ;;
        2) _apply_zsh_config   ;;
        3) _apply_fish_config  ;;
    esac

    echo "Shell setup done."
}

_apply_bash_config() {
    if [[ "$choiceTPKG" == "1" ]]; then
        cp .betterbash ~/.bashrc
    else
        cp .bashrc ~/.bashrc
    fi

    # Copy fastfetch config for terminals that invoke it on launch
    if [[ "$terminal_choice" == "ghostty" || "$terminal_choice" == "kitty" ]]; then
        mkdir -p ~/.config/fastfetch
        cp -r fastfetch ~/.config/
    fi
}

_apply_zsh_config() {
    # Install useful zsh plugins from pacman
    install_pacman zsh-autosuggestions zsh-syntax-highlighting zsh-completions

    local ZSHRC="$HOME/.zshrc"

    cat > "$ZSHRC" << 'EOF'
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

eval "$(starship init zsh)"
EOF

    # zoxide if available
    if command -v zoxide &>/dev/null; then
        echo 'eval "$(zoxide init zsh)"' >> "$ZSHRC"
    fi

    cat >> "$ZSHRC" << 'EOF'

# Plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fpath=(/usr/share/zsh/site-functions $fpath)
autoload -Uz compinit && compinit

EOF

    # fastfetch on terminal launch
    if [[ "$terminal_choice" == "ghostty" || "$terminal_choice" == "kitty" ]]; then
        mkdir -p ~/.config/fastfetch
        cp -r fastfetch ~/.config/
        echo "fastfetch" >> "$ZSHRC"
    fi

    # Add functions and aliases — mirror of .betterbash when terminal packages are installed
    if [[ "$choiceTPKG" == "1" ]]; then
        cat >> "$ZSHRC" << 'EOF'
# Completion for eza, rg, fd
[ -f /usr/share/zsh/site-functions/_eza ] && source /usr/share/zsh/site-functions/_eza

# Yazi wrapper — cd on exit
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

export EDITOR='micro'

# Aliases
alias ls='eza --icons'
alias grep='rg'
alias find='fd'
alias cd='z'
alias cat='bat'
EOF
    else
        cat >> "$ZSHRC" << 'EOF'
# Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
EOF
    fi

    _append_common_aliases "$ZSHRC"
    _append_common_functions "$ZSHRC"
}

_apply_fish_config() {
    install_pacman fisher 2>/dev/null || true

    local FISH_DIR="$HOME/.config/fish"
    mkdir -p "$FISH_DIR/functions"

    cat > "$FISH_DIR/config.fish" << 'EOF'
# Fish config — generated by archinstall

if status is-interactive
    starship init fish | source
EOF

    if command -v zoxide &>/dev/null; then
        echo "    zoxide init fish | source" >> "$FISH_DIR/config.fish"
    fi

    if [[ "$terminal_choice" == "ghostty" || "$terminal_choice" == "kitty" ]]; then
        mkdir -p ~/.config/fastfetch
        cp -r fastfetch ~/.config/
        echo "    fastfetch" >> "$FISH_DIR/config.fish"
    fi

    cat >> "$FISH_DIR/config.fish" << 'EOF'
end
EOF

    if [[ "$choiceTPKG" == "1" ]]; then
        cat >> "$FISH_DIR/config.fish" << 'EOF'

# Aliases
alias ls 'eza --icons'
alias grep 'rg'
alias find 'fd'
alias cat 'bat'
EOF
        # Yazi wrapper as fish function
        cat > "$FISH_DIR/functions/y.fish" << 'EOF'
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    set cwd (cat -- "$tmp")
    if test -n "$cwd" -a "$cwd" != "$PWD"
        cd "$cwd"
    end
    rm -f -- "$tmp"
end
EOF
    else
        echo "alias ls 'ls --color=auto'" >> "$FISH_DIR/config.fish"
    fi

    cat >> "$FISH_DIR/config.fish" << 'EOF'

# Common aliases
alias update-system 'yay -Syyu --noconfirm && flatpak update -y --noninteractive'
alias clear-packages 'set orphans (yay -Qtdq); if test -n "$orphans"; yay -Rns --noconfirm $orphans; else; echo "No packages to clear."; end && flatpak remove --unused -y --noninteractive'
alias speedup-mirrors 'sudo reflector --sort rate --latest 20 --protocol https --save /etc/pacman.d/mirrorlist'
alias test-nvidia 'prime-run glxinfo | grep "OpenGL renderer"'
alias show-ip 'ip -4 addr show | grep inet | awk \'{print $2}\' | cut -d\'/\' -f1'
alias clear-cache 'sudo pacman -Scc --noconfirm && yay -Sc --noconfirm'
alias gs 'git status'
alias ga 'git add .'
alias gc 'git commit -m'
alias duh 'du -h --max-depth=1 | sort -hr'

# Functions
function mkcd
    if test -z "$argv[1]"
        echo "Usage: mkcd <directory>"
        return 1
    end
    mkdir -p "$argv[1]" && cd "$argv[1]" && echo "Created and entered: "(pwd)
end

function gitall
    if test -z "$argv[1]"
        echo "Usage: gitall \"commit message\""
        return 1
    end
    git add . && git commit -m "$argv[1]" && git push && echo "Changes committed and pushed."
end
EOF

    echo "Fish config written to $FISH_DIR/config.fish"
}

# Shared aliases appended to bash/zsh configs
_append_common_aliases() {
    local rc="$1"
    cat >> "$rc" << 'EOF'

alias update-system="yay -Syyu --noconfirm && flatpak update -y --noninteractive"
alias clear-packages='orphans=$(yay -Qtdq); if [ -n "$orphans" ]; then yay -Rns --noconfirm $orphans; else echo "No packages to clear."; fi && flatpak remove --unused -y --noninteractive'
alias speedup-mirrors="sudo reflector --sort rate --latest 20 --protocol https --save /etc/pacman.d/mirrorlist"
alias test-nvidia="prime-run glxinfo | grep 'OpenGL renderer'"
alias show-ip="ip -4 addr show | grep inet | awk '{print \$2}' | cut -d'/' -f1"
alias show-ip-wifi="ip -4 addr show | grep inet | grep -E 'wlan|wlp' | awk '{print \$2}' | cut -d'/' -f1"
alias clear-cache="sudo pacman -Scc --noconfirm && yay -Sc --noconfirm"
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias duh='du -h --max-depth=1 | sort -hr'
EOF
}

_append_common_functions() {
    local rc="$1"
    cat >> "$rc" << 'EOF'

extract() {
    local delete="n" confirm="y"
    while [ "$1" = "--delete" ] || [ "$1" = "--noconfirm" ]; do
        [ "$1" = "--delete" ] && delete="y"
        [ "$1" = "--no-confirm" ] && confirm="n"
        shift
    done
    for f in *.{zip,rar,7z,tar.gz,tar,tgz,tar.bz2}; do
        [ -f "$f" ] || continue
        case "$f" in
            *.zip)     unzip "$f"    ;;
            *.rar)     unrar x "$f"  ;;
            *.7z)      7z x "$f"     ;;
            *.tar.gz|*.tgz) tar -xzf "$f" ;;
            *.tar)     tar -xf "$f"  ;;
            *.tar.bz2) tar -xjf "$f" ;;
        esac || { echo "Failed to extract $f"; return 1; }
        if [ "$delete" = "y" ]; then
            [ "$confirm" = "y" ] && read -p "Delete $f? [y/N] " c && [ "$c" = "y" ] && rm -f "$f"
            [ "$confirm" = "n" ] && rm -f "$f"
        fi
    done
}

mkcd() {
    [ -z "$1" ] && { echo "Usage: mkcd <directory>"; return 1; }
    mkdir -p "$1" && cd "$1" && echo "Created and entered: $(pwd)"
}

gitall() {
    [ -z "$1" ] && { echo "Usage: gitall \"commit message\""; return 1; }
    git add . && git commit -m "$1" && git push && echo "Changes committed and pushed."
}
EOF
}

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
# Video drivers
# ---------------------------------------------------------------------------

nvidia_setup() {
    if [[ "$IS_HYBRID" == "true" ]]; then
        echo "Hybrid GPU detected — no additional NVIDIA configuration needed."
        return
    fi

    if [[ "$choiceDE" == "3" ]]; then
        local HYPRCONF="${HOME}/.config/hypr/hyprland.conf"
        mkdir -p "${HOME}/.config/hypr"
        touch "$HYPRCONF"
        grep -q '^env = GBM_BACKEND,nvidia-drm'          "$HYPRCONF" || echo 'env = GBM_BACKEND,nvidia-drm'          >> "$HYPRCONF"
        grep -q '^env = LIBVA_DRIVER_NAME,nvidia'         "$HYPRCONF" || echo 'env = LIBVA_DRIVER_NAME,nvidia'         >> "$HYPRCONF"
        grep -q '^env = __GLX_VENDOR_LIBRARY_NAME,nvidia' "$HYPRCONF" || echo 'env = __GLX_VENDOR_LIBRARY_NAME,nvidia' >> "$HYPRCONF"
        grep -q '^env = WLR_NO_HARDWARE_CURSORS,1'        "$HYPRCONF" || echo 'env = WLR_NO_HARDWARE_CURSORS,1'        >> "$HYPRCONF"
    fi
    sudo mkinitcpio -P
}

install_video_drivers() {
    install_pacman "${base_drivers[@]}"

    local GPU_INFO
    GPU_INFO=$(lspci | grep -iE "VGA|3D|Display" || true)
    local HAS_INTEL HAS_AMD HAS_NVIDIA
    HAS_INTEL=$(echo "$GPU_INFO" | grep -i intel  || true)
    HAS_AMD=$(echo   "$GPU_INFO" | grep -i amd    || true)
    HAS_NVIDIA=$(echo "$GPU_INFO" | grep -i nvidia || true)
    IS_HYBRID=false
    [[ -n "$HAS_NVIDIA" && ( -n "$HAS_INTEL" || -n "$HAS_AMD" ) ]] && IS_HYBRID=true
    export IS_HYBRID

    [[ -n "$HAS_INTEL"  ]] && install_pacman "${intel_drivers[@]}"
    [[ -n "$HAS_AMD"    ]] && install_pacman "${amd_drivers[@]}"

    if [[ -n "$HAS_NVIDIA" ]]; then
        install_pacman "${nvidia_common_utils[@]}"
        if [[ "$choiceCAO" == "1" ]]; then
            install_pacman "${nvidia_cachyos[@]}"
        else
            install_pacman "${nvidia_drivers[@]}"
            nvidia_setup
        fi
    else
        sudo cp grub/grub /etc/default/grub
    fi

    if lspci | grep -i vmware &>/dev/null; then
        install_pacman "${vmware_drivers[@]}"
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

# ---------------------------------------------------------------------------
# Hyprland — bar selection + dotfiles
# ---------------------------------------------------------------------------

hyprland_setup() {
    [[ "$choiceDE" != "3" ]] && return

    _hyprland_choose_bar
    _hyprland_install_bar
    _hyprland_copy_dotfiles
    _hyprland_finalize
}

_hyprland_choose_bar() {
    echo ""
    echo "Choose a status bar / shell for Hyprland:"
    echo "1) Waybar       — simple, reliable, highly configurable via JSON+CSS"
    echo "2) AGS          — scriptable in JavaScript, modern widget toolkit"
    echo "3) Eww          — widget system in Yuck (Lisp-like), very flexible"
    echo "4) Quickshell   — QML-based, fast and composable"
    echo "5) None          — skip bar installation"
    read -p "Enter 1-5: " choiceBAR
    export choiceBAR
}

_hyprland_install_bar() {
    case $choiceBAR in
        1)
            echo "Installing Waybar..."
            install_pacman waybar
            ;;
        2)
            echo "Installing AGS..."
            # AGS v2 (astal-based) is available in AUR
            install_yay ags
            ;;
        3)
            echo "Installing Eww..."
            install_yay eww
            ;;
        4)
            echo "Installing Quickshell..."
            install_yay quickshell-git
            ;;
        5)
            echo "Skipping bar installation."
            ;;
        *)
            echo "Invalid choice. Skipping bar."
            choiceBAR=5
            ;;
    esac
}

_hyprland_copy_dotfiles() {
    echo "Copying Hyprland dotfiles..."

    # Core hypr configs
    mkdir -p ~/.config/hypr
    cp hypr/hyprland.conf  ~/.config/hypr/
    cp hypr/hypridle.conf  ~/.config/hypr/
    cp hypr/hyprlock.conf  ~/.config/hypr/
    cp hypr/hyprpaper.conf ~/.config/hypr/
    cp hypr/wallpapers.sh  ~/.config/hypr/
    chmod +x ~/.config/hypr/wallpapers.sh

    # wofi
    mkdir -p ~/.config/wofi
    cp -r wofi ~/.config/

    # bar-specific configs
    case $choiceBAR in
        1)
            mkdir -p ~/.config/waybar
            cp -r waybar ~/.config/
            ;;
        2)
            # AGS config goes to ~/.config/ags
            mkdir -p ~/.config/ags
            if [[ -d ags ]]; then
                cp -r ags ~/.config/
            else
                echo "No AGS dotfiles found in repo — AGS will start with defaults."
                echo "See https://aylur.github.io/ags-docs/ to create your config."
            fi
            ;;
        3)
            mkdir -p ~/.config/eww
            if [[ -d eww ]]; then
                cp -r eww ~/.config/
            else
                echo "No Eww dotfiles found in repo — create ~/.config/eww/eww.yuck to get started."
                echo "See https://elkowar.github.io/eww/ for documentation."
            fi
            ;;
        4)
            mkdir -p ~/.config/quickshell
            if [[ -d quickshell ]]; then
                cp -r quickshell ~/.config/
            else
                echo "No Quickshell dotfiles found in repo — create ~/.config/quickshell/shell.qml to get started."
                echo "See https://quickshell.outfoxxed.me/ for documentation."
            fi
            ;;
    esac

    # Kitty opacity tweak
    if [[ "$terminal_choice" == "kitty" ]]; then
        mkdir -p ~/.config/kitty
        echo "background_opacity 0.5" >> ~/.config/kitty/kitty.conf
    fi

    sudo usermod -aG video "$USER"
}

_hyprland_finalize() {
    # Patch hyprland.conf to reference the chosen bar
    local HYPRCONF="$HOME/.config/hypr/hyprland.conf"

    # Replace the bar exec-once line with the correct bar command
    case $choiceBAR in
        1) local BAR_CMD="waybar" ;;
        2) local BAR_CMD="ags" ;;
        3) local BAR_CMD="eww open bar" ;;
        4) local BAR_CMD="quickshell" ;;
        *) local BAR_CMD="" ;;
    esac

    if [[ -n "$BAR_CMD" ]]; then
        # If an exec-once bar line already exists, replace it; otherwise append
        if grep -q 'exec-once = \$bar' "$HYPRCONF"; then
            sed -i "s|exec-once = \\\$bar.*|exec-once = ${BAR_CMD}|" "$HYPRCONF"
        else
            # Insert after the last exec-once line
            sed -i "/^exec-once/a exec-once = ${BAR_CMD}" "$HYPRCONF" | head -1
        fi
    fi

    # Also fix the bar toggle keybind (Super+Escape) to match the chosen bar
    case $choiceBAR in
        1) sed -i 's|exec, killall waybar || waybar|exec, killall waybar \|\| waybar|' "$HYPRCONF" ;;
        2) sed -i "s|exec, killall waybar || waybar|exec, killall ags \|\| ags|" "$HYPRCONF" ;;
        3) sed -i "s|exec, killall waybar || waybar|exec, eww close-all \|\| eww open bar|" "$HYPRCONF" ;;
        4) sed -i "s|exec, killall waybar || waybar|exec, killall quickshell \|\| quickshell|" "$HYPRCONF" ;;
        5) sed -i '/killall waybar/d' "$HYPRCONF" ;;
    esac

    echo "Hyprland setup complete."
    echo "Bar chosen: ${BAR_CMD:-none}"
}

# ---------------------------------------------------------------------------
# Bootloader selection
# ---------------------------------------------------------------------------

bootloader_setup() {
    echo "Choose a bootloader:"
    echo "1) GRUB        (feature-rich, great dual-boot support, themes available)"
    echo "2) systemd-boot (simple, fast, integrated with systemd)"
    echo "3) rEFInd      (graphical, auto-detects OSes — best for dual-boot)"
    echo "4) Limine      (modern, minimal, fast)"
    echo "5) Skip        (keep existing bootloader)"
    read -p "Enter 1-5: " choiceBL

    case $choiceBL in
        1) _install_grub         ;;
        2) _install_systemd_boot ;;
        3) _install_refind       ;;
        4) _install_limine       ;;
        5) echo "Skipping bootloader setup." ;;
        *) echo "Invalid choice. Skipping bootloader setup." ;;
    esac

    export choiceBL
}

_install_grub() {
    install_yay "${grub_packages[@]}"
    sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
    sudo systemctl enable --now grub-btrfsd

    # Enable os-prober so GRUB detects Windows (disabled by default on Arch)
    local GRUB_DEFAULT=/etc/default/grub
    if ! grep -q '^GRUB_DISABLE_OS_PROBER=false' "$GRUB_DEFAULT"; then
        if grep -q 'GRUB_DISABLE_OS_PROBER' "$GRUB_DEFAULT"; then
            sudo sed -i 's/^#*GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' "$GRUB_DEFAULT"
        else
            echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee -a "$GRUB_DEFAULT" > /dev/null
        fi
    fi

    sudo grub-mkconfig -o /boot/grub/grub.cfg
    echo "GRUB installed and configured."
    _grub_theme_selection
}

_grub_theme_selection() {
    echo "Choose a GRUB theme:"
    echo "1) Lain     (1080p, credits: uiriansan)"
    echo "2) Tela     (credits: vinceliuice)"
    echo "3) Stylish  (credits: vinceliuice)"
    echo "4) Vimix    (credits: vinceliuice)"
    echo "5) WhiteSur (credits: vinceliuice)"
    echo "6) Fallout  (credits: shvchk)"
    echo "7) No theme"
    read -p "Enter 1-7: " choiceGRUB

    case $choiceGRUB in
        1)
            git clone --depth=1 https://github.com/uiriansan/LainGrubTheme
            cd LainGrubTheme && ./install.sh && ./patch_entries.sh
            cd .. && rm -rf LainGrubTheme
            ;;
        2|3|4|5)
            git clone https://github.com/vinceliuice/grub2-themes.git
            cd grub2-themes && chmod +x install.sh
            local res="1080p"
            local resolutions=("1080p" "2k" "4k" "ultrawide" "ultrawide2k")
            echo "Select your display resolution:"
            for i in "${!resolutions[@]}"; do echo "$((i+1))) ${resolutions[i]}"; done
            read -p "Enter 1-${#resolutions[@]} (default: 1080p): " res_choice
            [[ "$res_choice" =~ ^[1-5]$ ]] && res="${resolutions[$((res_choice-1))]}"
            case $choiceGRUB in
                2) sudo ./install.sh -t tela     -s "$res" ;;
                3) sudo ./install.sh -t stylish  -s "$res" ;;
                4) sudo ./install.sh -t vimix    -s "$res" ;;
                5) sudo ./install.sh -t whitesur -s "$res" ;;
            esac
            cd .. && rm -rf grub2-themes
            ;;
        6)
            git clone https://github.com/shvchk/fallout-grub-theme.git
            cd fallout-grub-theme && chmod +x install.sh && ./install.sh
            cd .. && rm -rf fallout-grub-theme
            ;;
        *)
            echo "No GRUB theme applied."
            ;;
    esac
}

_install_systemd_boot() {
    sudo bootctl install
    sudo mkdir -p /boot/loader/entries

    local ROOT_PARTUUID
    ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$(findmnt -n -o SOURCE /)")

    sudo tee /boot/loader/loader.conf > /dev/null <<EOF
default arch.conf
timeout 5
console-mode max
editor no
EOF

    sudo tee /boot/loader/entries/arch.conf > /dev/null <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=${ROOT_PARTUUID} rw quiet
EOF

    # Auto-detect Windows
    local WIN_PART
    WIN_PART=$(blkid -t TYPE=vfat -o device | while read -r dev; do
        local mp search_path
        mp=$(findmnt -n -o TARGET "$dev" 2>/dev/null)
        search_path="${mp:-/tmp/_efi_probe_$$}"
        if [[ -z "$mp" ]]; then
            sudo mkdir -p "$search_path"
            sudo mount "$dev" "$search_path" 2>/dev/null || { sudo rmdir "$search_path"; continue; }
        fi
        if [[ -f "$search_path/EFI/Microsoft/Boot/bootmgfw.efi" ]]; then
            echo "$dev"
            [[ -z "$mp" ]] && sudo umount "$search_path" && sudo rmdir "$search_path"
            break
        fi
        [[ -z "$mp" ]] && sudo umount "$search_path" 2>/dev/null && sudo rmdir "$search_path" 2>/dev/null
    done)

    if [[ -n "$WIN_PART" ]]; then
        sudo tee /boot/loader/entries/windows.conf > /dev/null <<EOF
title   Windows
efi     /EFI/Microsoft/Boot/bootmgfw.efi
EOF
        echo "Windows Boot Manager detected on ${WIN_PART} — entry created."
    else
        echo "No Windows installation detected. Skipping Windows entry."
    fi

    sudo bootctl update
    echo "systemd-boot installed and configured."
    echo "NOTE: Edit /boot/loader/entries/arch.conf to adjust kernel options as needed."
}

_install_refind() {
    install_pacman refind
    sudo refind-install
    echo "rEFInd installed. It auto-detects bootable entries on next reboot."
    echo "Optionally customize /boot/EFI/refind/refind.conf for themes/options."
}

_install_limine() {
    install_yay limine

    local EFI_DISK
    EFI_DISK=$(lsblk -no PKNAME "$(findmnt -n -o SOURCE /boot)" 2>/dev/null | head -1)
    if [[ -z "$EFI_DISK" ]]; then
        echo "WARNING: Could not auto-detect EFI disk. Install Limine manually:"
        echo "  sudo limine bios-install /dev/sdX"
        echo "  sudo cp /usr/share/limine/BOOTX64.EFI /boot/EFI/limine/"
        return
    fi

    sudo limine bios-install "/dev/$EFI_DISK"
    sudo mkdir -p /boot/EFI/limine
    sudo cp /usr/share/limine/BOOTX64.EFI /boot/EFI/limine/

    local ROOT_PARTUUID
    ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$(findmnt -n -o SOURCE /)")

    sudo tee /boot/limine.cfg > /dev/null <<EOF
TIMEOUT=5

:Arch Linux
    PROTOCOL=linux
    KERNEL_PATH=boot:///vmlinuz-linux
    CMDLINE=root=PARTUUID=${ROOT_PARTUUID} rw quiet
    MODULE_PATH=boot:///initramfs-linux.img
EOF

    # Auto-detect Windows
    local WIN_PART WIN_DISK WIN_PARTNUM
    WIN_PART=$(blkid -t TYPE=vfat -o device | while read -r dev; do
        local mp search_path
        mp=$(findmnt -n -o TARGET "$dev" 2>/dev/null)
        search_path="${mp:-/tmp/_efi_probe_$$}"
        if [[ -z "$mp" ]]; then
            sudo mkdir -p "$search_path"
            sudo mount "$dev" "$search_path" 2>/dev/null || { sudo rmdir "$search_path"; continue; }
        fi
        if [[ -f "$search_path/EFI/Microsoft/Boot/bootmgfw.efi" ]]; then
            echo "$dev"
            [[ -z "$mp" ]] && sudo umount "$search_path" && sudo rmdir "$search_path"
            break
        fi
        [[ -z "$mp" ]] && sudo umount "$search_path" 2>/dev/null && sudo rmdir "$search_path" 2>/dev/null
    done)

    if [[ -n "$WIN_PART" ]]; then
        WIN_DISK=$(lsblk -no PKNAME "$WIN_PART")
        WIN_PARTNUM=$(cat /sys/class/block/"$(basename "$WIN_PART")"/partition 2>/dev/null || echo "1")
        sudo tee -a /boot/limine.cfg > /dev/null <<EOF

:Windows
    PROTOCOL=chainload
    DRIVE=${WIN_DISK}
    PARTITION=${WIN_PARTNUM}
EOF
        echo "Windows detected on ${WIN_PART} — chainload entry added to limine.cfg."
    else
        echo "No Windows installation detected. Skipping Windows entry."
    fi

    echo "Limine installed. Edit /boot/limine.cfg to adjust entries."
}
