#!/usr/bin/env bash
# install packages

echo "::group::===========================> Install packages"

set -ouex pipefail

declare -a packages=(
    # ========> system
    base
    cachyos/linux-cachyos
    chaotic-aur/bootc
    cpio
    dbus
    dbus-glib
    dracut
    efibootmgr
    linux-firmware
    ostree
    shadow
    shim
    skopeo
    udev
    apparmor
    sudo

    # ========> cli
    bash
    bash-completion
    curl
    git
    glibc-locales
    jq
    less
    lsof
    man-db
    nano
    openssh
    powertop
    python3
    tar
    unzip
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
    fzf
    fd
    just
    socat
    trash-cli
    inotify-tools
    htop
    smartmontools
    ethtool
    chezmoi
    libxcrypt-compat  # homebrew dependency

    # ========> filesystems
    btrfs-progs
    dosfstools
    e2fsprogs
    exfatprogs
    ntfs-3g
    xfsprogs
    nfs-utils
    udftools

    # ========> hardware
    acpid
    amd-ucode
    intel-ucode
    bluez
    bluez-utils
    cups
    cups-browsed
    ddcutil
    intel-media-driver
    iio-sensor-proxy
    lm_sensors
    libva-intel-driver
    libva-mesa-driver
    vpl-gpu-rt
    vulkan-icd-loader
    vulkan-intel
    vulkan-radeon
    xf86-video-amdgpu
    zram-generator
    fprintd
    brightnessctl
    power-profiles-daemon
    thermald
    fwupd
    upower
    blueman

    # ========> display & graphics
    mesa
    mesa-utils
    wayland-utils
    xwayland-satellite

    # ========> audio
    alsa-firmware
    linux-firmware-intel
    pipewire
    pipewire-audio
    pipewire-ffado
    pipewire-jack
    pipewire-libcamera
    pipewire-pulse
    pipewire-zeroconf
    rtkit
    sof-firmware
    wireplumber
    pamixer
    lsp-plugins

    # ========> network
    firewalld
    libmtp
    networkmanager
    networkmanager-openconnect
    networkmanager-openvpn
    network-manager-applet
    nss-mdns
    avahi
    udiskie
    udisks2

    # ========> containers & virt
    distrobox
    podman
    podman-compose
    flatpak
    libvirt
    virt-manager
    qemu-full
    bridge-utils
    dnsmasq

    # ========> wayland / niri stack
    niri
    cage
    swaylock
    swayidle
    swaybg
    fuzzel
    wl-clipboard
    wlsunset
    kanshi
    grim
    slurp
    cliphist
    wl-clip-persist
    playerctl
    xdg-desktop-portal
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
    xdg-user-dirs
    xdg-utils
    polkit-kde-agent
    shared-mime-info
    swayosd
    swaync

    # ========> display manager
    greetd
    greetd-gtkgreet

    # ========> interface / theming
    accountsservice
    chaotic-aur/bibata-cursor-theme
    chaotic-aur/darkly-qt6-git
    matugen
    chaotic-aur/noctalia-shell
    qt5ct
    qt6ct
    kvantum
    papirus-icon-theme
    orchis-theme
    gnome-keyring
    libappindicator
    evolution-data-server
    glycin
    nwg-look

    # ========> terminals
    alacritty
    kitty

    # ========> file management
    yazi
    nemo
    gvfs
    gvfs-mtp
    gvfs-gphoto2
    gvfs-smb
    gvfs-nfs

    # ========> media
    ffmpeg
    ffmpegthumbs
    gst-libav
    gst-plugins-bad
    gst-plugins-base
    gst-plugins-good
    gst-plugins-ugly
    libdvdcss
    libglvnd
    librsvg
    mpv
    swayimg

    # ========> fonts
    gnu-free-fonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra
    ttf-ibm-plex
    ttf-dejavu
    ttf-liberation
    ttf-font-awesome
    unicode-emoji
    ttf-jetbrains-mono-nerd
    cabextract  # for install-msfonts.sh

    # ========> applications
    bazaar
    chaotic-aur/distroshelf
    chaotic-aur/zen-browser-bin
    cachyos/scx-manager
    scx-scheds
    scx-tools
    flatseal
    mission-center
    ark

    # ========> hardware utils
    keyd

    # ========> browsers
    chaotic-aur/helium-browser-bin

    # ========> android
    waydroid
    lzip

    # ========> AUR helper
    yay
)

# system_files pre-populates some paths that packages also own; stash them so
# pacman doesn't hit a "file exists in filesystem" conflict, then restore after.
declare -a _STASH=(
    /usr/share/xdg-desktop-portal/niri-portals.conf
    /usr/lib/sysusers.d/greetd.conf
)
mkdir -p /tmp/sys-stash
for _f in "${_STASH[@]}"; do
    [[ -f "$_f" ]] && mv "$_f" /tmp/sys-stash/
done

pacman -Sy --noconfirm "${packages[@]}" >/dev/null

for _f in "${_STASH[@]}"; do
    _s="/tmp/sys-stash/$(basename "$_f")"
    [[ -f "$_s" ]] && cp "$_s" "$_f"
done
unset _STASH _f _s

# install build tools as deps so they're swept as orphans after compilation
pacman -S --noconfirm --asdeps gcc binutils

# yay requires a non-root user
useradd -m builduser
echo "builduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
su - builduser -c "yay -S --noconfirm bluetuith uupd dropbox xdg-desktop-portal-termfilechooser adw-gtk3"
userdel -r builduser
sed -i '/builduser/d' /etc/sudoers

# remove orphaned build deps (gcc, binutils, go, etc.) — yay stays
pacman -Rns --noconfirm $(pacman -Qqdt) 2>/dev/null || true

echo "::endgroup::"
