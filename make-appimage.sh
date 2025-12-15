#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q obs-studio | awk '{print $2; exit}') # example command to get version of application here
export ARCH VERSION
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DESKTOP=/usr/share/applications/com.obsproject.Studio.desktop
export ICON=/usr/share/icons/hicolor/256x256/apps/com.obsproject.Studio.png 
export DEPLOY_LOCALE=1
export DEPLOY_OPENGL=1 
export DEPLOY_PIPEWIRE=1

# Deploy dependencies
quick-sharun \
	/usr/bin/obs*  \
	/usr/lib/obs*  \
	/usr/lib/libobs*

# Turn AppDir into AppImage
quick-sharun --make-appimage

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
mv -v ./*.AppBundle* ./dist
echo "All Done!"
