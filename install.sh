#!/bin/bash
set -e

source packages.sh
source header.sh

check_prerequisites
update_mirrors
set_variables
choose_de
install_basic_features
aur_setup
terminal_setup
install_video_drivers
gaming_setup
zen_kernel_setup
extra_setup
grub_setup

echo "Installation complete. Reboot required to apply changes."
read -p "Reboot now? (y/N): " reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    echo "Rebooting in 5 seconds..."
    sleep 5
    reboot
else
    echo "Please reboot manually to apply changes."
fi
