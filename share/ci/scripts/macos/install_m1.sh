set -ex

ROOT=$(pwd)
SCRIPT_DIR=$(realpath $(dirname $0))
MULTI=$(realpath "$SCRIPT_DIR/../multi")

LOCAL=${ROOT}/local_env
HOMEBREW="$LOCAL/homebrew"
BREW="$HOMEBREW/bin/brew"
CURRENT_ROOT="$ROOT"
export CURRENT_ROOT
deps=0

pathremove() {
    local IFS=':'
    local NEWPATH
    local DIR
    local PATHVARIABLE=${2:-PATH}
    for DIR in ${!PATHVARIABLE}; do
        if [ "$DIR" != "$1" ]; then
            NEWPATH=${NEWPATH:+$NEWPATH:}$DIR
        fi
    done
    export $PATHVARIABLE="$NEWPATH"
}

pathremove "/opt/homebrew/bin" PATH

PATH="$HOMEBREW/bin:$PATH"

while [[ "$#" -gt 0 ]]; do
    case $1 in
    -d | --deps)
        deps=1
        shift
        ;;
    -u | --uglify) uglify=1 ;;
    *)
        echo "Unknown parameter passed: $1"
        exit 1
        ;;
    esac
    #shift
done

# Make SCRIPT_DIR absolute

# mkdir -p $LOCAL/lib
# mkdir -p $LOCAL/bin
# mkdir -p $LOCAL/include
# mkdir -p $LOCAL/opt
# mkdir -p $LOCAL/share
# mkdir -p $LOCAL/Cellar

$BREW install cmake
# ensure only run in darwin env
OS_TYPE=$(uname)
if [ ${OS_TYPE} == "Darwin" ]; then
    if [ ! -e "$BREW" ]; then
        mkdir -p $HOMEBREW
        curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C $HOMEBREW

        # update
        $BREW update

        # system deps
        $BREW install gflags
    else
        # update
        $BREW update

    fi
fi

mkdir -p "$LOCAL/stage"
pushd "$LOCAL/stage"

if [ $deps == 1 ]; then
    $BREW install bison boost llvm

    $MULTI/install_pugixml.sh latest $HOMEBREW keep
    $MULTI/install_expat.sh 2.4.1 $HOMEBREW keep
    $MULTI/install_lcms2.sh 2.2 $HOMEBREW keep
    $MULTI/install_yaml-cpp.sh 0.7.0 $HOMEBREW keep
    #$MULTI/install_pystring.sh 1.1.3 $HOMEBREW
    $MULTI/install_pybind11.sh 2.6.1 $HOMEBREW keep

    $MULTI/install_openexr.sh latest $HOMEBREW keep
    $MULTI/install_imath.sh 3.1.5 $HOMEBREW keep

    # $BREW install openimageio
    $MULTI/install_oiio.sh latest $HOMEBREW keep
    $MULTI/install_osl.sh latest $HOMEBREW keep
    $MULTI/install_openfx.sh latest $HOMEBREW keep
fi
# $MULTI/install_pystring.sh 1.1.3 $LOCAL
mkdir -p _install
mkdir -p _build

# rsync -a $HOMEBREW/bin/ $LOCAL/bin/
# rsync -a $HOMEBREW/lib/ $LOCAL/lib/
# rsync -a $HOMEBREW/opt/ $LOCAL/opt/
# rsync -a $HOMEBREW/include/ $LOCAL/include/
# rsync -a $HOMEBREW/Cellar/ $LOCAL/Cellar/

pushd _build
cmake $ROOT \
    -DCMAKE_INSTALL_PREFIX=../_install \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DOCIO_BUILD_DOCS=OFF \
    -DOCIO_BUILD_OPENFX=ON \
    -DOCIO_BUILD_GPU_TESTS=OFF \
    -DOCIO_INSTALL_EXT_PACKAGES=NONE \
    -DOCIO_WARNING_AS_ERROR=OFF \
    -DPython_EXECUTABLE=$(which python) \
    -DOCIO_USE_OIIO_CMAKE_CONFIG=ON

cmake --build . \
    --target install \
    --config Release \
    -- -j
