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
export APPNAME=OBS_Studio
export DEPLOY_LOCALE=1
export DEPLOY_OPENGL=1 
export DEPLOY_PIPEWIRE=1
export DEPLOY_SYS_PYTHON=1
export PATH_MAPPING_HARDCODED='libobs.so*'

# Deploy dependencies
quick-sharun \
	/usr/bin/obs*    \
	/usr/lib/obs*    \
	/usr/lib/libobs* \
	/usr/lib/libluajit*.so*

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the app normally quits before that time
# then skip this or check if some flag can be passed that makes it stay open
quick-sharun --test ./dist/*.AppImage
