#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
    cmake          \
    glu            \
    libdecor       \
    libxcomposite  \
    pipewire-audio \
    pipewire-jack  \
    sdl2

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

# Comment this out if you need an AUR package
#make-aur-package

# If the application needs to be manually built that has to be done down here
echo "Making nightly build of Sonic-3-AIR..."
echo "---------------------------------------------------------------"
REPO="https://github.com/Eukaryot/sonic3air"
VERSION="$(git ls-remote "$REPO" HEAD | cut -c 1-9 | head -1)"
git clone "$REPO" ./sonic3air
echo "$VERSION" > ~/version

mkdir -p ./AppDir/bin/data
cd ./sonic3air/Oxygen/sonic3air/build/_cmake
#mkdir -p build && cd build
cmake . \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SDL_STATIC=ON \
    -DUSE_DISCORD=ON \
    -DBUILD_OXYGEN_ENGINEAPP=OFF ..
make -j$(nproc)

cd ../../
./sonic3air_linux -dumpcppdefinitions # Needs to do this to generate saves/scripts.bin
./sonic3air_linux -pack # Generates the other data bin files
mv enginedata.bin ../../../AppDir/bin/data
mv gamedata.bin ../../../AppDir/bin/data
mv audiodata.bin ../../../AppDir/bin/data
mv audioremaster.bin ../../../AppDir/bin/data
cp data/metadata.json ../../../AppDir/bin/data
mv -v sonic3air_linux ../../../AppDir/bin
mv -v ./source/external/discord_game_sdk/lib/$(uname -m)/libdiscord_game_sdk.so ../../../AppDir/bin
cp -r saves ../../../AppDir/bin
mv -v config.json ../../../AppDir/bin
