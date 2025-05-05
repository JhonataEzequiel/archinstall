#!/bin/bash

echo "Do you want my GNOME customization? (Just some extensions, nothing too complicated)"
echo "1) Yes"
echo "2) No"
read -p "Enter 1 or 2: " choiceGNOME

case $choiceGNOME in
    1)
        # Get list of installed extensions (if any)
        EXTENSIONS_FILE="gnome-extensions.txt"
        EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"
        mkdir -p "$EXTENSIONS_DIR"
        INSTALLED_EXTENSIONS=$(ls -1 "$EXTENSIONS_DIR" 2>/dev/null || echo "")

        # Read each UUID from the file and check if it's installed
        while IFS= read -r uuid; do
            # Skip empty lines
            [ -z "$uuid" ] && continue

            # Check if UUID directory exists
            if ! echo "$INSTALLED_EXTENSIONS" | grep -Fx "$uuid" >/dev/null; then
                echo "Extension $uuid is not installed. Installing..."

                # Download the extension ZIP
                ZIP_URL="https://extensions.gnome.org/extension-data/$uuid.shell-extension.zip"
                TEMP_ZIP="/tmp/$uuid.zip"
                if ! curl -s -o "$TEMP_ZIP" "$ZIP_URL"; then
                    echo "Warning: Failed to download $uuid. It may not exist or be unavailable."
                    continue
                fi

                # Extract to extensions directory
                EXTENSION_PATH="$EXTENSIONS_DIR/$uuid"
                mkdir -p "$EXTENSION_PATH"
                if ! unzip -o -q "$TEMP_ZIP" -d "$EXTENSION_PATH"; then
                    echo "Warning: Failed to extract $uuid. ZIP file may be corrupt."
                    rm -f "$TEMP_ZIP"
                    continue
                fi
                rm -f "$TEMP_ZIP"

                # Enable the extension (will apply in next GNOME session)
                if ! gnome-extensions enable "$uuid" 2>/dev/null; then
                    echo "Warning: Could not enable $uuid. It may be incompatible with your GNOME version."
                else
                    echo "Successfully installed and enabled $uuid."
                fi
            else
                echo "Extension $uuid is already installed."
            fi
        done < "$EXTENSIONS_FILE"

        echo "Done checking and installing extensions."
        echo "Extensions will take effect in your next GNOME Shell session."
        echo "After starting GNOME, you may need to restart the shell:"
        echo "- On X11: Alt + F2, type 'r', Enter."
        echo "- On Wayland: Log out and log back in."
        ;;
    2)
        echo "Skipping GNOME customization."
        ;;
    *)
        echo "Invalid input. Please enter 1 or 2. Skipping GNOME customization."
        exit 1
        ;;
esac
