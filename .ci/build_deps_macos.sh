#!/usr/bin/env bash
# Build Boost-Python 1.88.0 and Imath 3.1.11 for *the Python that cibuildwheel selected*
set -euo pipefail

BOOST_VER=1.88.0
IMATH_VER=3.1.11
CPU=$(sysctl -n hw.logicalcpu)        # works on Linux too
PYBIN=$(python -c 'import sys; print(sys.executable)')
ROOT="$HOME/deps"
mkdir -p "$ROOT"

echo "---- Boost $BOOST_VER ----"
curl -L "https://downloads.sourceforge.net/project/boost/boost/${BOOST_VER}/boost_${BOOST_VER//./_}.tar.gz" \
  -o boost.tar.gz
tar -xf boost.tar.gz
cd boost_*
./bootstrap.sh --with-libraries=python --with-python="$PYBIN" --prefix="$ROOT"
./b2 install -j"$CPU" cxxstd=20
cd ..

echo "---- Imath $IMATH_VER ----"
curl -L "https://github.com/AcademySoftwareFoundation/Imath/archive/refs/tags/v${IMATH_VER}.tar.gz" \
  -o imath.tar.gz
tar -xf imath.tar.gz
cmake -S Imath-${IMATH_VER} -B imath-build \
      -DCMAKE_INSTALL_PREFIX="$ROOT" \
      -DBUILD_SHARED_LIBS=ON \
      -DIMATH_ENABLE_PYTHON=ON \
      -DPYTHON_EXECUTABLE="$PYBIN"
cmake --build imath-build --target install -j"$CPU"

# Expose the custom prefix to subsequent CMake calls
echo "CMAKE_PREFIX_PATH=$ROOT" >> "$GITHUB_ENV"
