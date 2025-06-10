# If not running interactively, don't do anything
[[ $- != *i* ]] && return

eval "$(starship init bash)"
#pokemon-colorscripts --no-title -r 5
fastfetch

# Functions
extract() {
    local delete="n" confirm="y"
    while [ "$1" = "--delete" ] || [ "$1" = "--no-confirm" ]; do
        if [ "$1" = "--delete" ]; then
            delete="y"
        elif [ "$1" = "--no-confirm" ]; then
            confirm="n"
        fi
        shift
    done
    for f in *.{zip,rar,7z,tar.gz,tar,tgz,tar.bz2}; do
        if [ -f "$f" ]; then
            echo "Extracting $f"
            case "$f" in
                *.zip) unzip "$f" || { echo "Failed to extract $f"; return 1; } ;;
                *.rar) unrar x "$f" || { echo "Failed to extract $f"; return 1; } ;;
                *.7z) 7z x "$f" || { echo "Failed to extract $f"; return 1; } ;;
                *.tar.gz|*.tgz) tar -xzf "$f" || { echo "Failed to extract $f"; return 1; } ;;
                *.tar) tar -xf "$f" || { echo "Failed to extract $f"; return 1; } ;;
                *.tar.bz2) tar -xjf "$f" || { echo "Failed to extract $f"; return 1; } ;;
            esac
            if [ "$delete" = "y" ]; then
                if [ "$confirm" = "y" ]; then
                    read -p "Delete $f? [y/N] " user_confirm
                    [ "$user_confirm" = "y" ] && rm -f "$f" && echo "Deleted $f"
                else
                    rm -f "$f" && echo "Deleted $f"
                fi
            fi
        fi
    done
}

mkcd() {
    if [ -z "$1" ]; then
        echo "Usage: mkcd <directory>"
        return 1
    fi
    if ! mkdir -p "$1"; then
        echo "Failed to create directory: $1"
        return 1
    fi
    cd "$1" && echo "Created and entered: $(pwd)"
}

gitall() {
    if [ -z "$1" ]; then
        echo "Usage: gitall \"commit message\""
        return 1
    fi
    git add . && git commit -m "$1" && git push && echo "Changes committed and pushed."
}

# aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias update-system="yay -Syyu && flatpak update"
alias clear-packages='sudo pacman -Rns $(sudo pacman -Qtdq)'
alias speedup-mirrors="sudo reflector --sort rate --latest 20 --protocol https --save /etc/pacman.d/mirrorlist"
alias test-nvidia="prime-run glxinfo | grep 'OpenGL renderer'"
alias show-ip-wifi="ip address | grep wlp8s0 | grep inet | awk '{print $2}' | cut -d'/' -f1"
alias show-ip="ip address | grep eth0 | grep inet | awk '{print $2}' | cut -d'/' -f1"
alias logoff="gnome-session-quit --no-prompt"
alias clear-cache="sudo pacman -Scc && yay -Sc && flatpak remove --unused"
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias duh='du -h --max-depth=1 | sort -hr'
