#!/bin/bash
# hyprland.sh — Bar, launcher, screenshot stack, dotfiles, config generation

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

hyprland_setup() {
    [[ "$choiceDE" != "3" ]] && return

    _hyprland_choose_bar
    _hyprland_install_bar
    _hyprland_choose_launcher
    _hyprland_install_launcher
    _hyprland_install_screenshot
    _hyprland_copy_dotfiles
    _hyprland_finalize
}

# ---------------------------------------------------------------------------
# Bar
# ---------------------------------------------------------------------------

_hyprland_choose_bar() {
    echo ""
    echo "Choose a status bar / shell for Hyprland:"
    echo "1) Waybar       — simple, reliable, highly configurable via JSON+CSS"
    echo "2) AGS          — scriptable in JavaScript, modern widget toolkit"
    echo "3) Eww          — widget system in Yuck (Lisp-like), very flexible"
    echo "4) Quickshell   — QML-based, fast and composable"
    echo "5) None         — skip bar installation"
    read -p "Enter 1-5 [1]: " choiceBAR
    choiceBAR=${choiceBAR:-1}
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

# ---------------------------------------------------------------------------
# Launcher
# ---------------------------------------------------------------------------

_hyprland_choose_launcher() {
    echo ""
    echo "Choose an application launcher / menu for Hyprland:"
    echo "1) wofi         — lightweight, native wlroots launcher (simple)"
    echo "2) rofi-wayland — feature-rich, themeable, actively maintained"
    echo "3) walker       — modern, plugin-based launcher (AUR)"
    read -p "Enter 1-3 [2]: " choiceLAUNCHER
    choiceLAUNCHER=${choiceLAUNCHER:-2}
    export choiceLAUNCHER
}

_hyprland_install_launcher() {
    case $choiceLAUNCHER in
        1)
            echo "Installing wofi..."
            install_pacman wofi
            ;;
        2)
            echo "Installing rofi-wayland..."
            install_pacman rofi-wayland
            ;;
        3)
            echo "Installing walker (AUR)..."
            install_yay walker
            ;;
        *)
            echo "Invalid launcher choice. Defaulting to rofi-wayland."
            install_pacman rofi-wayland
            choiceLAUNCHER=2
            ;;
    esac
    export choiceLAUNCHER
}

# ---------------------------------------------------------------------------
# Screenshot stack
# ---------------------------------------------------------------------------

_hyprland_install_screenshot() {
    echo "Installing screenshot stack (grimblast + grim + slurp)..."
    install_yay grimblast
    install_pacman grim slurp
}

# ---------------------------------------------------------------------------
# Dotfiles
# ---------------------------------------------------------------------------

_hyprland_copy_dotfiles() {
    echo ""
    mkdir -p ~/.config/hypr

    echo "Do you want to use the custom hyprland.conf from this repo?"
    echo "  1) Yes — copy my personal hyprland.conf (keybinds, rules, env vars, etc.)"
    echo "  2) No  — generate a clean default hyprland.conf from scratch"
    read -p "Enter 1-2 [2]: " choiceHYPRCONF
    choiceHYPRCONF=${choiceHYPRCONF:-2}

    if [[ "$choiceHYPRCONF" == "1" ]]; then
        echo "Copying custom hyprland.conf..."
        cp hypr/hyprland.conf ~/.config/hypr/
    else
        echo "Generating default hyprland.conf..."
        _hyprland_generate_default_conf
    fi

    # launcher dotfiles — copy if available, otherwise generate minimal defaults
    case $choiceLAUNCHER in
        1)
            mkdir -p ~/.config/wofi
            if [[ -d wofi ]]; then
                cp -r wofi/. ~/.config/wofi/
            else
                echo "No wofi dotfiles found — generating minimal wofi config..."
                _hyprland_generate_wofi_config
            fi
            ;;
        2)
            mkdir -p ~/.config/rofi
            if [[ -d rofi ]]; then
                cp -r rofi/. ~/.config/rofi/
            else
                echo "No rofi dotfiles found — rofi-wayland will use its built-in defaults."
                echo "Run 'rofi -dump-config > ~/.config/rofi/config.rasi' to start customising."
            fi
            ;;
        3)
            mkdir -p ~/.config/walker
            if [[ -d walker ]]; then
                cp -r walker/. ~/.config/walker/
            else
                echo "No walker dotfiles found — walker will use its built-in defaults."
                echo "See https://github.com/abenz1267/walker for configuration docs."
            fi
            ;;
    esac

    # bar-specific dotfiles
    case $choiceBAR in
        1)
            mkdir -p ~/.config/waybar
            if [[ -d waybar ]]; then
                cp -r waybar/. ~/.config/waybar/
            else
                echo "No Waybar dotfiles found — Waybar will start with its built-in defaults."
                echo "Edit ~/.config/waybar/config.jsonc and style.css to customise."
            fi
            ;;
        2)
            mkdir -p ~/.config/ags
            if [[ -d ags ]]; then
                cp -r ags/. ~/.config/ags/
            else
                echo "No AGS dotfiles found — AGS will start with defaults."
                echo "See https://aylur.github.io/ags-docs/ to create your config."
            fi
            ;;
        3)
            mkdir -p ~/.config/eww
            if [[ -d eww ]]; then
                cp -r eww/. ~/.config/eww/
            else
                echo "No Eww dotfiles found — create ~/.config/eww/eww.yuck to get started."
                echo "See https://elkowar.github.io/eww/ for documentation."
            fi
            ;;
        4)
            mkdir -p ~/.config/quickshell
            if [[ -d quickshell ]]; then
                cp -r quickshell/. ~/.config/quickshell/
            else
                echo "No Quickshell dotfiles found — create ~/.config/quickshell/shell.qml to get started."
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

# ---------------------------------------------------------------------------
# Default hyprland.conf generator
# ---------------------------------------------------------------------------

_hyprland_generate_default_conf() {
    local TERM_BIN
    case "${terminal_choice:-kitty}" in
        gnome-console) TERM_BIN="kgx"       ;;
        ptyxis)        TERM_BIN="ptyxis"    ;;
        konsole)       TERM_BIN="konsole"   ;;
        alacritty)     TERM_BIN="alacritty" ;;
        ghostty)       TERM_BIN="ghostty"   ;;
        kitty|*)       TERM_BIN="kitty"     ;;
    esac

    local MENU_CMD
    case ${choiceLAUNCHER:-2} in
        1) MENU_CMD="wofi --show drun" ;;
        2) MENU_CMD="rofi -show drun"  ;;
        3) MENU_CMD="walker"           ;;
        *) MENU_CMD="rofi -show drun"  ;;
    esac

    local BAR_EXEC=""
    case $choiceBAR in
        1) BAR_EXEC="exec-once = waybar"       ;;
        2) BAR_EXEC="exec-once = ags"          ;;
        3) BAR_EXEC="exec-once = eww open bar" ;;
        4) BAR_EXEC="exec-once = quickshell"   ;;
    esac

    cat > ~/.config/hypr/hyprland.conf << EOF
# =============================================================================
# Hyprland default configuration — generated by archinstall
# Full reference: https://wiki.hyprland.org/Configuring/
# =============================================================================

# --- Monitors ----------------------------------------------------------------
monitor=,preferred,auto,1

# --- Autostart ---------------------------------------------------------------
exec-once = hyprpolkitagent
exec-once = nm-applet
exec-once = swaync
exec-once = wl-paste --type text  --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
${BAR_EXEC}

# --- Environment variables ---------------------------------------------------
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Adwaita
env = QT_QPA_PLATFORM,wayland
env = QT_QPA_PLATFORMTHEME,qt5ct
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland

# --- Look & feel -------------------------------------------------------------
general {
    gaps_in             = 5
    gaps_out            = 10
    border_size         = 2
    col.active_border   = rgba(88c0d0ff) rgba(81a1c1ff) 45deg
    col.inactive_border = rgba(4c566aaa)
    layout              = dwindle
    resize_on_border    = true
}

decoration {
    rounding = 10
    blur {
        enabled           = true
        size              = 6
        passes            = 3
        new_optimizations = true
    }
    shadow {
        enabled      = true
        range        = 10
        render_power = 2
        color        = rgba(1a1a1aee)
    }
}

animations {
    enabled = true
    bezier  = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows,    1, 7,  myBezier
    animation = windowsOut, 1, 7,  default, popin 80%
    animation = border,     1, 10, default
    animation = fade,       1, 7,  default
    animation = workspaces, 1, 6,  default
}

# --- Layouts -----------------------------------------------------------------
dwindle {
    pseudotile     = true
    preserve_split = true
}

master {
    new_status = master
}

# --- Input -------------------------------------------------------------------
input {
    kb_layout    = us
    follow_mouse = 1
    sensitivity  = 0
    touchpad {
        natural_scroll = false
        tap-to-click   = true
        drag_lock      = false
    }
}

gestures {
    workspace_swipe = true
}

# --- Misc --------------------------------------------------------------------
misc {
    force_default_wallpaper = 0
    disable_hyprland_logo   = true
}

# =============================================================================
# Keybindings  (SUPER = Windows key)
# =============================================================================
\$mainMod     = SUPER
\$terminal    = ${TERM_BIN}
\$fileManager = nautilus
\$menu        = ${MENU_CMD}

# Applications
bind = \$mainMod,       Return, exec, \$terminal
bind = \$mainMod,       E,      exec, \$fileManager
bind = \$mainMod,       R,      exec, \$menu
bind = \$mainMod,       B,      exec, xdg-open https://

# Window management
bind = \$mainMod,       Q,      killactive
bind = \$mainMod,       F,      fullscreen, 0
bind = \$mainMod SHIFT, F,      fullscreen, 1
bind = \$mainMod,       V,      togglefloating
bind = \$mainMod,       P,      pseudo
bind = \$mainMod,       J,      togglesplit

# Focus
bind = \$mainMod, left,  movefocus, l
bind = \$mainMod, right, movefocus, r
bind = \$mainMod, up,    movefocus, u
bind = \$mainMod, down,  movefocus, d

# Move windows
bind = \$mainMod SHIFT, left,  movewindow, l
bind = \$mainMod SHIFT, right, movewindow, r
bind = \$mainMod SHIFT, up,    movewindow, u
bind = \$mainMod SHIFT, down,  movewindow, d

# Resize windows
binde = \$mainMod CTRL, left,  resizeactive, -20 0
binde = \$mainMod CTRL, right, resizeactive,  20 0
binde = \$mainMod CTRL, up,    resizeactive,  0 -20
binde = \$mainMod CTRL, down,  resizeactive,  0  20

# Workspaces 1-9
\$(for i in \$(seq 1 9); do
    echo "bind = \\\$mainMod,       \$i, workspace,       \$i"
    echo "bind = \\\$mainMod SHIFT, \$i, movetoworkspace, \$i"
done)

# Special workspace (scratchpad)
bind = \$mainMod,       S, togglespecialworkspace, magic
bind = \$mainMod SHIFT, S, movetoworkspace,        special:magic

# Scroll through workspaces with mouse
bind = \$mainMod, mouse_down, workspace, e+1
bind = \$mainMod, mouse_up,   workspace, e-1

# Move/resize with mouse
bindm = \$mainMod, mouse:272, movewindow
bindm = \$mainMod, mouse:273, resizewindow

# Screenshots (grimblast)
bind = ,                Print, exec, grimblast copy output
bind = \$mainMod,       Print, exec, grimblast copy area
bind = \$mainMod SHIFT, Print, exec, grimblast copy active

# Clipboard history
bind = \$mainMod, C, exec, cliphist list | ${MENU_CMD/--show drun/--dmenu} | cliphist decode | wl-copy

# Colour picker
bind = \$mainMod SHIFT, C, exec, hyprpicker -a

# Notifications
bind = \$mainMod,       N, exec, swaync-client -t
bind = \$mainMod SHIFT, N, exec, swaync-client -C

# Lock screen
bind = \$mainMod, L, exec, hyprlock

# Bar toggle (Super+Escape)
bind = \$mainMod, Escape, exec, killall waybar || waybar

# Audio (wireplumber + playerctl)
bindel = , XF86AudioRaiseVolume,  exec, wpctl set-volume    @DEFAULT_AUDIO_SINK@ 5%+
bindel = , XF86AudioLowerVolume,  exec, wpctl set-volume    @DEFAULT_AUDIO_SINK@ 5%-
bindl  = , XF86AudioMute,         exec, wpctl set-mute      @DEFAULT_AUDIO_SINK@ toggle
bindl  = , XF86AudioMicMute,      exec, wpctl set-mute      @DEFAULT_AUDIO_SOURCE@ toggle
bindl  = , XF86AudioPlay,         exec, playerctl play-pause
bindl  = , XF86AudioPrev,         exec, playerctl previous
bindl  = , XF86AudioNext,         exec, playerctl next

# Brightness (brightnessctl)
bindel = , XF86MonBrightnessUp,   exec, brightnessctl set 5%+
bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# =============================================================================
# Window rules
# =============================================================================
windowrulev2 = suppressevent maximize, class:.*
windowrulev2 = float, class:^(pavucontrol)$
windowrulev2 = float, class:^(nm-connection-editor)$
windowrulev2 = float, title:^(Picture-in-Picture)$
windowrulev2 = pin,   title:^(Picture-in-Picture)$
EOF

    echo "Default hyprland.conf written to ~/.config/hypr/hyprland.conf"
}

# ---------------------------------------------------------------------------
# Minimal wofi config generator (fallback when no dotfiles exist)
# ---------------------------------------------------------------------------

_hyprland_generate_wofi_config() {
    cat > ~/.config/wofi/config << 'EOF'
width=500
height=400
location=center
show=drun
prompt=Search...
filter_rate=100
allow_markup=true
no_actions=true
halign=fill
orientation=vertical
content_halign=fill
insensitive=true
allow_images=true
image_size=24
EOF

    cat > ~/.config/wofi/style.css << 'EOF'
* {
    font-family: "JetBrains Mono Nerd Font", monospace;
    font-size: 13px;
}

window {
    margin: 0px;
    border: 2px solid #88c0d0;
    border-radius: 10px;
    background-color: #2e3440ee;
}

#input {
    margin: 8px;
    border: none;
    border-radius: 8px;
    color: #eceff4;
    background-color: #3b4252;
}

#inner-box {
    margin: 4px;
    border: none;
    background-color: transparent;
}

#outer-box {
    margin: 4px;
    border: none;
    background-color: transparent;
}

#scroll {
    margin: 0px;
    border: none;
}

#text {
    margin: 5px;
    border: none;
    color: #eceff4;
}

#entry:selected {
    border-radius: 6px;
    background-color: #4c566a;
}

#text:selected {
    color: #88c0d0;
}
EOF
    echo "Default wofi config and style generated."
}

# ---------------------------------------------------------------------------
# Finalize — patch hyprland.conf bar references
# ---------------------------------------------------------------------------

_hyprland_finalize() {
    local HYPRCONF="$HOME/.config/hypr/hyprland.conf"

    local BAR_CMD=""
    case $choiceBAR in
        1) BAR_CMD="waybar"       ;;
        2) BAR_CMD="ags"          ;;
        3) BAR_CMD="eww open bar" ;;
        4) BAR_CMD="quickshell"   ;;
    esac

    if [[ -n "$BAR_CMD" ]]; then
        if grep -q 'exec-once = \$bar' "$HYPRCONF"; then
            sed -i "s|exec-once = \\\$bar.*|exec-once = ${BAR_CMD}|" "$HYPRCONF"
        elif ! grep -q "exec-once = ${BAR_CMD}" "$HYPRCONF"; then
            sed -i "/^exec-once/a exec-once = ${BAR_CMD}" "$HYPRCONF"
        fi
    fi

    case $choiceBAR in
        1) sed -i 's|exec, killall waybar || waybar|exec, killall waybar \|\| waybar|' "$HYPRCONF" ;;
        2) sed -i "s|exec, killall waybar || waybar|exec, killall ags \|\| ags|"       "$HYPRCONF" ;;
        3) sed -i "s|exec, killall waybar || waybar|exec, eww close-all \|\| eww open bar|" "$HYPRCONF" ;;
        4) sed -i "s|exec, killall waybar || waybar|exec, killall quickshell \|\| quickshell|" "$HYPRCONF" ;;
        5) sed -i '/killall waybar/d' "$HYPRCONF" ;;
    esac

    echo "Hyprland setup complete."
    echo "Bar chosen: ${BAR_CMD:-none}"
}
