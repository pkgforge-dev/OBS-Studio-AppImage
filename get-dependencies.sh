#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	libfdk-aac         \
	libxtst            \
	luajit             \
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

# TODO do proper matrix to make separate build
if true; then 
	git clone --depth 1 https://aur.archlinux.org/obs-studio-browser.git ./obs
	cd ./obs
	sed -i -e 's|-DENABLE_BROWSER=OFF|-DENABLE_BROWSER=ON -DCEF_ROOT_DIR="$srcdir"/../cef_binary_*|' ./PKGBUILD
	wget "https://cdn-fastly.obsproject.com/downloads/cef_binary_6533_linux_${ARCH}_v6.tar.xz" -O /tmp/cef.tar.xz
	tar xvf /tmp/cef.tar.xz
	make-aur-package
else
	pacman -Syu --noconfirm obs-studio
fi
