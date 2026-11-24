#!/usr/bin/env bash
# Builds llama.cpp for iOS (device arm64 and simulator x86_64 + arm64) as static libraries
# and an XCFramework, from the same llama.cpp tree the Android build uses.
#
# Output (vendored by ios/llama_flutter_android.podspec):
#   ios/llama_ios/lib/simulator/libllama_ios.a   llama + ggml (simulator x86_64 + arm64)
#   ios/llama_ios/lib/device/libllama_ios.a      llama + ggml (device arm64)
#   ios/llama_ios/lib/libllama_ios.a             fallback / simulator binary
#   ios/llama_ios/llama_ios.xcframework          multi-platform framework slices
#   ios/llama_ios/include/                       llama.h, ggml*.h, gguf.h
#
# Usage: local_plugins/llama_flutter_android/scripts/build_llama_ios.sh
# Needs Xcode and CMake (brew install cmake).
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LLAMA_SRC="$PLUGIN_DIR/android/src/main/cpp/llama.cpp"
OUT="$PLUGIN_DIR/ios/llama_ios"
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT

mkdir -p "$BUILD/wrapper"
cat > "$BUILD/wrapper/CMakeLists.txt" <<EOF
cmake_minimum_required(VERSION 3.22)
project(llama_ios C CXX OBJC OBJCXX)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
set(GGML_METAL ON CACHE BOOL "" FORCE)
set(GGML_METAL_EMBED_LIBRARY ON CACHE BOOL "" FORCE)
set(GGML_RPC ON CACHE BOOL "" FORCE)
set(GGML_RPC_RDMA OFF CACHE BOOL "" FORCE)
set(GGML_BLAS OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
add_subdirectory("$LLAMA_SRC" llama)
EOF

NCPU="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"

echo "==> Building for iOS Device (arm64)..."
cmake -S "$BUILD/wrapper" -B "$BUILD/out_device" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0

cmake --build "$BUILD/out_device" --target llama ggml ggml-base ggml-cpu ggml-metal ggml-rpc -j "$NCPU"
libtool -static -o "$BUILD/libllama_device.a" $(find "$BUILD/out_device" -name "*.a")

echo "==> Building for iOS Simulator (x86_64)..."
cmake -S "$BUILD/wrapper" -B "$BUILD/out_sim_x86_64" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES=x86_64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0

cmake --build "$BUILD/out_sim_x86_64" --target llama ggml ggml-base ggml-cpu ggml-metal ggml-rpc -j "$NCPU"
libtool -static -o "$BUILD/libllama_sim_x86_64.a" $(find "$BUILD/out_sim_x86_64" -name "*.a")

echo "==> Building for iOS Simulator (arm64)..."
cmake -S "$BUILD/wrapper" -B "$BUILD/out_sim_arm64" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0

cmake --build "$BUILD/out_sim_arm64" --target llama ggml ggml-base ggml-cpu ggml-metal ggml-rpc -j "$NCPU"
libtool -static -o "$BUILD/libllama_sim_arm64.a" $(find "$BUILD/out_sim_arm64" -name "*.a")

rm -rf "$OUT"
mkdir -p "$OUT/lib/simulator" "$OUT/lib/device" "$OUT/include"

# Copy headers
cp "$LLAMA_SRC"/include/*.h "$OUT/include/"
cp "$LLAMA_SRC"/ggml/include/*.h "$OUT/include/"

# Copy device library
cp "$BUILD/libllama_device.a" "$OUT/lib/device/libllama_ios.a"

# Universal simulator library (x86_64 + arm64)
lipo -create "$BUILD/libllama_sim_x86_64.a" "$BUILD/libllama_sim_arm64.a" -output "$OUT/lib/simulator/libllama_ios.a"
cp "$OUT/lib/simulator/libllama_ios.a" "$OUT/lib/libllama_ios.a"

# Create XCFramework
xcodebuild -create-xcframework \
  -library "$OUT/lib/device/libllama_ios.a" -headers "$OUT/include" \
  -library "$OUT/lib/simulator/libllama_ios.a" -headers "$OUT/include" \
  -output "$OUT/llama_ios.xcframework"

echo "Successfully built llama_ios libraries and XCFramework."
