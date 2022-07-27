#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright Contributors to the OpenColorIO Project.

set -ex

EXPAT_VERSION="$1"
INSTALL_TARGET="$2"
remove=1

if [ $3 == "keep" ]; then
    remove=0
fi

EXPAT_MAJOR_MINOR=$(echo "${EXPAT_VERSION}" | cut -d. -f-2)
EXPAT_MAJOR=$(echo "${EXPAT_VERSION}" | cut -d. -f-1)
EXPAT_MINOR=$(echo "${EXPAT_MAJOR_MINOR}" | cut -d. -f2-)
EXPAT_PATCH=$(echo "${EXPAT_VERSION}" | cut -d. -f3-)
EXPAT_VERSION_U="${EXPAT_MAJOR}_${EXPAT_MINOR}_${EXPAT_PATCH}"

if [ ! -d "libexpat" ]; then
    git clone https://github.com/libexpat/libexpat.git
else
    cd libexpat
    git reset --hard origin/master
    git checkout master
    git fetch
    git pull
    cd ..
fi

cd libexpat

if [ "$EXPAT_VERSION" == "latest" ]; then
    LATEST_TAG=$(git describe --abbrev=0 --tags)
    git branch -d ${LATEST_TAG} >/dev/null 2>&1 || true
    git checkout tags/${LATEST_TAG} -b ${LATEST_TAG}
else
    git branch -d R_${EXPAT_VERSION_U} >/dev/null 2>&1 || true
    git checkout tags/R_${EXPAT_VERSION_U} -b R_${EXPAT_VERSION_U}
fi

mkdir -p build
cd build

cmake -DCMAKE_BUILD_TYPE=Release \
    ${INSTALL_TARGET:+"-DCMAKE_INSTALL_PREFIX="${INSTALL_TARGET}""} \
    -DEXPAT_BUILD_TOOLS=OFF \
    -DEXPAT_BUILD_EXAMPLES=OFF \
    -DEXPAT_BUILD_TESTS=OFF \
    -DEXPAT_SHARED_LIBS=ON \
    -DEXPAT_BUILD_DOCS=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    ../expat/.

cmake --build . \
    --target install \
    --config Release \
    --parallel 2

cd ../..

if [ $remove == 1 ]; then
    rm -rf libexpat
fi
