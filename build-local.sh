#!/bin/bash
# Run on the user's Mac with Theos and an iPhoneOS SDK installed.
set -euo pipefail
cd "$(dirname "$0")"
export THEOS="${THEOS:-$HOME/theos}"
if [ ! -f "$THEOS/makefiles/common.mk" ]; then
  echo "Theos not found. Set THEOS to your installed Theos directory." >&2
  exit 1
fi
make clean
make LOCAL_TEST=1 FINALPACKAGE=1
product=""
for candidate in .theos/obj/XsGpS.dylib .theos/obj/arm64/XsGpS.dylib; do
  if [ -f "$candidate" ]; then product="$candidate"; break; fi
done
if [ -z "$product" ]; then
  while IFS= read -r candidate; do
    product="$candidate"
    break
  done < <(find .theos/obj -type f -name 'XsGpS.dylib' -print)
fi
if [ -z "$product" ]; then
  echo "Build completed without an identifiable XsGpS.dylib product." >&2
  exit 1
fi
mkdir -p local-build
cp "$product" local-build/XsGpS.dylib
file local-build/XsGpS.dylib
if strings local-build/XsGpS.dylib | grep -F 'location-spoofer-api.hso0ooni14.workers.dev'; then
  echo "Unexpected licensing URL in local build; do not use this output." >&2
  exit 1
fi
echo "Built: $(pwd)/local-build/XsGpS.dylib"
echo "This is a build result, not a device compatibility test."