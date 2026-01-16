#!/usr/bin/env bash
set -euo pipefail

# macOS Tahoe Automatic Full Installer
# This script automates all installation steps from install.sh and includes common extras.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Starting macOS Tahoe Full Automatic Installation...${NC}"

# Check dependencies
echo -e "${GREEN}🔍 Checking dependencies...${NC}"
MISSING_DEPS=()
for cmd in curl git unzip rsync python3; do
    if ! command -v "$cmd" &>/dev/null; then
        MISSING_DEPS+=("$cmd")
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "${YELLOW}❌ Missing required dependencies: ${MISSING_DEPS[*]}${NC}"
    echo -e "${YELLOW}Please install them and try again.${NC}"
    exit 1
fi
echo "  ✓ All dependencies met."

# 1. Install Base Themes (Light & Dark)
echo -e "${GREEN}📦 Installing base themes (Light & Dark)...${NC}"
./install.sh --install-both

# 2. Generate and Install All Accent Variants
echo -e "${GREEN}🎨 Generating all accent color variants...${NC}"
./install.sh --colors

echo -e "${GREEN}🚚 Moving accent variants to ~/.themes...${NC}"
THEME_DIR="$HOME/.themes"
mkdir -p "$THEME_DIR"
shopt -s nullglob
for theme in gtk/Tahoe-Dark-* gtk/Tahoe-Light-*; do
    if [ -d "$theme" ]; then
        bn=$(basename "$theme")
        # Remove existing to avoid nested copies if running again
        rm -rf "$THEME_DIR/$bn"
        cp -ra "$theme" "$THEME_DIR/"
        echo "  ✓ Installed: $bn"
    fi
done
shopt -u nullglob

# 3. Install libadwaita override (Supports Light & Dark)
echo -e "${GREEN}⚙️ Installing libadwaita override (Light/Dark support)...${NC}"
./install.sh -l -la

# 4. Install Wallpapers
echo -e "${GREEN}🖼️ Installing Tahoe wallpapers...${NC}"
./install.sh -w

# 5. Connect Flatpak themes
echo -e "${GREEN}📦 Connecting Flatpak themes...${NC}"
# We run these directly to avoid the interactive prompt in install.sh
if command -v flatpak &>/dev/null; then
    sudo flatpak override --filesystem=xdg-config/gtk-3.0 || true
    sudo flatpak override --filesystem=xdg-config/gtk-4.0 || true
    sudo flatpak override --filesystem=~/.themes || true
    echo "  ✓ Flatpak permissions granted."
else
    echo -e "${YELLOW}  ! Flatpak not found, skipping.${NC}"
fi

# 6. Install Extras (Icons & Cursors)
DOWNLOADS_DIR="$(xdg-user-dir DOWNLOAD 2>/dev/null || echo "$HOME/Downloads")"
mkdir -p "$DOWNLOADS_DIR"

echo -e "${GREEN}📂 Installing MacTahoe icons...${NC}"
if [ ! -d "$DOWNLOADS_DIR/MacTahoe-icon-theme" ]; then
    git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git "$DOWNLOADS_DIR/MacTahoe-icon-theme"
fi
sudo bash "$DOWNLOADS_DIR/MacTahoe-icon-theme/install.sh" -b

echo -e "${GREEN}🖱️ Installing WhiteSur cursors...${NC}"
if [ ! -d "$DOWNLOADS_DIR/WhiteSur-cursors" ]; then
    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-cursors.git "$DOWNLOADS_DIR/WhiteSur-cursors"
fi
sudo bash "$DOWNLOADS_DIR/WhiteSur-cursors/install.sh"

echo -e "${BLUE}✅ Full installation complete!${NC}"
echo -e "${BLUE}Note: You can apply the themes using GNOME Tweaks or Settings.${NC}"
