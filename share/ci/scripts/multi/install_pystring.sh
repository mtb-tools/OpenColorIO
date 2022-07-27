#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright Contributors to the OpenColorIO Project.

set -ex

PYSTRING_VERSION="$1"
INSTALL_TARGET="$2"
remove=1

if [ $3 == "keep" ]; then
    remove=0
fi

if [ ! -d "pystring" ]; then
    git clone "https://github.com/imageworks/pystring.git"
else
    cd pystring
    git reset --hard origin/master
    git checkout master
    git fetch
    git pull
    cd ..
fi

cd pystring

if [ "$PYSTRING_VERSION" == "latest" ]; then
    LATEST_TAG=$(git describe --abbrev=0 --tags)
    git branch -d ${LATEST_TAG} >/dev/null 2>&1 || true
    git checkout tags/${LATEST_TAG} -b ${LATEST_TAG}
else
    git branch -d v${PYSTRING_VERSION} >/dev/null 2>&1 || true
    git checkout tags/v${PYSTRING_VERSION} -b v${PYSTRING_VERSION}
fi

cp $CURRENT_ROOT/share/cmake/projects/Buildpystring.cmake CMakeLists.txt

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
    rm -rf pystring
fi
