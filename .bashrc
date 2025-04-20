# If not running interactively, don't do anything
[[ $- != *i* ]] && return

eval "$(starship init bash)"
#pokemon-colorscripts --no-title -r 5

# Functions
extract() {
    for f in *.{zip,rar,7z,tar.gz,tar,tgz,tar.bz2}; do
        [ -f "$f" ] && echo "Extracting $f" && (
            case "$f" in
                *.zip) unzip "$f";;
                *.rar) unrar x "$f";;
                *.7z) 7z x "$f";;
                *.tar.gz|*.tgz) tar -xzf "$f";;
                *.tar) tar -xf "$f";;
                *.tar.bz2) tar -xjf "$f";;
            esac
        ) && [ "$delete" = "y" ] && rm "$f"
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

check_install_days() {
  # Get the creation (birth) time of /etc
  birth_time=$(stat -c %w /etc 2>/dev/null | cut -d ' ' -f1)

  if [ -z "$birth_time" ] || [ "$birth_time" = "-" ]; then
    echo "Error: Could not retrieve creation time of /etc. Your system may not support birth time."
    return 1
  fi

  # Calculate days since installation
  days=$(( ($(date +%s) - $(date -d "$birth_time" +%s)) / 86400 ))

  # Output result
  echo "System installed approximately $days days ago"
}

# aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias update-system="yay -Syu && flatpak update"
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
