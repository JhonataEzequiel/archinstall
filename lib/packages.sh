#!/bin/bash

base_packages=(
    dconf bluez bluez-utils git wget pacman-contrib
    unzip unrar 7zip tar python-pip ufw zip
    openssh ntfs-3g linux-headers ibus flatpak
    python pciutils base-devel
)

printer=(
    cups cups-filters ghostscript gsfonts avahi nss-mdns
)

audio=(
    pipewire pipewire-pulse pipewire-alsa lib32-pipewire
    pipewire-audio pipewire-v4l2 wireplumber
)

gnome_packages=(
    gdm xdg-user-dirs-gtk nautilus
    gnome-text-editor papers adwaita-icon-theme xdg-desktop-portal-gnome
    baobab gnome-shell gnome-control-center gnome-settings-daemon
    gnome-session gnome-tweaks gnome-calculator gnome-disk-utility
    gnome-online-accounts gvfs-google gvfs loupe gnome-menus
    decibels mission-center showtime qbittorrent
    gnome-themes-extra pavucontrol gnome-keyring gvfs-goa
    gvfs-afc gvfs-mtp gvfs-nfs gvfs-smb gvfs-wsdd gvfs-dnssd
    gvfs-gphoto2 gvfs-onedrive gnome-software nautilus-python
)

kde_packages=(
    xdg-user-dirs plasma-desktop dolphin kate spectacle
    plasma-nm plasma-pa powerdevil kscreen kinfocenter breeze-icons
    xdg-desktop-portal-kde kcalc ark partitionmanager systemsettings
    plasma-workspace plasma-systemmonitor kde-gtk-config bluedevil
    discover filelight kdeplasma-addons okular gwenview plasma-login-manager
    dolphin-plugins elisa qbittorrent
    plasma-wayland-protocols haruna kwalletmanager
)

# Base Hyprland packages — bar, launcher, and screenshot tool installed separately
hyprland_packages=(
    xdg-desktop-portal-hyprland xdg-user-dirs-gtk
    pavucontrol polkit hyprpolkitagent ly hyprland hyprpaper
    hypridle hyprlock hyprpicker cliphist network-manager-applet
    swaync brightnessctl playerctl waybar
    qt5-wayland qt6-wayland
    hyprutils hyprcursor
)

# Hyprland — launchers: 1=wofi  2=rofi-wayland  3=walker-bin
hyprland_launchers=(wofi rofi-wayland walker-bin)

# Hyprland — screenshot stack
hyprland_screenshot=(grimblast grim slurp)

# Zsh plugins
zsh_plugins=(zsh-autosuggestions zsh-syntax-highlighting zsh-completions)

# Mirror management
mirrors_prereqs=(reflector curl)

rendering_packages=(
    imagemagick ffmpeg poppler
    gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav
    x264 x265 libvpx aom dav1d rav1e svt-av1
    libfdk-aac faad2 lame libmad opus flac mkvtoolnix-cli
)

terminal_packages=(
    dysk tealdeer btop fastfetch bat fd eza fzf zoxide ripgrep yazi wl-clipboard resvg
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
    nvidia-open-dkms
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
    egl-gbm
    egl-x11
)

vmware_drivers=(
    xf86-video-vmware
)

wine_and_dependencies=(
    wine-staging winetricks giflib libpng libldap gnutls mpg123 openal v4l-utils
    libpulse alsa-plugins alsa-lib libjpeg-turbo libxcomposite libxinerama
    ncurses opencl-icd-loader libxslt libva gtk3 gst-plugins-base-libs
    vulkan-icd-loader
)

extra=(
    upscayl-desktop-git parsec-bin
    obsidian pokemon-colorscripts-git gimp kdenlive
    audacity komikku raider bottles gearlever
    flatseal switcheroo
    obs-studio discord libreoffice-still
    octopi vscodium
)

gaming=(
    heroic-games-launcher-bin mangohud
    wine vkd3d glfw mangojuice wqy-zenhei
    jdk21-openjdk
    steam
)

gnome_extra=(
    extension-manager gapless gradia numix-folders-git numix-circle-icon-theme-git bazaar-git
)

# --- Package management helpers ---

install_pacman() {
    sudo pacman -S --needed --noconfirm "$@"
}

install_yay() {
    yay -S --needed --noconfirm "$@"
}

install_flatpak() {
    flatpak install -y --noninteractive flathub "$@"
}

remove_pacman() {
    sudo pacman -R --noconfirm "$@"
}

remove_yay() {
    yay -R --noconfirm "$@"
}

remove_flatpak() {
    flatpak remove -y --noninteractive "$@"
}
