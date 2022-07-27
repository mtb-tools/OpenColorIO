#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright Contributors to the OpenColorIO Project.

set -ex

OPENEXR_VERSION="$1"
INSTALL_TARGET="$2"
remove=1

if [ $3 == "keep" ]; then
    remove=0
fi

if [ ! -d "openexr" ]; then
    git clone https://github.com/AcademySoftwareFoundation/openexr.git
else
    cd openexr
    git reset --hard origin/main
    git checkout main
    git fetch
    git pull
    cd ..
fi

cd openexr

if [ "$OPENEXR_VERSION" == "latest" ]; then
    git checkout release
    LATEST_TAG=$(git describe --abbrev=0 --tags)
    git branch -d ${LATEST_TAG} >/dev/null 2>&1 || true
    git checkout tags/${LATEST_TAG} -b ${LATEST_TAG}
else
    git branch -d v${OPENEXR_VERSION} >/dev/null 2>&1 || true
    git checkout tags/v${OPENEXR_VERSION} -b v${OPENEXR_VERSION}
fi

mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=Release \
    ${INSTALL_TARGET:+"-DCMAKE_INSTALL_PREFIX="${INSTALL_TARGET}""} \
    -DBUILD_TESTING=OFF \
    -DOPENEXR_BUILD_UTILS=OFF \
    -DOPENEXR_VIEWERS_ENABLE=OFF \
    -DINSTALL_OPENEXR_EXAMPLES=OFF \
    -DPYILMBASE_ENABLE=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    ../.
cmake --build . \
    --target install \
    --config Release \
    --parallel 2

cd ../..

if [ $remove == 1 ]; then
    rm -rf openexr
fi
