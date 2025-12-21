#!/bin/bash
#
# Patch the PPA build for different ubuntu codenames
#
# Usage: ./patch-for-dist.sh [OPTIONS]
#   Options:
#     -h             Show this help message
#     -c CODENAME    Ubuntu codename (noble, questing, etc.)
#

set -e

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
CODENAME="questing"

while getopts 'hc:' opt; do
    case "$opt" in
        'h')
            echo "Usage: $0 [OPTIONS]"
            echo "  Options:"
            echo "    -h             Show this help message"
            echo "    -c CODENAME    Ubuntu codename (noble, questing, etc.)"
            echo "    -s             Sign the package (sets SIGN_PACKAGE=true)"
            echo "    -v VERSION     Ghostty version (tip, 1.0.0, etc.)"
            echo "                   Defaults to tip"
            exit 0
            ;;
        'c')
            CODENAME="$OPTARG"
            ;;
        '?')
            echo "Invalid option: -$OPTARG"
            exit 1
            ;;
    esac
done

if [ "$CODENAME" = "noble" ]; then
  # Noble does not have libgtk4-layer-shell
  # Build without that system lib, and remove the dependency on it.
  sed -i 's/-Doptimize=ReleaseFast/-Doptimize=ReleaseFast -fno-sys=gtk4-layer-shell/' "$SCRIPT_DIR/ghostty-nightly/debian/rules"
  sed -i '/libgtk4-layer-shell0/d' "$SCRIPT_DIR/ghostty-nightly/debian/control"
  sed -i '/libgtk4-layer-shell-dev/d' "$SCRIPT_DIR/ghostty-nightly/debian/control"

  # libicu76 is libicu74 in 24.04
  sed -i 's/libicu76/libicu74/' "$SCRIPT_DIR/zig0.15/debian/control"
fi

echo "Done patching packaging source for $CODENAME"
