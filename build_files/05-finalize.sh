#!/usr/bin/env bash
# finalize image build

echo "::group::===========================> Finalize image build"

set -ouex pipefail

# set a root password so emergency shell is accessible if boot fails
echo "root:root" | chpasswd

# generate initramfs with dracut
KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "\.img$" | tail -n 1)")"
DRACUT_NO_XATTR=1 dracut --force --no-hostonly --reproducible --zstd --verbose --add "systemd systemd-initrd ostree" --install "mount.composefs" --add-drivers "composefs" --kver "$KERNEL_VERSION" "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"

# arrange filesystem for bootc, see https://bootc-dev.github.io/bootc/filesystem.html

# clear tempfiles
rm -rf /tmp/* /run/*

# remove target directories
rm -rf /{boot,home,opt,root,srv,mnt,var,usr/local}
rm -rf /usr/lib/sysimage/{log,cache/pacman/pkg}
rm -rf /build

# (re)create essential system directories
mkdir -p /sysroot /boot /usr/lib/ostree /var

# bootc filesystem layout symlinks
ln -sT sysroot/ostree /ostree
ln -sT var/roothome /root
ln -sT var/srv /srv
ln -sT var/mnt /mnt
ln -sT var/opt /opt
ln -sT var/home /home
ln -sT var/usrlocal /usr/local

echo "::endgroup::"
