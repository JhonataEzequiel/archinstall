#!/bin/bash
# terminal.sh — Terminal text editors and terminal emulator setup

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
                ;;
            none)
                echo "Skipping terminal emulator installation."
                ;;
        esac
    fi

    export terminal_choice
}
