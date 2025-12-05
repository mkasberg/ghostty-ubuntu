#!/bin/bash
#
# Creates the .orig.tar.gz for ghostty.
#
# This is a custom script because we need to vendor some dependencies in
# order to build in PPA.
#
# Usage: ./fetch-ghostty-orig-source.sh [version]
#   version: defaults to 'tip'

set -e

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [version]"
    echo "  version: defaults to 'tip'"
    echo "  Examples:"
    echo "    $0 tip"
    echo "    $0 1.2.3"
    echo ""
    echo "Creates the .orig.tar.gz for ghostty with vendored dependencies."
    exit 0
fi

VERSION=${1:-tip}


REPACK_SUFFIX="~vendor1"
GHOSTTY_PUBKEY="RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV"
if [[ "$VERSION" == "tip" ]]; then
  GHOSTTY_TARBALL="ghostty-source.tar.gz"
  REPACK_TARBALL=""
  TARBALL_URL="https://github.com/ghostty-org/ghostty/releases/download/tip/ghostty-source.tar.gz"
else
  GHOSTTY_TARBALL="ghostty-${VERSION}.tar.gz"
  GHOSTTY_DIR="ghostty-${VERSION}"
  REPACK_TARBALL="ghostty_${VERSION}${REPACK_SUFFIX}.orig.tar.gz"
  TARBALL_URL="https://release.files.ghostty.org/${VERSION}/${GHOSTTY_TARBALL}"
fi
GHOSTTY_SIGNATURE="${TARBALL_URL}.minisig"


echo "Downloading ghostty source..."
wget "$TARBALL_URL"
wget "$GHOSTTY_SIGNATURE"

echo "Verifying ghostty source..."
minisign -V -P "${GHOSTTY_PUBKEY}" -m "${GHOSTTY_TARBALL}"

echo "Extracting ghostty source..."
if [ -z "$GHOSTTY_DIR" ]; then
  GHOSTTY_DIR=$(tar -tzf ghostty-source.tar.gz | head -n1)
fi
tar -xzf "${GHOSTTY_TARBALL}"

echo "Fetching zig cache..."
sed -i 's/zig fetch/zig0.15 fetch/g' "${GHOSTTY_DIR}/nix/build-support/fetch-zig-cache.sh"
ZIG_GLOBAL_CACHE_DIR="${GHOSTTY_DIR}/vendor-zig-cache" "${GHOSTTY_DIR}/nix/build-support/fetch-zig-cache.sh"
find "${GHOSTTY_DIR}/vendor-zig-cache" -name '*.exe' -delete
find "${GHOSTTY_DIR}/vendor-zig-cache" -name '*.dll' -delete
find "${GHOSTTY_DIR}/vendor-zig-cache" -name '*.chm' -delete

echo "Repacking ghostty source..."
# If REPACK_TARBALL is not set (tip builds), extract version from GHOSTTY_DIR
if [ -z "$REPACK_TARBALL" ]; then
  # Extract version from GHOSTTY_DIR name like "ghostty-1.3.0-main+1207240"
  EXTRACTED_VERSION=$(echo "$GHOSTTY_DIR" | sed -n 's/^ghostty-\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/p')
  DATE=$(date -u +"%Y%m%d")
  if [ -n "$EXTRACTED_VERSION" ]; then
    REPACK_TARBALL="ghostty_${EXTRACTED_VERSION}+nightly${DATE}${REPACK_SUFFIX}.orig.tar.gz"
  else
    echo "Error: Could not extract version from GHOSTTY_DIR: $GHOSTTY_DIR"
    exit 1
  fi
fi
tar -czf "${REPACK_TARBALL}" "${GHOSTTY_DIR}"

echo "Cleaning up..."
rm -rf "${GHOSTTY_DIR}"

echo "Successfully created ${REPACK_TARBALL}"
