#!/data/data/com.termux/files/usr/bin/bash
# Spoof Fierce — Build prebuilt .so via Termux
set -e

echo "=== Spoof Fierce Build ==="

pkg install -y cmake clang

[ ! -f spoof_module.cpp ] && { echo "ERROR: spoof_module.cpp not found"; exit 1; }
[ ! -f zygisk.hpp ] && { echo "ERROR: zygisk.hpp not found"; exit 1; }
[ ! -f CMakeLists.txt ] && { echo "ERROR: CMakeLists.txt not found"; exit 1; }

mkdir -p build lib/arm64-v8a

cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build . -j4

cp libspoof_fierce.so ../lib/arm64-v8a/
cd ..

if [ -f lib/arm64-v8a/libspoof_fierce.so ]; then
    echo ""
    echo "=== BUILD SUCCESS ==="
    ls -la lib/arm64-v8a/libspoof_fierce.so
else
    echo "ERROR: Build failed"
    exit 1
fi
