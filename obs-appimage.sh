#!/bin/sh

set -eux

PACKAGE=obs-studio
DESKTOP=com.obsproject.Studio.desktop
ICON=com.obsproject.Studio.png

ARCH="$(uname -m)"
VERSION="$(pacman -Q $PACKAGE | awk 'NR==1 {print $2; exit}')"
echo "$VERSION" > ~/version

UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
SHARUN="https://github.com/VHSgunzo/sharun/releases/latest/download/sharun-$ARCH-aio"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
URUNTIME_LITE="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-lite-$ARCH"

# Prepare AppDir
mkdir -p ./AppDir/share
cd ./AppDir

cp -r /usr/share/obs                              ./share
cp -r /usr/share/locale                           ./share
find ./share/locale -type f ! -name '*glib*' ! -name '*v4l*' ! -name '*obs*' -delete
cp /usr/share/applications/"$DESKTOP"             ./
cp /usr/share/icons/hicolor/256x256/apps/"$ICON"  ./
cp /usr/share/icons/hicolor/256x256/apps/"$ICON"  ./.DirIcon
ln -s ./ ./usr

# ADD LIBRARIES
wget --retry-connrefused --tries=30 "$SHARUN" -O ./sharun-aio
chmod +x ./sharun-aio
xvfb-run -a -- ./sharun-aio l -p -v -e -k -s \
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
rm -f ./sharun-aio
cp -vn /usr/lib/obs-scripting/* ./shared/lib/obs-scripting

# Prepare sharun
ln ./sharun ./AppRun
./sharun -g

# Make intel hardware accel work
echo 'LIBVA_DRIVERS_PATH=${SHARUN_DIR}/shared/lib:${SHARUN_DIR}/shared/lib/dri' >> ./.env

# MAKE APPIMAGE WITH URUNTIME
cd ..
wget --retry-connrefused --tries=30 "$URUNTIME"      -O  ./uruntime
wget --retry-connrefused --tries=30 "$URUNTIME_LITE" -O  ./uruntime-lite
chmod +x ./uruntime*

# Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime-lite --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S26 -B8 \
	--header uruntime-lite \
	-i ./AppDir -o ./OBS-Studio-"$VERSION"-anylinux-"$ARCH".AppImage

# make appbundle
UPINFO="$(echo "$UPINFO" | sed 's#.AppImage.zsync#*.AppBundle.zsync#g')"
wget -O ./pelf "https://github.com/xplshn/pelf/releases/latest/download/pelf_$ARCH"
chmod +x ./pelf
echo "Generating [dwfs]AppBundle..."
./pelf --add-appdir ./AppDir \
	--appbundle-id="com.obsproject.Studio#github.com/$GITHUB_REPOSITORY:$VERSION@$(date +%d_%m_%Y)" \
	--appimage-compat \
	--disable-use-random-workdir \
	--add-updinfo "$UPINFO" \
	--compression "-C zstd:level=22 -S26 -B8" \
	--output-to "OBS-Studio-$VERSION-anylinux-$ARCH.dwfs.AppBundle"

zsyncmake ./*.AppImage -u ./*.AppImage
zsyncmake ./*.AppBundle -u ./*.AppBundle
echo "All Done!"
