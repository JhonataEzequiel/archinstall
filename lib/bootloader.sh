#!/bin/bash
# bootloader.sh — Bootloader selection: GRUB, systemd-boot, rEFInd, Limine

# ---------------------------------------------------------------------------
# Selection
# ---------------------------------------------------------------------------

bootloader_setup() {
    echo "Choose a bootloader:"
    echo "1) GRUB         (feature-rich, great dual-boot support, themes available)"
    echo "2) systemd-boot (simple, fast, integrated with systemd)"
    echo "3) rEFInd       (graphical, auto-detects OSes — best for dual-boot)"
    echo "4) Limine       (modern, minimal, fast)  [default]"
    echo "5) Skip         (keep existing bootloader)"
    read -p "Enter 1-5 [4]: " choiceBL
    choiceBL=${choiceBL:-4}

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

# ---------------------------------------------------------------------------
# GRUB
# ---------------------------------------------------------------------------

_install_grub() {
    install_yay "${grub_packages[@]}"
    sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
    sudo systemctl enable --now grub-btrfsd

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
            (cd LainGrubTheme && ./install.sh && ./patch_entries.sh)
            rm -rf LainGrubTheme
            ;;
        2|3|4|5)
            git clone https://github.com/vinceliuice/grub2-themes.git
            local res="1080p"
            local resolutions=("1080p" "2k" "4k" "ultrawide" "ultrawide2k")
            echo "Select your display resolution:"
            for i in "${!resolutions[@]}"; do echo "$((i+1))) ${resolutions[i]}"; done
            read -p "Enter 1-${#resolutions[@]} (default: 1080p): " res_choice
            [[ "$res_choice" =~ ^[1-5]$ ]] && res="${resolutions[$((res_choice-1))]}"
            (
                cd grub2-themes && chmod +x install.sh
                case $choiceGRUB in
                    2) sudo ./install.sh -t tela     -s "$res" ;;
                    3) sudo ./install.sh -t stylish  -s "$res" ;;
                    4) sudo ./install.sh -t vimix    -s "$res" ;;
                    5) sudo ./install.sh -t whitesur -s "$res" ;;
                esac
            )
            rm -rf grub2-themes
            ;;
        6)
            git clone https://github.com/shvchk/fallout-grub-theme.git
            (cd fallout-grub-theme && chmod +x install.sh && ./install.sh)
            rm -rf fallout-grub-theme
            ;;
        *)
            echo "No GRUB theme applied."
            ;;
    esac
}

# ---------------------------------------------------------------------------
# systemd-boot
# ---------------------------------------------------------------------------

_install_systemd_boot() {
    sudo bootctl install
    sudo mkdir -p /boot/loader/entries

    local ROOT_PARTUUID
    ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$(findmnt -n -o SOURCE /)")

    sudo tee /boot/loader/loader.conf > /dev/null << EOF
default arch.conf
timeout 5
console-mode max
editor no
EOF

    sudo tee /boot/loader/entries/arch.conf > /dev/null << EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=${ROOT_PARTUUID} rw quiet
EOF

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
        sudo tee /boot/loader/entries/windows.conf > /dev/null << EOF
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

# ---------------------------------------------------------------------------
# rEFInd
# ---------------------------------------------------------------------------

_install_refind() {
    install_pacman refind
    sudo refind-install
    echo "rEFInd installed. It auto-detects bootable entries on next reboot."
    echo "Optionally customize /boot/EFI/refind/refind.conf for themes/options."
}

# ---------------------------------------------------------------------------
# Limine
# ---------------------------------------------------------------------------

_install_limine() {
    install_yay limine

    # -----------------------------------------------------------------------
    # Detect the ESP (EFI System Partition) — expected to be mounted at /boot
    # as a dedicated FAT32 partition (e.g. 3 GB, separate from root btrfs).
    # -----------------------------------------------------------------------
    local ESP_DEV ESP_DISK
    ESP_DEV=$(findmnt -n -o SOURCE /boot 2>/dev/null)

    if [[ -z "$ESP_DEV" ]]; then
        echo "ERROR: Could not find a partition mounted at /boot."
        echo "Make sure your FAT32 ESP is mounted at /boot before running this script."
        return 1
    fi

    # Resolve symlinks (e.g. /dev/disk/by-uuid/... → /dev/sda1)
    ESP_DEV=$(realpath "$ESP_DEV")
    # Parent disk: strip trailing digits and 'p' for NVMe (nvme0n1p1 → nvme0n1)
    ESP_DISK=$(lsblk -no PKNAME "$ESP_DEV" 2>/dev/null | head -1)

    if [[ -z "$ESP_DISK" ]]; then
        echo "ERROR: Could not determine parent disk of $ESP_DEV."
        return 1
    fi

    echo "ESP detected: $ESP_DEV  (disk: /dev/$ESP_DISK)"

    # -----------------------------------------------------------------------
    # UEFI install — copy the EFI binary into the ESP.
    # limine bios-install is NOT needed on pure UEFI systems.
    # -----------------------------------------------------------------------
    sudo mkdir -p /boot/EFI/limine
    sudo cp /usr/share/limine/BOOTX64.EFI /boot/EFI/limine/

    # Register with the UEFI firmware (requires efibootmgr)
    if ! command -v efibootmgr &>/dev/null; then
        install_pacman efibootmgr
    fi

    # Get the partition number (e.g. sda1 → 1, nvme0n1p1 → 1)
    local ESP_PARTNUM
    ESP_PARTNUM=$(cat /sys/class/block/"$(basename "$ESP_DEV")"/partition 2>/dev/null || echo "1")

    sudo efibootmgr \
        --create \
        --disk "/dev/$ESP_DISK" \
        --part "$ESP_PARTNUM" \
        --label "Limine" \
        --loader "\\EFI\\limine\\BOOTX64.EFI" \
        --unicode || {
            echo "WARNING: efibootmgr failed — Limine EFI binary is in place but"
            echo "no boot entry was created. Add one manually or via your UEFI firmware."
        }

    # -----------------------------------------------------------------------
    # Build limine.cfg
    # Root partition PARTUUID (the btrfs partition, not /boot)
    # -----------------------------------------------------------------------
    local ROOT_PARTUUID
    ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$(findmnt -n -o SOURCE /)" 2>/dev/null)

    if [[ -z "$ROOT_PARTUUID" ]]; then
        echo "ERROR: Could not determine PARTUUID of root partition."
        return 1
    fi

    # Determine active kernel via pacman (reliable even right after install/removal)
    # Falls back to file-based detection so it also works on already-installed systems.
    local KERNEL_IMG INITRD_IMG FALLBACK_INITRD
    if pacman -Qq linux-cachyos &>/dev/null; then
        KERNEL_IMG="vmlinuz-linux-cachyos"
        INITRD_IMG="initramfs-linux-cachyos.img"
        FALLBACK_INITRD="initramfs-linux-cachyos-fallback.img"
    elif pacman -Qq linux-zen &>/dev/null; then
        KERNEL_IMG="vmlinuz-linux-zen"
        INITRD_IMG="initramfs-linux-zen.img"
        FALLBACK_INITRD="initramfs-linux-zen-fallback.img"
    elif pacman -Qq linux &>/dev/null; then
        KERNEL_IMG="vmlinuz-linux"
        INITRD_IMG="initramfs-linux.img"
        FALLBACK_INITRD="initramfs-linux-fallback.img"
    else
        # Last resort: scan /boot for any vmlinuz-* file
        local found
        found=$(find /boot -maxdepth 1 -name 'vmlinuz-*' | head -1)
        if [[ -z "$found" ]]; then
            echo "ERROR: No kernel image found. Aborting Limine setup."
            return 1
        fi
        KERNEL_IMG=$(basename "$found")
        local kname="${KERNEL_IMG#vmlinuz-}"
        INITRD_IMG="initramfs-${kname}.img"
        FALLBACK_INITRD="initramfs-${kname}-fallback.img"
        echo "WARNING: Kernel detected by file scan: ${KERNEL_IMG}"
    fi

    # Build the kernel cmdline — rootflags=subvol=@ only applies to btrfs
    local ROOT_FSTYPE
    ROOT_FSTYPE=$(findmnt -n -o FSTYPE / 2>/dev/null)
    local CMDLINE
    if [[ "$ROOT_FSTYPE" == "btrfs" ]]; then
        CMDLINE="root=PARTUUID=${ROOT_PARTUUID} rootflags=subvol=@ rw quiet loglevel=3"
    else
        CMDLINE="root=PARTUUID=${ROOT_PARTUUID} rw quiet loglevel=3"
    fi
    echo "Root filesystem detected: ${ROOT_FSTYPE} — CMDLINE: ${CMDLINE}"

    sudo tee /boot/limine.cfg > /dev/null << EOF
# Limine bootloader configuration
# Full reference: https://limine-bootloader.org/USAGE.html
TIMEOUT=5
GRAPHICS=yes

/:Arch Linux
    PROTOCOL=linux
    KERNEL_PATH=boot():///${KERNEL_IMG}
    CMDLINE=${CMDLINE}
    MODULE_PATH=boot():///${INITRD_IMG}
    MODULE_PATH=boot():///${FALLBACK_INITRD}
EOF

    # -----------------------------------------------------------------------
    # Auto-detect Windows and add a chainload entry
    # -----------------------------------------------------------------------
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
        local WIN_DISK WIN_PARTNUM
        WIN_DISK=$(lsblk -no PKNAME "$WIN_PART")
        WIN_PARTNUM=$(cat /sys/class/block/"$(basename "$WIN_PART")"/partition 2>/dev/null || echo "1")
        sudo tee -a /boot/limine.cfg > /dev/null << EOF

/:Windows
    PROTOCOL=chainload
    DRIVE=/dev/${WIN_DISK}
    PARTITION=${WIN_PARTNUM}
EOF
        echo "Windows detected on ${WIN_PART} — chainload entry added."
    else
        echo "No Windows installation detected. Skipping Windows entry."
    fi

    echo ""
    echo "Limine installed successfully."
    echo "  EFI binary : /boot/EFI/limine/BOOTX64.EFI"
    echo "  Config     : /boot/limine.cfg"
    echo "  Kernel     : ${KERNEL_IMG}  (subvol=@)"
    echo ""
    echo "Edit /boot/limine.cfg to adjust entries or add kernel parameters."
}
