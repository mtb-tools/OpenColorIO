#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright Contributors to the OpenColorIO Project.

set -ex

OIIO_VERSION="$1"
INSTALL_TARGET="$2"
remove=1

if [ $3 == "keep" ]; then
    remove=0
fi

if [ -d "oiio" ]; then
    cd oiio
    git reset --hard origin/master
    git checkout master
    git fetch
    git pull
    cd ..
else
    git clone https://github.com/OpenImageIO/oiio.git
fi

cd oiio

if [ "$OIIO_VERSION" == "latest" ]; then
    LATEST_TAG=$(git describe --abbrev=0 --tags)
    git branch -d ${LATEST_TAG} >/dev/null 2>&1 || true
    git checkout tags/${LATEST_TAG} -b ${LATEST_TAG}
else
    git branch -d Release-${OIIO_VERSION} >/dev/null 2>&1 || true
    git checkout tags/Release-${OIIO_VERSION} -b Release-${OIIO_VERSION}
fi

mkdir -p build
cd build
# Disable python bindings to avoid build issues on Windows
cmake -DCMAKE_BUILD_TYPE=Release \
    ${INSTALL_TARGET:+"-DCMAKE_INSTALL_PREFIX="${INSTALL_TARGET}""} \
    -DOIIO_BUILD_TOOLS=OFF \
    -DOIIO_BUILD_TESTS=OFF \
    -DVERBOSE=ON \
    -DSTOP_ON_WARNING=OFF \
    -DBoost_NO_BOOST_CMAKE=ON \
    -DUSE_PYTHON=OFF \
    ../.
cmake --build . \
    --target install \
    --config Release

cd ../..

if [ $remove == 1 ]; then
    rm -rf oiio
fi
