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
    echo "Dowload last stable build of Sonic-3-AIR for Linux..."
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
    echo "Making stable build of Sonic-3-AIR for aarch64..."
    echo "---------------------------------------------------------------"
    REPO="https://github.com/Eukaryot/sonic3air"
    #VERSION=$(git ls-remote --tags --sort="v:refname" "$REPO" | grep -v "\^{}" | tail -n1 | sed 's|.*/||')
    #git clone --branch "$VERSION" --single-branch "$REPO" ./sonic3air
    git clone --branch $VERSION-preview --single-branch "$REPO" ./sonic3air
    echo "$VERSION" > ~/version

    mkdir -p ./AppDir/bin/data
    #cd ./sonic3air
    #sed -i '113,125s|^|//|w /dev/stdout' Oxygen/sonic3air/source/sonic3air/client/crowdcontrol/CrowdControlClient.cpp
    #cd ..
    cd ./sonic3air
    #sed -i 's/pw_node_enum_params(node->proxy/pw_node_enum_params((struct pw_node*)node->proxy/g' framework/external/sdl/SDL2/src/audio/pipewire/SDL_pipewire.c
    cd Oxygen/sonic3air/build/_cmake
    #cd ./sonic3air/Oxygen/sonic3air/build/_cmake
    #sed -i 's/set(CMAKE_CXX_FLAGS_RELEASE "-O3")/set(CMAKE_CXX_FLAGS_RELEASE "-O0")/' CMakeLists.txt
    # -DUSE_DISCORD=false for aarch64
    export CFLAGS="${CFLAGS:-} -Dfopen64=fopen -Dfseeko64=fseeko -Dftello64=ftello -D_FILE_OFFSET_BITS=64"
    export CXXFLAGS="${CXXFLAGS:-} -Dfopen64=fopen -Dfseeko64=fseeko -Dftello64=ftello -D_FILE_OFFSET_BITS=64"
    cmake . \
        -DCMAKE_BUILD_TYPE=Release \
        -DUSE_DISCORD=false \
        -DSDL_SHARED=ON \
        -DSDL_STATIC=OFF # For stable v24.12.05.0 only
    make -j$(nproc)

    cd ../../../../sonic3air
    mv -v sonic3air_linux ../Oxygen/sonic3air
    cd ../Oxygen/sonic3air
    ./sonic3air_linux -dumpcppdefinitions # Needs to do this to generate saves/scripts.bin
    ./sonic3air_linux -pack # Generates the other data bin files
    mv -v enginedata.bin gamedata.bin audiodata.bin audioremaster.bin data/metadata.json ../../../AppDir/bin/data
    mv -v sonic3air_linux saves/scripts.bin saves scripts config.json ../../../AppDir/bin
fi

