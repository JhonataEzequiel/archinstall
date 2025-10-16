#!/bin/bash

base_packages=(
    dconf bluez bluez-utils git curl wget pacman-contrib
    unzip unrar 7zip tar python-pip ufw zip timeshift
    fuse2 openssh cronie ntfs-3g linux-headers ibus flatpak
)

audio=(
    pipewire pipewire-pulse pipewire-alsa pipewire-jack lib32-pipewire 
    pipewire-audio pipewire-v4l2 wireplumber
)

gnome_packages=(
    gdm xdg-user-dirs-gtk nautilus
    gnome-text-editor papers adwaita-icon-theme xdg-desktop-portal-gnome
    baobab gnome-shell gnome-control-center gnome-settings-daemon
    gnome-session gnome-tweaks gnome-calculator gnome-disk-utility
    gnome-online-accounts gvfs-google gvfs loupe gnome-menus
    gnome-software decibels mission-center showtime qbittorrent
    gnome-themes-extra pavucontrol gnome-keyring
)

kde_packages=(
    xdg-user-dirs plasma-desktop dolphin kate spectacle
    plasma-nm plasma-pa powerdevil kscreen kinfocenter breeze-icons
    xdg-desktop-portal-kde kcalc ark partitionmanager systemsettings
    plasma-workspace plasma-systemmonitor kde-gtk-config bluedevil
    discover filelight kdeplasma-addons okular gwenview ly
    dolphin-plugins elisa qbittorrent
    plasma-wayland-protocols haruna kwalletmanager
)

hyprland_packages=(
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-user-dirs
    pavucontrol polkit polkit-qt6 dolphin ly
)

rendering_packages=(
    imagemagick ffmpeg poppler gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav
    x264 x265 libvpx aom dav1d rav1e svt-av1 libfdk-aac faad2 lame libmad opus flac mkvtoolnix-cli
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
    ttf-cascadia-code-nerd ttf-ms-fonts
)

base_drivers=(
    mesa
    xorg-server
    xorg-xinit
    mesa-utils
)

intel_drivers=(
    intel-media-driver
    libva-intel-driver
    vulkan-intel
)

amd_drivers=(
    libva-mesa-driver
    vulkan-radeon
    xf86-video-amdgpu
    xf86-video-ati
)

nvidia_drivers=(
    libva-mesa-driver
)

nvidia_common_utils=(
    nvidia-utils
    nvidia-prime
    nvidia-settings 
    lib32-nvidia-utils 
    lib32-opencl-nvidia 
    opencl-nvidia 
    libvdpau 
    libxnvctrl
    vulkan-icd-loader 
    lib32-vulkan-icd-loader
)

nvidia_proprietary=(
    egl-gbm
    egl-x11
    nvidia-dkms
)

nvidia_open=(
    egl-gbm
    egl-x11
    nvidia-open-dkms
)

vmware_drivers=(
    xf86-video-vmware
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
    upscayl-desktop-git parsec-bin
    obsidian pokemon-colorscripts-git gimp kdenlive
    audacity komikku raider bottles gearlever
    flatseal switcheroo spotify-launcher 
    obs-studio discord libreoffice-still
    octopi
)

gaming_nvidia_proprietary=(
    heroic-games-launcher-bin lutris gamescope mangohud
    wine vkd3d lib32-nvidia-utils glfw mangojuice
    wqy-zenhei gamemode lib32-gamemode jdk21-openjdk
    steam-native-runtime corectrl proton-ge-custom-bin
)

gaming=(
    heroic-games-launcher-bin lutris gamescope mangohud
    wine vkd3d glfw mangojuice wqy-zenhei
    gamemode lib32-gamemode jdk21-openjdk
    steam-native-runtime corectrl proton-ge-custom-bin
)

gnome_extra=(
    extension-manager gapless gradia
)

grub_packages=(
    grub grub-btrfs os-prober inotify-tools update-grub
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

emulators_mixed_flatpak=(
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
    sudo pacman -S --needed --noconfirm "$@"
}

install_yay() {
    yay -S --needed --noconfirm "$@"
}

install_flatpak() {
    flatpak install -y --noninteractive flathub "$@"
}

install_video_drivers(){
    # Install base drivers
    echo "Installing base video drivers"
    install_pacman "${base_drivers[@]}"

    # Detect GPU(s) using lspci
    if ! command -v lspci &> /dev/null; then
        echo "lspci not found, installing pciutils"
        install_pacman pciutils
    fi

    GPU_INFO=$(lspci | grep -iE "VGA|3D|Display" || true)
    HAS_INTEL=$(echo "$GPU_INFO" | grep -i intel || true)
    HAS_AMD=$(echo "$GPU_INFO" | grep -i amd || true)
    HAS_NVIDIA=$(echo "$GPU_INFO" | grep -i nvidia || true)
    IS_HYBRID=false
    if [[ -n "$HAS_NVIDIA" && ( -n "$HAS_INTEL" || -n "$HAS_AMD" ) ]]; then
        IS_HYBRID=true
        echo "Hybrid GPU system detected (NVIDIA + Intel/AMD)."
    fi

    # --- Intel drivers ---
    if [[ -n "$HAS_INTEL" ]]; then
        echo "Detected Intel GPU, installing Intel drivers..."
        install_pacman "${intel_drivers[@]}"
    fi

    # --- AMD drivers ---
    if [[ -n "$HAS_AMD" ]]; then
        echo "Detected AMD GPU, installing AMD drivers..."
        install_pacman "${amd_drivers[@]}"
    fi
    if [[ -n "$HAS_NVIDIA" ]]; then
        if [ "$mode" = "1" ]; then
            echo "Detected NVIDIA GPU."
            echo "NVIDIA driver options:"
            echo "1) Proprietary: Better performance, closed-source."
            echo "2) Open: Open-source, may have lower performance."
            echo "3) Minimal: Install only basic NVIDIA support."
            read -p "Enter 1, 2, or 3: " choiceNV
        else
            choiceNV=1
        fi
        case $choiceNV in
            1)
                echo "Installing proprietary NVIDIA drivers"
                install_pacman "${nvidia_proprietary[@]}"
                install_pacman "${nvidia_common_utils[@]}"
                nvidia_setup
                ;;
            2)
                echo "Installing open-source NVIDIA drivers"
                install_pacman "${nvidia_open[@]}"
                install_pacman "${nvidia_common_utils[@]}"
                install_pacman xf86-video-nouveau vulkan-nouveau
                nvidia_setup
                ;;
            *)
                echo "Installing minimal NVIDIA support"
                install_pacman "${nvidia_drivers[@]}"
                install_pacman "${nvidia_common_utils[@]}"
                install_pacman xf86-video-nouveau vulkan-nouveau
                nvidia_setup
                ;;
        esac
    else
        echo "No NVIDIA hardware detected. Skipping NVIDIA driver installation."
        sudo cp /grub/grub /etc/default/grub
        choiceNV=3
    fi
    # Check if running in VMware
    if lspci | grep -i vmware &> /dev/null; then
        echo "Detected VMware environment, installing VMware drivers"
        install_pacman "${vmware_drivers[@]}"
    fi

    # Export choiceNV for use in install.sh
    export choiceNV
}

nvidia_setup(){
    sudo mkdir -p /etc/modprobe.d
    echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf > /dev/null
    echo "Wrote /etc/modprobe.d/nvidia.conf (options nvidia_drm modeset=1)."

    if [[ -n "$IS_HYBRID" == true ]]; then
        if grep -qE '^MODULES=.*\bnvidia\b' /etc/mkinitcpio.conf; then
            echo "NVIDIA modules already present in MODULES, skipping modification."
        else
            sudo sed -i '/^MODULES=/ s/)/ nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
        fi
    fi

    echo "Setting NVIDIA-related environment variables for Wayland..."
    echo -e "GBM_BACKEND=nvidia-drm\n__GLX_VENDOR_LIBRARY_NAME=nvidia\nLIBVA_DRIVER_NAME=nvidia\nNVIDIA_PRIME_RENDER_OFFLOAD=1" | sudo tee -a /etc/environment
    sudo cp grub/grubnvidia /etc/default/grub
    # DE-specific configurations
    if [[ "$choiceDE" == "1" ]]; then
        sudo sed -i '/exit 0/i /usr/bin/prime-run' /etc/gdm/Init/Default
    elif [[ "$choiceDE" == "3" ]]; then
        mkdir -p "${HOME}/.config/hypr"
        # Append env entries only if not already present
        HYPRCONF="${HOME}/.config/hypr/hyprland.conf"
        touch "$HYPRCONF"
        grep -q '^env = GBM_BACKEND,nvidia-drm' "$HYPRCONF" || echo 'env = GBM_BACKEND,nvidia-drm' >> "$HYPRCONF"
        grep -q '^env = LIBVA_DRIVER_NAME,nvidia' "$HYPRCONF" || echo 'env = LIBVA_DRIVER_NAME,nvidia' >> "$HYPRCONF"
        grep -q '^env = __GLX_VENDOR_LIBRARY_NAME,nvidia' "$HYPRCONF" || echo 'env = __GLX_VENDOR_LIBRARY_NAME,nvidia' >> "$HYPRCONF"
        # WLR_NO_HARDWARE_CURSORS=1 is sometimes recommended for NVIDIA+Wayland (Hyprland)
        grep -q '^env = WLR_NO_HARDWARE_CURSORS,1' "$HYPRCONF" || echo 'env = WLR_NO_HARDWARE_CURSORS,1' >> "$HYPRCONF"
    fi
    sudo mkinitcpio -P
}