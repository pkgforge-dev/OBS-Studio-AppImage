#!/bin/sh

set -eu

PACKAGE=obs-studio
DESKTOP=com.obsproject.Studio.desktop
ICON=com.obsproject.Studio.png

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
export VERSION="$(pacman -Q $PACKAGE | awk 'NR==1 {print $2; exit}')"
echo "$VERSION" > ~/version

UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"

# Prepare AppDir
mkdir -p ./AppDir/share
cd ./AppDir

cp -r /usr/share/obs                              ./share
cp -r /usr/share/locale                           ./share
cp -r /usr/share/glvnd                            ./share
cp /usr/share/applications/"$DESKTOP"             ./
cp /usr/share/icons/hicolor/256x256/apps/"$ICON"  ./
cp /usr/share/icons/hicolor/256x256/apps/"$ICON"  ./.DirIcon
ln -s ./ ./usr

# ADD LIBRARIES
wget "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -e -k -s \
	/usr/bin/obs* \
	/usr/lib/libobs* \
	/usr/lib/obs-plugins/* \
	/usr/lib/obs-scripting/* \
	/usr/lib/libcurl.so* \
	/usr/lib/libavutil.so* \
	/usr/lib/libavformat.so* \
	/usr/lib/libavcodec.so* \
	/usr/lib/libswscale.so* \
	/usr/lib/libXt.so* \
	/usr/lib/qt6/plugins/iconengines/* \
	/usr/lib/qt6/plugins/imageformats/* \
	/usr/lib/qt6/plugins/platforms/* \
	/usr/lib/qt6/plugins/platformthemes/* \
	/usr/lib/qt6/plugins/styles/* \
	/usr/lib/qt6/plugins/xcbglintegrations/* \
	/usr/lib/qt6/plugins/wayland-*/* \
	/usr/lib/vdpau/* \
	/usr/lib/alsa-lib/* \
	/usr/lib/pipewire-0.3/* \
	/usr/lib/spa-0.2/*/*

cp -vn /usr/lib/obs-scripting/* ./shared/lib/obs-scripting

# Prepare sharun
ln ./sharun ./AppRun
./sharun -g

# MAKE APPIMAGE WITH URUNTIME
cd ..
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
printf "$UPINFO" > data.upd_info
llvm-objcopy --update-section=.upd_info=data.upd_info \
	--set-section-flags=.upd_info=noload,readonly ./uruntime
printf 'AI\x02' | dd of=./uruntime bs=1 count=3 seek=8 conv=notrunc

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S26 -B32 \
	--header uruntime \
	-i ./AppDir -o OBS-Studio-"$VERSION"-anylinux-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage

echo "All Done!"
