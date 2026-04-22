#!/usr/bin/env bash
# enable/disable systemd services

echo "::group::===========================> Configure systemd"

set -ouex pipefail

systemctl enable --root=/ \
    greetd.service \
    bluetooth.service \
    NetworkManager.service \
    firewalld.service \
    avahi-daemon.service \
    acpid.service \
    apparmor.service \
    cups.service \
    power-profiles-daemon.service \
    thermald.service \
    scx_loader.service \
    fstrim.timer \
    xfs_scrub_all.timer \
    uupd.timer \
    libvirtd.socket \
    waydroid-container.service \
    keyd.service

systemctl disable --root=/ \
    gdm.service \
    sddm.service \
    flatpak-system-update.timer \
    brew-update.timer || true

echo "::endgroup::"
