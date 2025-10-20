#!/bin/bash

# List of extension UUIDs to toggle (leave empty to disable ALL enabled extensions)
# To get UUIDs: gnome-extensions list --enabled
EXTENSIONS_TO_TOGGLE=()

# Function to disable extensions

get_extensions(){
    if [ ${#EXTENSIONS_TO_TOGGLE[@]} -eq 0 ]; then
        # Disable all enabled extensions
        mapfile -t EXTENSIONS_TO_TOGGLE < <(gnome-extensions list --enabled)
    fi
}

disable_extensions() {
    get_extensions
    for ext in "${EXTENSIONS_TO_TOGGLE[@]}"; do
        gnome-extensions disable "$ext"
    done
}

# Function to re-enable extensions
enable_extensions() {
    get_extensions
    for ext in "${EXTENSIONS_TO_TOGGLE[@]}"; do
        gnome-extensions enable "$ext"
    done
}

case "$1" in
    "start")
        disable_extensions
        ;;
    "end")
        enable_extensions
        ;;
esac