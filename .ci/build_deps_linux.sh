#!/usr/bin/env bash
# Same idea, but runs INSIDE the manylinux container
set -euo pipefail

BOOST_VER=1.88.0
IMATH_VER=3.1.11
CPU=$(nproc || getconf _NPROCESSORS_ONLN || echo 8)
PYBIN=$(python -c 'import sys; print(sys.executable)')
ROOT="/usr/local/deps"
mkdir -p "$ROOT"

yum install -y curl tar gzip bzip2 make gcc-c++ git

# ---- Boost ----
curl -L "https://downloads.sourceforge.net/project/boost/boost/${BOOST_VER}/boost_${BOOST_VER//./_}.tar.gz" \
  -o boost.tar.gz
tar -xf boost.tar.gz
cd boost_*
./bootstrap.sh --with-libraries=python --with-python="$PYBIN" --prefix="$ROOT"
./b2 install -j"$CPU" cxxstd=20
cd ..

# ---- Imath ----
curl -L "https://github.com/AcademySoftwareFoundation/Imath/archive/refs/tags/v${IMATH_VER}.tar.gz" \
  -o imath.tar.gz
tar -xf imath.tar.gz
cmake -S Imath-${IMATH_VER} -B build \
      -DCMAKE_INSTALL_PREFIX="$ROOT" \
      -DBUILD_SHARED_LIBS=ON \
      -DIMATH_ENABLE_PYTHON=ON \
      -DPYTHON_EXECUTABLE="$PYBIN"
cmake --build build --target install -j"$CPU"

echo "CMAKE_PREFIX_PATH=$ROOT" >> "$GITHUB_ENV"
