# llama.cpp for iOS (prebuilt)

`llama_flutter_android.podspec` links llama.cpp as static library built
from the same source tree as the Android build
(`android/src/main/cpp/llama.cpp`), so both platforms run the same engine and
speak the same phone-cluster (RPC) protocol version:

- `lib/libllama_ios.a` — universal static library (iOS Device arm64 + iOS Simulator x86_64)
- `llama_ios.xcframework` — multi-platform XCFramework
- `include/` — `llama.h`, `ggml*.h`, `gguf.h`

## Building

These files can be rebuilt at any time after updating llama.cpp:

```bash
local_plugins/llama_flutter_android/scripts/build_llama_ios.sh
```

Needs Xcode and CMake (`brew install cmake`).
