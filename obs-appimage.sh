#!/bin/sh

set -e

PACKAGE=obs-studio
TARGET_BIN=obs
DESKTOP=com.obsproject.Studio.desktop
ICON=com.obsproject.Studio.png

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1

APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage"
UPINFO="gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|OBS-Studio-AppImage|continuous|*$ARCH.AppImage.zsync"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
SHARUN=$(wget -q https://api.github.com/repos/VHSgunzo/sharun/releases -O - \
	| sed 's/[()",{} ]/\n/g' | grep -oi "https.*-$ARCH$" | head -1)

# Prepare AppDir
mkdir -p ./"$PACKAGE"/AppDir/usr/share/applications
cd ./"$PACKAGE"/AppDir
cp -r /usr/share/obs ./usr/share
cp -r /usr/share/locale ./usr/share
cp /usr/share/applications/$DESKTOP ./usr/share/applications
cp /usr/share/applications/$DESKTOP ./
cp /usr/share/icons/hicolor/256x256/apps/"$ICON" ./
ln -s ./usr/share ./share

echo '#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"
export XDG_DATA_DIRS="$CURRENTDIR/usr/share:$XDG_DATA_DIRS"
export PATH="$CURRENTDIR/bin:$PATH"
"$CURRENTDIR"/bin/TARGET "$@"' > ./AppRun
sed -i "s|TARGET|$TARGET_BIN|" ./AppRun
chmod +x ./AppRun

# ADD LIBRARIES
wget "$LIB4BN" -O ./lib4bin
wget "$SHARUN" -O ./sharun
chmod +x ./lib4bin ./sharun
HARD_LINKS=1 ./lib4bin /usr/bin/obs*
rm -f ./lib4bin

ln -s ./shared/lib ./lib # NEEDED BY OBS
cp -nv /usr/lib/libobs* ./shared/lib
cp -r /usr/lib/obs-plugins     ./shared/lib
cp -r /usr/lib/obs-scripting   ./shared/lib

patchelf --set-rpath '$ORIGIN/../lib' ./shared/lib/obs-plugins/*
patchelf --set-rpath '$ORIGIN' ./shared/lib/libobs*

ldd ./shared/lib/obs-plugins/* 2>/dev/null \
  | awk -F"[> ]" '{print $4}' | xargs -I {} cp -nv {} ./shared/lib || true

# DELOY QT
mkdir -p ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/iconengines       ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/imageformats      ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/platforms         ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/platformthemes    ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/styles            ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/xcbglintegrations ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/wayland-*         ./shared/lib/qt6/plugins

ldd ./shared/lib/qt6/plugins/*/* 2>/dev/null \
  | awk -F"[> ]" '{print $4}' | xargs -I {} cp -nv {} ./shared/lib || true
find ./shared/lib -type f -exec strip -s -R .comment --strip-unneeded {} ';'
./sharun -g # makes sharun generate the lib.path file

export VERSION=$(pacman -Q $PACKAGE | awk 'NR==1 {print $2; exit}')

# MAKE APPIAMGE WITH FUSE3 COMPATIBLE APPIMAGETOOL
cd ..
wget -q "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool

./appimagetool --comp zstd \
	--mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 \
	-n -u "$UPINFO" "$PWD"/AppDir "$PWD"/"$PACKAGE"-"$VERSION"-"$ARCH".AppImage

mv ./*.AppImage* ../
cd ..
rm -rf ./"$PACKAGE"
echo "All Done!"
