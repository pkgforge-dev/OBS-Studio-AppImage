#!/bin/sh

set -eux
ARCH="$(uname -m)"
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	base-devel         \
	curl               \
	git                \
	libfdk-aac         \
	libxtst            \
	obs-studio         \
	pipewire-audio     \
	pulseaudio         \
	pulseaudio-alsa    \
	qrcodegencpp-cmake \
	qt6ct              \
	wget               \
	xorg-server-xvfb   \
	zsync

if [ "$ARCH" = 'x86_64' ]; then
		pacman -Syu --noconfirm libva-intel-driver
fi

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh --add-common --prefer-nano intel-media-driver-mini
