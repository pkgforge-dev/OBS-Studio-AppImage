#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	libfdk-aac         \
	libxtst            \
	obs-studio         \
	pipewire-audio     \
	pipewire-jack      \
	qrcodegencpp-cmake \
	qt6ct

if [ "$ARCH" = 'x86_64' ]; then
		pacman -Syu --noconfirm libva-intel-driver
fi

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano intel-media-driver-mini

# Comment this out if you need an AUR package
#get-aur-package PACKAGENAME

# If the application needs to be manually built that has to be done down here
