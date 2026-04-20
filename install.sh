#!/bin/bash
set -uo pipefail

source packages.sh
source functions.sh

# Trap erros inesperados com contexto útil
trap 'echo ""; echo "ERRO: falha na linha $LINENO (código $?). Verifique o output acima." >&2' ERR

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
