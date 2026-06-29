#!/data/data/com.termux/files/usr/bin/bash
export PREFIX=/data/data/com.termux/files/usr
export PATH=$PREFIX/bin:$PATH
export CC=$PREFIX/bin/clang
export CXX=$PREFIX/bin/clang++
export MAKE=$PREFIX/bin/make
export CMAKE=$PREFIX/bin/cmake

SRC=/data/local/tmp
BUILD=$SRC/spoof_build
OUT=$SRC

mkdir -p $BUILD
cd $BUILD
$CMAKE -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=$CC \
  -DCMAKE_CXX_COMPILER=$CXX \
  -DCMAKE_MAKE_PROGRAM=$MAKE \
  $SRC
$CMAKE --build . -j4

if [ -f libspoof_fierce.so ]; then
    cp libspoof_fierce.so $OUT/libspoof_fierce.so
    echo "=== BUILD SUCCESS ==="
    ls -la $OUT/libspoof_fierce.so
else
    echo "=== BUILD FAILED ==="
    exit 1
fi
