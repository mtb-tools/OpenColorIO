#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright Contributors to the OpenColorIO Project.

set -ex

PYBIND11_VERSION="$1"
INSTALL_TARGET="$2"
remove=1

if [ $3 == "keep" ]; then
    remove=0
fi

if [ ! -d "pybind11" ]; then
    git clone https://github.com/pybind/pybind11.git
else
    cd pybind11
    git reset --hard origin/master
    git checkout master
    git fetch
    git pull
    cd ..
fi

cd pybind11

if [ "$PYBIND11_VERSION" == "latest" ]; then
    LATEST_TAG=$(git describe --abbrev=0 --tags)
    git branch -d ${LATEST_TAG} >/dev/null 2>&1 || true
    git checkout tags/${LATEST_TAG} -b ${LATEST_TAG}
else
    git branch -d v${PYBIND11_VERSION} >/dev/null 2>&1 || true
    git checkout tags/v${PYBIND11_VERSION} -b v${PYBIND11_VERSION}
fi

mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=Release \
    ${INSTALL_TARGET:+"-DCMAKE_INSTALL_PREFIX="${INSTALL_TARGET}""} \
    -DPYBIND11_INSTALL=ON \
    -DPYBIND11_TEST=OFF \
    ../.
cmake --build . \
    --target install \
    --config Release \
    --parallel 2

cd ../..

if [ $remove == 1 ]; then
    rm -rf pybind11
fi
