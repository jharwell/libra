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

# gcc-13 defaults to c11

rm -rf $BUILDDIR
mkdir -p $BUILDDIR && cd $BUILDDIR

cmake ../cmake-pkg \
      -DCMAKE_INSTALL_PREFIX=/tmp/bar \
      -DCMAKE_C_COMPILER=gcc-13 | tee /tmp/$SCRIPT_NAME_NO_EXT.log

grep -qE "C std.*c11" /tmp/$SCRIPT_NAME_NO_EXT.log

rm -rf $BUILDDIR
mkdir -p $BUILDDIR && cd $BUILDDIR

# If CMAKE_C_STANDARD set, LIBRA should respect. You should not need
# to clear the cache for this to work.
echo "[TEST] Respect CMAKE_C_STANDARD..."
stds=(11 99)
for std in "${stds[@]}"; do
    cmake ../cmake-pkg \
          -DCMAKE_INSTALL_PREFIX=/tmp/bar \
          -DCMAKE_C_COMPILER=gcc-13 \
          -DCMAKE_C_STANDARD=${std} | tee /tmp/$SCRIPT_NAME_NO_EXT.log

    grep -qE "C std.*c${std}" /tmp/$SCRIPT_NAME_NO_EXT.log

done

# If LIBRA_GLOBAL_C_STANDARD is set, then this should error out.
echo "[TEST] LIBRA_GLOBAL_C_STANDARD..."
rm -rf $BUILDDIR
mkdir -p $BUILDDIR && cd $BUILDDIR

cmake ../cmake-pkg \
      -DCMAKE_INSTALL_PREFIX=/tmp/bar \
      -DCMAKE_C_COMPILER=gcc-13 \
      -DLIBRA_GLOBAL_C_STANDARD=YES \
      -DLIBRA_C_STANDARD=11 && exit 1

# CMAKE_C_STANDARD has higher precedence. This should succeed.
echo "[TEST] LIBRA_C_STANDARD vs CMAKE_C_STANDARD..."
rm -rf $BUILDDIR
mkdir -p $BUILDDIR && cd $BUILDDIR
cmake ../cmake-pkg \
      -DCMAKE_INSTALL_PREFIX=/tmp/bar \
      -DCMAKE_C_COMPILER=gcc-13 \
      -DLIBRA_GLOBAL_C_STANDARD=YES \
      -DCMAKE_C_STANDARD=99 \
      -DLIBRA_C_STANDARD=11
