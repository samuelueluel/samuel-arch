#!/usr/bin/env bash
# run install scripts

echo "::group::===========================> Run install scripts"

set -ouex pipefail

bash /build/scripts/install-msfonts.sh
bash /build/scripts/install-oreo-cursors.sh
bash /build/scripts/setup-greetd.sh

# bake dotfiles snapshot (no .git — user sets up remote after first boot)
# Guarded so forks without the deploy-key secret still build.
mkdir -p /usr/share/samuel-arch/dotfiles
if [[ -n "${DOTFILES_DEPLOY_KEY:-}" ]]; then
    DOTFILES_OWNER="${DOTFILES_OWNER:-samuelueluel}"
    mkdir -p /root/.ssh
    echo "$DOTFILES_DEPLOY_KEY" > /root/.ssh/dotfiles_deploy
    chmod 600 /root/.ssh/dotfiles_deploy
    ssh-keyscan github.com >> /root/.ssh/known_hosts
    GIT_SSH_COMMAND="ssh -i /root/.ssh/dotfiles_deploy" \
        git clone --depth=1 "git@github.com:${DOTFILES_OWNER}/dotfiles.git" /tmp/dotfiles-snapshot
    rsync -a --exclude='.git' /tmp/dotfiles-snapshot/ /usr/share/samuel-arch/dotfiles/
    rm -rf /tmp/dotfiles-snapshot /root/.ssh/dotfiles_deploy
else
    echo "DOTFILES_DEPLOY_KEY not set — skipping dotfiles snapshot."
    echo "Users will need to populate ~/dotfiles manually on first boot."
fi

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
