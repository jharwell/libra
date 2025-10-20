#! /bin/bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME=$(basename "$0")
SCRIPT_NAME_NO_EXT="${SCRIPT_NAME%.*}"
BUILDDIR=$SCRIPTDIR/build

set -euo pipefail
set -x

################################################################################
# Test Cases
################################################################################
echo "[TEST] Nominative case..."

# gcc-13 defaults to c++17

rm -rf $BUILDDIR
mkdir -p $BUILDDIR && cd $BUILDDIR

cmake ../cmake-pkg \
      -DCMAKE_INSTALL_PREFIX=/tmp/bar \
      -DCMAKE_CXX_COMPILER=g++-13 | tee /tmp/$SCRIPT_NAME_NO_EXT.log

grep -qE "C\+\+ std.*c\+\+20" /tmp/$SCRIPT_NAME_NO_EXT.log

rm -rf $BUILDDIR
mkdir -p $BUILDDIR && cd $BUILDDIR

# If CMAKE_CXX_STANDARD set, LIBRA should respect. You should not need
# to clear the cache for this to work.
echo "[TEST] Respect CMAKE_CXX_STANDARD..."
stds=(20 17 14 11)
for std in "${stds[@]}"; do
    cmake ../cmake-pkg \
          -DCMAKE_INSTALL_PREFIX=/tmp/bar \
          -DCMAKE_CXX_COMPILER=g++-13 \
          -DCMAKE_CXX_STANDARD=${std} | tee /tmp/$SCRIPT_NAME_NO_EXT.log

    grep -qE "C\+\+ std.*c\+\+${std}" /tmp/$SCRIPT_NAME_NO_EXT.log

done

# If LIBRA_GLOBAL_CXX_STANDARD is set, then this should error out.
echo "[TEST] LIBRA_GLOBAL_CXX_STANDARD..."
rm -rf $BUILDDIR
mkdir -p $BUILDDIR && cd $BUILDDIR

cmake ../cmake-pkg \
      -DCMAKE_INSTALL_PREFIX=/tmp/bar \
      -DCMAKE_CXX_COMPILER=g++-13 \
      -DLIBRA_GLOBAL_CXX_STANDARD=YES \
      -DLIBRA_CXX_STANDARD=11 && exit 1

# CMAKE_CXX_STANDARD has higher precedence. This should succeed.
echo "[TEST] LIBRA_CXX_STANDARD vs CMAKE_CXX_STANDARD..."
rm -rf $BUILDDIR
mkdir -p $BUILDDIR && cd $BUILDDIR
cmake ../cmake-pkg \
      -DCMAKE_INSTALL_PREFIX=/tmp/bar \
      -DCMAKE_CXX_COMPILER=g++-13 \
      -DLIBRA_GLOBAL_CXX_STANDARD=YES \
      -DCMAKE_CXX_STANDARD=17 \
      -DLIBRA_CXX_STANDARD=11
