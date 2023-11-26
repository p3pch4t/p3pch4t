#!/bin/bash
# This script will download latest P3PGO binaries and use
# some dark android magic to make the binaries available
# after the app is installed.
set -xe
cd $(dirname $0)
P3PGO_BRANCH="master"
COPY_DIR="../../../../p3pgo/"
CLONE_URL="ssh://gitea@git.mrcyjanek.net:2222/p3pch4t/p3pgo.git"
BUILD_DIR=$(mktemp -d)
CLONE_DIR=$(mktemp -d)
[[ -d "$COPY_DIR" ]] && (cp -a $COPY_DIR/{*,.*} $CLONE_DIR) || (git clone -b "$P3PGO_BRANCH" "$CLONE_URL" "$CLONE_DIR" --depth=1)
(cd $CLONE_DIR && make c_api_android)

# All android archs
# build/api_android_arm64-v8a.h
# build/api_android_arm64-v8a.so
# build/api_android_armeabi-v7a.h
# build/api_android_armeabi-v7a.so
# build/api_android_x86_64.h
# build/api_android_x86_64.so
# build/api_android_x86.h
# build/api_android_x86.so
for arch in arm64-v8a armeabi-v7a x86 x86_64; do
    mkdir -p "$BUILD_DIR/lib/$arch"
    # loop to move all the binaries that we want
    for binary in .h .so; do
        cp "$CLONE_DIR/build/api_android_$arch$binary" "$BUILD_DIR/lib/$arch/libp3pgo$binary"
    done
done
(cd $BUILD_DIR; zip p3plib.jar lib -r)
mv $BUILD_DIR/p3plib.jar .
# rm -rf $BUILD_DIR $CLONE_DIR