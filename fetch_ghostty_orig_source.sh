#!/bin/bash
#
# Creates the .orig.tar.gz for ghostty.
#
# This is a custom script because we need to vendor some dependencies in
# order to build in PPA.
#
# Usage: ./fetch_ghostty_orig_source.sh 1.2.3

set -e

VERSION=$1
if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

REPACK_SUFFIX="~vendor1"
GHOSTTY_TARBALL="ghostty-${VERSION}.tar.gz"
GHOSTTY_SIGNATURE="ghostty-${VERSION}.tar.gz.minisig"
GHOSTTY_PUBKEY="RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV"
GHOSTTY_DIR="ghostty-${VERSION}"
REPACK_TARBALL="ghostty_${VERSION}${REPACK_SUFFIX}.orig.tar.gz"

echo "Downloading ghostty source..."
wget "https://release.files.ghostty.org/${VERSION}/${GHOSTTY_TARBALL}"
wget "https://release.files.ghostty.org/${VERSION}/${GHOSTTY_SIGNATURE}"

echo "Verifying ghostty source..."
minisign -V -P "${GHOSTTY_PUBKEY}" -m "${GHOSTTY_TARBALL}"

echo "Extracting ghostty source..."
tar -xzf "${GHOSTTY_TARBALL}"

echo "Fetching zig cache..."
# We need || true here because a theme release from 1.2.3 is failing...
ZIG_GLOBAL_CACHE_DIR="${GHOSTTY_DIR}/vendor-zig-cache" "${GHOSTTY_DIR}/nix/build-support/fetch-zig-cache.sh" || true

echo "Repacking ghostty source..."
tar -czf "${REPACK_TARBALL}" "${GHOSTTY_DIR}"

echo "Cleaning up..."
rm -rf "${GHOSTTY_DIR}"

echo "Successfully created ${REPACK_TARBALL}"
