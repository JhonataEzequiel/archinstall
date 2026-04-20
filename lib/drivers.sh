#!/bin/bash
# drivers.sh — Video driver detection and installation

# ---------------------------------------------------------------------------
# NVIDIA — Hyprland-specific env vars + mkinitcpio
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

# ---------------------------------------------------------------------------
# Driver detection and installation
# ---------------------------------------------------------------------------

install_video_drivers() {
    install_pacman "${base_drivers[@]}"

    local GPU_INFO
    GPU_INFO=$(lspci | grep -iE "VGA|3D|Display" || true)
    local HAS_INTEL HAS_AMD HAS_NVIDIA
    HAS_INTEL=$(echo "$GPU_INFO"  | grep -i intel  || true)
    HAS_AMD=$(echo   "$GPU_INFO"  | grep -i amd    || true)
    HAS_NVIDIA=$(echo "$GPU_INFO" | grep -i nvidia || true)
    IS_HYBRID=false
    [[ -n "$HAS_NVIDIA" && ( -n "$HAS_INTEL" || -n "$HAS_AMD" ) ]] && IS_HYBRID=true
    export IS_HYBRID

    [[ -n "$HAS_INTEL" ]] && install_pacman "${intel_drivers[@]}"
    [[ -n "$HAS_AMD"   ]] && install_pacman "${amd_drivers[@]}"

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
