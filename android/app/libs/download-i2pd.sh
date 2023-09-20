#!/bin/bash
# This script will download latest I2pd binaries and use
# some dark android magic to make the binaries available
# after the app is installed.
set -xe
cd $(dirname $0)
I2PD_BRANCH="i2pd_2.49.0"
CLONE_URL="ssh://gitea@git.mrcyjanek.net:2222/p3pch4t/flutter_i2p_bins-prebuild.git"
CLONE_DIR=$(mktemp -d)
BUILD_DIR=$(mktemp -d)
git clone -b "$I2PD_BRANCH" "$CLONE_URL" "$CLONE_DIR" --depth=1

# All android archs
for arch in arm64-v8a armeabi-v7a x86 x86_64; do
    mkdir -p "$BUILD_DIR/lib/$arch"
    # loop to move all the binaries that we want
    for binary in i2pd keyinfo; do
        cp "$CLONE_DIR/android/$arch/$binary" "$BUILD_DIR/lib/$arch/lib$binary.so"
    done
done
(cd $BUILD_DIR; zip i2plib.jar lib -r)
mv $BUILD_DIR/i2plib.jar .
rm -rf $BUILD_DIR $CLONE_DIR