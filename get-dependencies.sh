#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	kvantum                   \
	libfdk-aac                \
	libxtst                   \
	luajit                    \
	lxqt-qtplugin             \
	obs-studio                \
	obs-studio-plugin-browser \
	pipewire-audio            \
	pipewire-jack             \
	qrcodegencpp-cmake        \
	qt6ct

if [ "$ARCH" = 'x86_64' ]; then
		pacman -Syu --noconfirm libva-intel-driver
fi

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano intel-media-driver-mini

