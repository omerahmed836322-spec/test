#!/bin/bash
# Alternative Mac build with explicit Apple CLT tools and a standalone Theos SDK.
# This route is not the standard full-Xcode setup documented by Theos.
set -euo pipefail
cd "$(dirname "$0")"
export THEOS="${THEOS:-$HOME/theos}"
SDK_VERSION="${XSGPS_SDK_VERSION:-16.5}"
MIN_IOS="${XSGPS_MIN_IOS:-15.0}"
SDK_PATH="$THEOS/sdks/iPhoneOS${SDK_VERSION}.sdk"
if [ "$(uname -s)" != Darwin ]; then
  echo 'Run this script on your Mac, not Linux or the iPhone.' >&2; exit 1
fi
if [ ! -f "$THEOS/makefiles/common.mk" ]; then
  echo 'Theos not found. Export THEOS with your actual installation path.' >&2; exit 1
fi
if [ ! -d "$SDK_PATH" ]; then
  echo "Missing standalone iPhoneOS SDK: $SDK_PATH" >&2; exit 1
fi
# No xcrun -sdk iphoneos calls: tools are located independently of the iOS SDK.
CC="${XSGPS_CC:-$(xcrun --find clang)}"
LIPO="${XSGPS_LIPO:-$(xcrun --find lipo)}"
STRIP="${XSGPS_STRIP:-$(xcrun --find strip)}"
SIGNER="${XSGPS_LDID:-$(command -v ldid || true)}"
if [ ! -x "$CC" ] || [ ! -x "$LIPO" ] || [ ! -x "$STRIP" ]; then
  echo 'Apple compiler/lipo/strip tools unavailable. See THEOS_BUILD_GUIDE.md.' >&2; exit 1
fi
if [ ! -x "$SIGNER" ]; then
  echo 'ldid unavailable. Install it or export XSGPS_LDID with its executable path.' >&2; exit 1
fi
"$CC" --version
echo "SDK: $SDK_PATH"
# Test actual Objective-C compilation and arm64 iOS dynamic linking before the app.
PROBE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/xsgps-probe.XXXXXX")"
trap 'rm -rf "$PROBE_DIR"' EXIT
printf '%s\n' '#import <Foundation/Foundation.h>' '@interface XsGpSSDKProbe : NSObject @end' '@implementation XsGpSSDKProbe @end' > "$PROBE_DIR/probe.m"
"$CC" -target arm64-apple-ios${MIN_IOS} -isysroot "$SDK_PATH" -fobjc-arc \
  -dynamiclib -framework Foundation "$PROBE_DIR/probe.m" -o "$PROBE_DIR/probe.dylib"
file "$PROBE_DIR/probe.dylib"
echo 'Compiler + standalone SDK + linker probe passed.'
MAKE_ARGS=("TARGET=iphone:clang:${SDK_VERSION}:${MIN_IOS}" "TARGET_CC=$CC" "TARGET_CXX=$CC" \
  "TARGET_LD=$CC" "TARGET_LIPO=$LIPO" "TARGET_STRIP=$STRIP" "TARGET_CODESIGN=$SIGNER" \
  "SYSROOT=$SDK_PATH" "ISYSROOT=$SDK_PATH" "LOCAL_TEST=1" "FINALPACKAGE=1")
make "${MAKE_ARGS[@]}" clean
make "${MAKE_ARGS[@]}"
product=''
for candidate in .theos/obj/XsGpS.dylib .theos/obj/arm64/XsGpS.dylib; do
  if [ -f "$candidate" ]; then product="$candidate"; break; fi
done
if [ -z "$product" ]; then
  while IFS= read -r candidate; do product="$candidate"; break; done \
    < <(find .theos/obj -type f -name 'XsGpS.dylib' -print)
fi
if [ -z "$product" ]; then echo 'No XsGpS.dylib output found.' >&2; exit 1; fi
if strings "$product" | grep -F 'location-spoofer-api.hso0ooni14.workers.dev'; then
  echo 'Unexpected licensing URL in local output. Do not inject this file.' >&2; exit 1
fi
mkdir -p local-build
cp "$product" local-build/XsGpS.dylib
file local-build/XsGpS.dylib
"$LIPO" -info local-build/XsGpS.dylib
echo "Output: $(pwd)/local-build/XsGpS.dylib"
echo 'Build succeeded; device/runtime compatibility still requires testing.'