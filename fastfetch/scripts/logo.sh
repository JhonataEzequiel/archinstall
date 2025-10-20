#!/usr/bin/env bash
# ------------------------------------------------------------
# Random-logo picker for fastfetch
#   • Only scans ~/.config/fastfetch/logo/*.png
#   • Uses `shuf` (true random) – falls back to $RANDOM if shuf missing
#   • Prints a single absolute path (fastfetch receives it via $(…))
# ------------------------------------------------------------

# ---- 1. Folder that holds the images ---------------------------------
logo_dir="${HOME}/.config/fastfetch/logo"

# ---- 2. Bail out early if the folder is empty ------------------------
if ! ls "${logo_dir}"/*.png >/dev/null 2>&1; then
    # No PNGs – fastfetch will just skip the logo (or you can echo a fallback)
    exit 0
fi

# ---- 3. Build a list of PNG files ------------------------------------
mapfile -t pngs < <(printf '%s\n' "${logo_dir}"/*.png)

# ---- 4. Random selection ---------------------------------------------
if command -v shuf >/dev/null 2>&1; then
    # Preferred – true shuffle
    selected="${pngs[RANDOM % ${#pngs[@]}]}"
else
    # Fallback for systems without shuf (very unlikely)
    selected="${pngs[$((RANDOM % ${#pngs[@]}))]}"
fi

# ---- 5. Output the absolute path (fastfetch expects this) ------------
printf '%s\n' "$selected"
