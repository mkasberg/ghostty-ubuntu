#!/bin/sh
#
# Unpack a Zig global cache for use with `zig build --system <dir>`.
#
# Zig 0.15 and earlier left fetched packages unpacked in <cache>/p/<hash>/.
# Zig 0.16+ keeps them compressed as <cache>/p/<hash>.tar.gz instead, so
# `zig build --system <cache>/p` fails with "package not found".
#
# This script unpacks each tarball into <cache>/p/<hash>/ and strips the
# wrapper directory that most archives have inside (e.g. "zlib-1.3.1/").
# Packages already unpacked (Zig <= 0.15) are left alone.
#
# Usage: unpack-zig-cache.sh <cache-dir>

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <zig-cache-dir>" >&2
  exit 1
fi

PKG_DIR="$1/p"

if [ ! -d "$PKG_DIR" ]; then
  echo "No package directory at $PKG_DIR" >&2
  exit 1
fi

for tarball in "$PKG_DIR"/*.tar.gz; do
  # No tarballs means the cache is already in the old unpacked layout.
  [ -e "$tarball" ] || continue

  dir="${tarball%.tar.gz}"
  echo "Unpacking $(basename "$tarball")"
  tar -xzf "$tarball" -C "$PKG_DIR"
  rm -f "$tarball"

  # The archive holds the package under its hash directory, and most
  # upstream tarballs then wrap the sources once more (e.g. "zlib-1.3.1/").
  # `zig build --system` wants <dir>/build.zig.zon, so peel off wrapper
  # directories until the package's own files are at the top.
  while [ ! -e "$dir/build.zig.zon" ]; do
    entries=$(find "$dir" -mindepth 1 -maxdepth 1 | wc -l)
    inner=$(find "$dir" -mindepth 1 -maxdepth 1)
    if [ "$entries" -ne 1 ] || [ ! -d "$inner" ]; then
      # Not a wrapper directory; the package has no manifest (a plain C
      # library such as zlib) or a flat layout. Leave it as it is.
      break
    fi
    mv "$inner" "$dir.inner"
    rmdir "$dir"
    mv "$dir.inner" "$dir"
  done
done
