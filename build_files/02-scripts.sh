#!/usr/bin/env bash
# run install scripts

echo "::group::===========================> Run install scripts"

set -ouex pipefail

bash /build/scripts/install-msfonts.sh
bash /build/scripts/install-oreo-cursors.sh
bash /build/scripts/setup-greetd.sh

# bake dotfiles snapshot (no .git — user sets up remote after first boot)
DOTFILES_OWNER="${DOTFILES_OWNER:-samuelueluel}"
git clone --depth=1 "https://github.com/${DOTFILES_OWNER}/dotfiles.git" /usr/share/samuel-arch/dotfiles
rm -rf /usr/share/samuel-arch/dotfiles/.git

chmod +x \
    /usr/bin/sjust \
    /usr/bin/cliphist-pick \
    /usr/bin/cliphist-preview \
    /usr/bin/niri-complement-column \
    /usr/bin/niri-minimap \
    /usr/bin/niri-nav \
    /usr/bin/niri_parse_keybinds.py \
    /usr/bin/niri-tile-toggle \
    /usr/bin/smart-close.sh

echo "::endgroup::"
