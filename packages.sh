#!/bin/bash

# Package lists stored in arrays for easier maintenance

# Base drivers required for all setups
base_drivers=(
    mesa
    xorg-server
    xorg-xinit
    mesa-utils
)

# Intel-specific drivers
intel_drivers=(
    intel-media-driver
    libva-intel-driver
    vulkan-intel
)

# AMD-specific drivers
amd_drivers=(
    libva-mesa-driver
    vulkan-radeon
    xf86-video-amdgpu
    xf86-video-ati
)

# NVIDIA-specific drivers (open-source)
nvidia_drivers=(
    libva-mesa-driver
    vulkan-nouveau
    xf86-video-nouveau
)

# VMware-specific drivers (for virtual machines)
vmware_drivers=(
    xf86-video-vmware
)

gnome_packages=(
    gdm xdg-user-dirs-gtk power-profiles-daemon nautilus
    gnome-text-editor papers adwaita-icon-theme xdg-desktop-portal-gnome
    baobab gnome-shell gnome-control-center gnome-settings-daemon
    gnome-session gnome-tweaks gnome-calculator gnome-disk-utility
    gnome-online-accounts gvfs-google gvfs loupe gnome-menus
    gnome-software decibels mission-center showtime qbittorrent
    gnome-themes-extra pavucontrol
)

kde_packages=(
    sddm xdg-user-dirs plasma-desktop dolphin kate spectacle
    plasma-nm plasma-pa powerdevil kscreen kinfocenter breeze-icons
    xdg-desktop-portal-kde kcalc ark partitionmanager systemsettings
    plasma-workspace plasma-systemmonitor kde-gtk-config bluedevil
    discover filelight kdeplasma-addons okular gwenview sddm-kcm
    dolphin-plugins elisa power-profiles-daemon qbittorrent
)

hyprland_packages=(
    xdg-desktop-portal xdg-desktop-portal-wlr ly xdg-user-dirs
    pavucontrol power-profiles-daemon polkit polkit-qt6 nautilus
)

base_packages=(
    dconf bluez bluez-utils git curl wget pacman-contrib
    unzip unrar 7zip tar python-pip os-prober ufw zip timeshift
    fuse2 openssh cronie ntfs-3g
)

rendering_packages=(
    imagemagick ffmpeg poppler gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav
    x264 x265 libvpx aom dav1d rav1e svt-av1 libfdk-aac faad2 lame libmad opus flac mkvtoolnix-cli
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
    hyprland wlogout hypridle wofi hyprpaper swaync 
    hyprshot xdg-desktop-portal-hyprland 
    polkit-gnome qt5-wayland qt6-wayland light hyprlock
    ghostty waypaper hyprpicker
    aylurs-gtk-shell-git wireplumber libgtop btop 
    dart-sass wl-clipboard brightnessctl swww python upower
    gvfs gtksourceview3 libsoup3 grimblast-git wf-recorder-git hyprpicker 
    matugen-bin python-gpustat hyprsunset-git ags-hyprpanel-git
)

extra=(
    upscayl-desktop-git stremio parsec-bin
    obsidian pokemon-colorscripts-git vscodium gimp kdenlive
    audacity vesktop komikku raider bottles gearlever
    flatseal switcheroo spotify-launcher 
    obs-studio
)

gaming_nvidia_proprietary=(
    heroic-games-launcher-bin steam lutris gamescope mangohud
    wine winetricks vkd3d lib32-nvidia-utils glfw mangojuice
    wqy-zenhei protonplus gamemode lib32-gamemode jdk21-openjdk
    steam-native-runtime
)

gaming=(
    heroic-games-launcher-bin steam lutris gamescope mangohud
    wine winetricks vkd3d glfw mangojuice wqy-zenhei
    protonplus gamemode lib32-gamemode jdk21-openjdk
    steam-native-runtime
)

cachyos_kernel=(
    linux-cachyos linux-cachyos-headers 
)

cachyos_bore_kernel=(
    linux-cachyos-bore linux-cachyos-bore-headers
)

cachyos_base=(
    bpf chwd scx-manager
    scx-scheds cachyos-settings
)

gnome_extra=(
    extension-manager gapless refine
)

emulators_aur=(
    melonds-git azahar shadps4-git mgba-qt-git rpcs3-git
    pcsx2-git duckstation-git ryujinx-canary cemu-git
    dolphin-emu-git kega-fusion ppsspp-git vita3k-git
    mesen2-git
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

install_video_drivers() {
    # Install base drivers
    echo "Installing base video drivers"
    install_pacman "${base_drivers[@]}"

    # Detect GPU(s) using lspci
    if ! command -v lspci &> /dev/null; then
        echo "lspci not found, installing pciutils"
        install_pacman pciutils
    fi

    # Check for Intel GPU
    if lspci | grep -iE "VGA|3D|Display" | grep -i intel &> /dev/null; then
        echo "Detected Intel GPU, installing Intel drivers"
        install_pacman "${intel_drivers[@]}"
    fi

    # Check for AMD GPU
    if lspci | grep -iE "VGA|3D|Display" | grep -i amd &> /dev/null; then
        echo "Detected AMD GPU, installing AMD drivers"
        install_pacman "${amd_drivers[@]}"
    fi

    # Check for NVIDIA GPU
    if lspci | grep -iE "VGA|3D|Display" | grep -i nvidia &> /dev/null; then
        echo "Detected NVIDIA GPU, installing open-source NVIDIA drivers"
        install_pacman "${nvidia_drivers[@]}"
    fi

    # Check if running in VMware
    if lspci | grep -i vmware &> /dev/null; then
        echo "Detected VMware environment, installing VMware drivers"
        install_pacman "${vmware_drivers[@]}"
    fi
}