#!/bin/sh

set -eux

ARCH="$(uname -m)"
URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

VERSION="$(pacman -Q obs-studio | awk 'NR==1 {print $2; exit}')"
[ -n "$VERSION"] && echo "$VERSION" > ~/version

export ADD_HOOKS="self-updater.bg.hook"
export OUTNAME=OBS-Studio-"$VERSION"-anylinux-"$ARCH".AppImage
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DESKTOP=/usr/share/applications/com.obsproject.Studio.desktop
export ICON=/usr/share/icons/hicolor/256x256/apps/com.obsproject.Studio.png 
export DEPLOY_LOCALE=1
export DEPLOY_OPENGL=1 
export DEPLOY_PIPEWIRE=1

# ADD LIBRARIES
wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun
chmod +x ./quick-sharun
./quick-sharun /usr/bin/obs* /usr/lib/libobs* /usr/lib/obs-*/*

# MAKE APPIMAGE WITH URUNTIME
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime2appimage
chmod +x ./uruntime2appimage
./uruntime2appimage

# make appbundle
UPINFO="$(echo "$UPINFO" | sed 's#.AppImage.zsync#*.AppBundle.zsync#g')"
wget --retry-connrefused --tries=30 \
	"https://github.com/xplshn/pelf/releases/latest/download/pelf_$ARCH" -O ./pelf
chmod +x ./pelf
echo "Generating [dwfs]AppBundle..."
./pelf --add-appdir ./AppDir \
	--appbundle-id="com.obsproject.Studio#github.com/$GITHUB_REPOSITORY:$VERSION@$(date +%d_%m_%Y)" \
	--appimage-compat \
	--disable-use-random-workdir \
	--add-updinfo "$UPINFO" \
	--compression "-C zstd:level=22 -S26 -B8" \
	--output-to "OBS-Studio-$VERSION-anylinux-$ARCH.dwfs.AppBundle"
zsyncmake ./*.AppBundle -u ./*.AppBundle
echo "All Done!"
