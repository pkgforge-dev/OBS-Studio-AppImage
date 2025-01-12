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
URUNTIME="$(wget -q https://api.github.com/repos/VHSgunzo/uruntime/releases -O - \
	| sed 's/[()",{} ]/\n/g' | grep -oi "https.*appimage.*dwarfs.*$ARCH$" | head -1)"

# Prepare AppDir
mkdir -p ./"$PACKAGE"/AppDir/usr/share/applications ./"$PACKAGE"/AppDir/shared/lib
cd ./"$PACKAGE"/AppDir

cp -r /usr/share/obs                             ./usr/share
cp -r /usr/share/locale                          ./usr/share
cp -r /usr/share/glvnd                           ./usr/share
cp /usr/share/applications/$DESKTOP              ./usr/share/applications
cp /usr/share/applications/$DESKTOP              ./
cp /usr/share/icons/hicolor/256x256/apps/"$ICON" ./
cp /usr/share/icons/hicolor/256x256/apps/"$ICON" ./.DirIcon

ln -s ./usr/share ./

# ADD LIBRARIES
wget "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -e -r -k /usr/bin/obs*
rm -f ./lib4bin

# DELOY QT AND OBS PLUGINS
mkdir -p ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/iconengines       ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/imageformats      ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/platforms         ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/platformthemes    ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/styles            ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/xcbglintegrations ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/wayland-*         ./shared/lib/qt6/plugins

cp -r /usr/lib/obs-plugins   ./shared/lib
cp -r /usr/lib/obs-scripting ./shared/lib

ldd ./shared/lib/qt6/plugins/*/* ./shared/lib/obs*/* 2>/dev/null \
  | awk -F"[> ]" '{print $4}' | xargs -I {} cp -nv {} ./shared/lib || true

cp -rv /usr/lib/alsa-lib     ./usr/lib
cp -rv /usr/lib/pipewire-0.3 ./usr/lib
cp -rv /usr/lib/spa-0.2      ./usr/lib

find ./shared -type f -exec strip -s -R .comment --strip-unneeded {} ';'

# Prepare sharun
ln -s ./bin/obs ./AppRun
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
	--compression zstd:level=22 -S24 -B16 \
	--header uruntime \
	-i ./AppDir -o "$PACKAGE"-"$VERSION"-anylinux-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage

mv ./*.AppImage* ../
cd ..
rm -rf ./"$PACKAGE"
echo "All Done!"
