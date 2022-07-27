#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright Contributors to the OpenColorIO Project.

set -ex

IMATH_VERSION="$1"
INSTALL_TARGET="$2"
remove=1

if [ $3 == "keep" ]; then
    remove=0
fi

if [ ! -d "Imath" ]; then
    git clone https://github.com/AcademySoftwareFoundation/Imath.git
else
    cd Imath
    git reset --hard origin/main
    git checkout main
    git fetch
    git pull
    cd ..
fi

cd Imath

if [ "$IMATH_VERSION" == "latest" ]; then
    LATEST_TAG=$(git describe --abbrev=0 --tags)
    git branch -D ${LATEST_TAG} >/dev/null 2>&1 || true
    git checkout tags/${LATEST_TAG} -b ${LATEST_TAG}
else
    git branch -D v${IMATH_VERSION} >/dev/null 2>&1 || true
    git checkout tags/v${IMATH_VERSION} -b v${IMATH_VERSION}
fi

mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=Release \
    ${INSTALL_TARGET:+"-DCMAKE_INSTALL_PREFIX="${INSTALL_TARGET}""} \
    -DBUILD_TESTING=OFF \
    -DPYTHON=OFF \
    -DCMAKE_OSX_SYSROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    ../.
cmake --build . \
    --target install \
    --config Release

cd ../..

if [ $remove == 1 ]; then
    rm -rf Imath
fi
