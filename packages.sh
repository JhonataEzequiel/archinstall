#!/bin/bash

# Package lists stored in arrays for easier maintenance
video_drivers=(
    intel-media-driver libva-intel-driver libva-mesa-driver mesa
    vulkan-intel vulkan-nouveau vulkan-radeon xf86-video-amdgpu
    xf86-video-ati xf86-video-nouveau xf86-video-vmware
    xorg-server xorg-xinit mesa-utils
)

gnome_packages=(
    gdm xdg-user-dirs-gtk power-profiles-daemon nautilus
    gnome-text-editor papers adwaita-icon-theme xdg-desktop-portal-gnome
    baobab gnome-shell gnome-control-center gnome-settings-daemon
    gnome-session gnome-tweaks gnome-calculator gnome-disk-utility
    gnome-online-accounts gvfs-google gvfs loupe gnome-menus
    gnome-software decibels mission-center
)

kde_packages=(
    sddm xdg-user-dirs plasma-desktop dolphin kate spectacle
    plasma-nm plasma-pa powerdevil kscreen kinfocenter breeze-icons
    xdg-desktop-portal-kde kcalc ark partitionmanager systemsettings
    plasma-workspace plasma-systemmonitor kde-gtk-config bluedevil
    discover filelight kdeplasma-addons okular gwenview sddm-kcm
    dolphin-plugins elisa
)

hyprland_packages=(
    xdg-desktop-portal xdg-desktop-portal-wlr sddm xdg-user-dirs
    dolphin ark pavucontrol power-profiles-daemon
)

base_packages=(
    dconf bluez bluez-utils git curl wget pacman-contrib
    unzip unrar p7zip tar python-pip os-prober ufw zip timeshift
    fuse2
)

rendering_packages=(
    imagemagick ffmpeg poppler
)

additional_packages=(
    vlc libreoffice-still thunderbird
)

terminal_packages=(
    dysk tealdeer btop fastfetch bat fd eza fzf zoxide ripgrep yazi wl-clipboard
)

terminal_text_editors=(
    nano vim micro neovim
)

font_packages=(
    noto-fonts-cjk noto-fonts adobe-source-code-pro-fonts
    noto-fonts-emoji otf-font-awesome ttf-droid ttf-fira-code
    ttf-jetbrains-mono-nerd ttf-font-awesome ttf-cascadia-mono-nerd
    ttf-cascadia-code-nerd
)

nvidia_proprietary=(
    egl-gbm egl-x11 nvidia-dkms nvidia-utils nvidia-prime
)

nvidia_open=(
    egl-gbm egl-x11 nvidia-open-dkms nvidia-utils nvidia-prime
)

ms_fonts=(
    ttf-ms-fonts ttf-tahoma ttf-vista-fonts
)

hyprland_aur=(
    hyprland wlogout network-manager-applet blueman hypridle
    waybar wofi hyprpaper swaync kitty pavulcontrol hyprshot
    xdg-desktop-portal-hyprland polkit-kde-agent qt5-wayland
    qt6-wayland light hyprlock
)

extra_aur=(
    proton-vpn-gtk-app upscayl-desktop-git stremio parsec-bin
    obsidian pokemon-colorscripts-git vscodium gimp kdenlive
    qbittorrent audacity obs-studio vesktop
)

gaming_nvidia_proprietary=(
    heroic-games-launcher-bin steam lutris gamescope mangohud
    wine winetricks vkd3d lib32-nvidia-utils glfw goverlay
    wqy-zenhei protonplus gamemode lib32-gamemode jdk21-openjdk
)

gaming=(
    heroic-games-launcher-bin steam lutris gamescope mangohud
    wine winetricks vkd3d glfw goverlay-bin wqy-zenhei
    protonplus gamemode lib32-gamemode jdk21-openjdk
)

cachyos_kernels=(
    linux-cachyos linux-cachyos-headers bpf chwd scx-manager
    scx-scheds
)

emulators_aur=(
    melonds-git azahar shadps4-git mgba-qt-git rpcs3-git
    pcsx2-git duckstation-git ryujinx-canary cemu-git
    dolphin-emu-git kega-fusion ppsspp-git vita3k-git
)

emulators_mixed_aur=(
    melonds-git shadps4-git vita3k-git
)

emulators_flatpak=(
    org.DolphinEmu.dolphin-emu io.mgba.mGBA com.carpeludum.KegaFusion
    org.ppsspp.PPSSPP net.pcsx2.PCSX2 io.github.ryubing.Ryujinx
    org.duckstation.DuckStation info.cemu.Cemu org.azahar_emu.Azahar
    net.rpcs3.RPCS3 com.snes9x.Snes9x
)

emulators_flatpak_complete=(
    org.DolphinEmu.dolphin-emu io.mgba.mGBA com.carpeludum.KegaFusion
    org.ppsspp.PPSSPP net.pcsx2.PCSX2 io.github.ryubing.Ryujinx
    org.duckstation.DuckStation info.cemu.Cemu org.azahar_emu.Azahar
    net.rpcs3.RPCS3 com.snes9x.Snes9x net.shadps4.shadPS4 net.kuribo64.melonDS
)

flatpak_packages=(
    info.febvre.Komikku it.mijorus.gearlever com.github.ADBeveridge.Raider
    com.usebottles.bottles com.github.tchx84.Flatseal
)

# Functions for package installation
install_pacman() {
    sudo pacman -S --needed "$@"
}

install_yay() {
    yay -S --needed "$@"
}

install_flatpak() {
    flatpak install flathub "$@"
}