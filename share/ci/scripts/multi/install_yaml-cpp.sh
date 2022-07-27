#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright Contributors to the OpenColorIO Project.

set -ex

YAMLCPP_VERSION="$1"
INSTALL_TARGET="$2"
remove=1

if [ $3 == "keep" ]; then
    remove=0
fi

YAMLCPP_MAJOR_MINOR=$(echo "${YAMLCPP_VERSION}" | cut -d. -f-2)
YAMLCPP_MINOR=$(echo "${YAMLCPP_MAJOR_MINOR}" | cut -d. -f2-)
YAMLCPP_PATCH=$(echo "${YAMLCPP_VERSION}" | cut -d. -f3-)

if [ ! -d "yaml-cpp" ]; then
    git clone https://github.com/jbeder/yaml-cpp.git
else
    cd yaml-cpp
    git reset --hard origin/master
    git checkout master
    git fetch
    git pull
    cd ..
fi

cd yaml-cpp

if [ "$YAMLCPP_VERSION" == "latest" ]; then
    LATEST_TAG=$(git describe --abbrev=0 --tags)
    git branch -d ${LATEST_TAG} >/dev/null 2>&1 || true
    git checkout tags/${LATEST_TAG} -b ${LATEST_TAG}
else
    if [[ "$YAMLCPP_MINOR" -lt 6 && "$YAMLCPP_PATCH" -lt 3 ]]; then
        git branch -d release-${YAMLCPP_VERSION} >/dev/null 2>&1 || true
        git checkout tags/release-${YAMLCPP_VERSION} -b release-${YAMLCPP_VERSION}
    else
        git branch -d yaml-cpp-${YAMLCPP_VERSION} >/dev/null 2>&1 || true
        git checkout tags/yaml-cpp-${YAMLCPP_VERSION} -b yaml-cpp-${YAMLCPP_VERSION}
    fi
fi

mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=Release \
    ${INSTALL_TARGET:+"-DCMAKE_INSTALL_PREFIX="${INSTALL_TARGET}""} \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DYAML_CPP_BUILD_TESTS=OFF \
    -DYAML_CPP_BUILD_TOOLS=OFF \
    -DYAML_CPP_BUILD_CONTRIB=OFF \
    ../.
cmake --build . \
    --target install \
    --config Release \
    --parallel 2

cd ../..

if [ $remove == 1 ]; then
    rm -rf yaml-cpp
fi
