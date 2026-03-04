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
    minizip        \
    sdl2

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

# Comment this out if you need an AUR package
#make-aur-package

# If the application needs to be manually built that has to be done down here
VERSION=v26.02.28.0
if [ "${ARCH}" = x86_64 ]; then
    echo "Dowload last stable build of Sonic 3 A.I.R. for Linux..."
    echo "---------------------------------------------------------------"
    wget https://github.com/Eukaryot/sonic3air/releases/download/$VERSION-preview/sonic3air_game.tar.gz
    echo "$VERSION" > ~/version

    bsdtar -xvf sonic3air_game.tar.gz
    rm -f *.tar.gz
    mkdir -p ./AppDir/bin

    cd ./sonic3air_game
    rm -rf Manual.pdf setup_linux.sh bonus doc data/icon.png
    mv -v data libdiscord_game_sdk.so config.json sonic3air_linux ../AppDir/bin
else
    echo "Making stable build of Sonic 3 A.I.R. for aarch64..."
    echo "---------------------------------------------------------------"
    REPO="https://github.com/Eukaryot/sonic3air"
    #VERSION=$(git ls-remote --tags --sort="v:refname" "$REPO" | grep -v "\^{}" | tail -n1 | sed 's|.*/||')
    #git clone --branch "$VERSION" --single-branch "$REPO" ./sonic3air
    git clone --branch $VERSION-preview --single-branch "$REPO" ./sonic3air
    echo "$VERSION" > ~/version

    mkdir -p ./AppDir/bin/data
    cd ./sonic3air/Oxygen/sonic3air/build/_cmake
    cmake . \
        -DCMAKE_BUILD_TYPE=Release \
        -DUSE_DISCORD=OFF \
        -DBUILD_SDL_STATIC=OFF
    make -j$(nproc)

    cd ../../../../sonic3air
    mv -v sonic3air_linux ../Oxygen/sonic3air
    cd ../Oxygen/sonic3air
    ./sonic3air_linux -dumpcppdefinitions # Needs to do this to generate scripts.bin
    ./sonic3air_linux -pack # Generates the other data bin files
    mv -v enginedata.bin gamedata.bin audiodata.bin audioremaster.bin data/metadata.json ../../../AppDir/bin/data
    mv -v sonic3air_linux config.json ../../../AppDir/bin
    wget https://github.com/Eukaryot/sonic3air/releases/download/$VERSION-preview/sonic3air_game.tar.gz
    tar -xvf sonic3air_game.tar.gz sonic3air_game/data/scripts.bin --strip-components=1 -C ../../../AppDir/bin/data
fi

