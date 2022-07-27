#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright Contributors to the OpenColorIO Project.

set -ex

OSL_VERSION="$1"
INSTALL_TARGET="$2"
remove=1

if [ $3 == "keep" ]; then
    remove=0
fi

if [ ! -d "OpenShadingLanguage" ]; then
    git clone https://github.com/AcademySoftwareFoundation/OpenShadingLanguage.git
else
    cd OpenShadingLanguage
    git reset --hard origin/main
    git checkout main
    git fetch
    git pull
    cd ..
fi

cd OpenShadingLanguage

if [ "$OSL_VERSION" == "latest" ]; then
    git checkout release
    LATEST_TAG=$(git describe --abbrev=0 --tags)
    git branch -d ${LATEST_TAG} >/dev/null 2>&1 || true
    git checkout tags/${LATEST_TAG} -b ${LATEST_TAG}
else
    git branch -d Release-${OSL_VERSION} >/dev/null 2>&1 || true
    git checkout tags/Release-${OSL_VERSION} -b Release-${OSL_VERSION}
fi

mkdir -p build
cd build
# FIXME: Revert OSL_BUILD_TESTS to OFF when OSL 1.12 is released
# CMake configure fails when tests are off, only fixed in 1.12 dev branch
cmake -DCMAKE_BUILD_TYPE=Release \
    ${INSTALL_TARGET:+"-DCMAKE_INSTALL_PREFIX="${INSTALL_TARGET}""} \
    -DCMAKE_CXX_STANDARD=14 \
    -DOSL_BUILD_TESTS=ON \
    -DVERBOSE=ON \
    -DSTOP_ON_WARNING=OFF \
    -DBoost_NO_BOOST_CMAKE=ON \
    ../.
cmake --build . \
    --target install \
    --config Release \
    --parallel 2

cd ../..

if [ $remove == 1 ]; then
    rm -rf OpenShadingLanguage
fi