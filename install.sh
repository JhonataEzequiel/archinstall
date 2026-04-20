#!/bin/bash
set -uo pipefail

source packages.sh
source functions.sh

# ---------------------------------------------------------------------------
# Sudo — ask for the password once and keep the cache alive for the entire
# script via a background loop (sudo -v every 60 s).
# The ticket is invalidated and the background process is killed on exit.
# ---------------------------------------------------------------------------
echo "This script requires administrator privileges."
sudo -v || { echo "ERROR: sudo authentication failed."; exit 1; }

( while true; do sudo -v; sleep 60; done ) &
_SUDO_KEEPALIVE_PID=$!

_cleanup() {
    kill "$_SUDO_KEEPALIVE_PID" 2>/dev/null
    sudo -k
}

# Error trap — clean up and print useful context
trap '_cleanup; echo ""; echo "ERROR: failed at line $LINENO (exit code $?). Check the output above." >&2' ERR
# Normal exit trap — always clean up the keepalive
trap '_cleanup' EXIT

check_prerequisites
update_mirrors
set_variables
choose_de
install_basic_features
aur_setup
terminal_text_editors_setup
terminal_setup
shell_setup
wine_setup
cachyos_setup
install_video_drivers
gaming_setup
zen_kernel_setup
extra_setup
hyprland_setup

# Regenerate initramfs for all installed kernels before configuring the bootloader.
echo "Regenerating initramfs for all kernels..."
sudo mkinitcpio -P

bootloader_setup

echo ""
echo "Installation complete. A reboot is required to apply all changes."
read -p "Reboot now? (y/N): " reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    echo "Rebooting in 5 seconds..."
    sleep 5
    reboot
else
    echo "Please reboot manually when ready."
fi
