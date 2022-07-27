#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright Contributors to the OpenColorIO Project.

set -ex

LCMS2_VERSION="$1"
INSTALL_TARGET="$2"
remove=1

if [ $3 == "keep" ]; then
    remove=0
fi

if [ ! -d "Little-CMS" ]; then
    git clone https://github.com/mm2/Little-CMS.git
else
    cd Little-CMS
    git reset --hard origin/master
    git checkout master
    cd ..
fi

cd Little-CMS

if [ "$LCMS2_VERSION" == "latest" ]; then
    LATEST_TAG=$(git describe --abbrev=0 --tags)
    git branch -d ${LATEST_TAG} >/dev/null 2>&1 || true
    git checkout tags/${LATEST_TAG} -b ${LATEST_TAG}
else
    git branch -d lcms${LCMS2_VERSION} >/dev/null 2>&1 || true
    git checkout tags/lcms${LCMS2_VERSION} -b lcms${LCMS2_VERSION}
fi

cp $CURRENT_ROOT/share/cmake/projects/Buildlcms2.cmake CMakeLists.txt

mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=Release \
    ${INSTALL_TARGET:+"-DCMAKE_INSTALL_PREFIX="${INSTALL_TARGET}""} \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    ../.
cmake --build . \
    --target install \
    --config Release \
    --parallel 2

cd ../..

if [ $remove == 1 ]; then
    rm -rf Little-CMS
fi
