#!/bin/sh
#
# Materialize vendor-zig-pkgs/ from vendor-zig-cache/ for zig >= 0.16.
#
# Since zig 0.16, `zig fetch` stores packages in the global cache as
# compressed tarballs (vendor-zig-cache/p/<hash>.tar.gz). `zig build
# --system <dir>` cannot consume those tarballs -- in read-only system
# mode it hits an assertion failure in the fetch worker (Maker/Fetch.zig:
# assert(!job_queue.read_only)) and aborts. Instead, --system expects a
# directory holding each dependency unpacked as real files, named by hash.
#
# Usage: materialize-zig-pkgs.sh <ghostty-source-dir>
#   Operates on <dir>/vendor-zig-cache and creates <dir>/vendor-zig-pkgs.
#
set -e

ROOT=${1:-.}
CACHE_DIR="$ROOT/vendor-zig-cache"
PKG_DIR="$ROOT/vendor-zig-pkgs"

rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR"

# Unpack each cached tarball. Zig package tarballs hold the package either
# at the archive root or under a single top-level directory; mirror what
# `zig fetch` does and strip that single top-level directory when present.
for f in "$CACHE_DIR"/p/*.tar.gz; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .tar.gz)
  dest="$PKG_DIR/$name"
  rm -rf "$dest"
  mkdir -p "$dest"
  if [ "$(tar -tzf "$f" 2>/dev/null | cut -d/ -f1 | sort -u | wc -l)" -eq 1 ]; then
    first=$(tar -tzf "$f" 2>/dev/null | head -n 1)
    case "$first" in
      */*) tar -xzf "$f" -C "$dest" --strip-components=1 ;;
      *) tar -xzf "$f" -C "$dest" ;;
    esac
  else
    tar -xzf "$f" -C "$dest"
  fi
done

# Carry over any already-unpacked entries (older zig cache layouts).
for entry in "$CACHE_DIR"/p/*/; do
  [ -d "$entry" ] || continue
  name=$(basename "$entry")
  if [ ! -e "$PKG_DIR/$name/build.zig.zon" ]; then
    mkdir -p "$PKG_DIR/$name"
    cp -rL "$entry/." "$PKG_DIR/$name/"
  fi
done

# Sanity check: every materialized package should have a manifest.
missing=0
for d in "$PKG_DIR"/*/; do
  [ -d "$d" ] || continue
  if [ ! -f "$d/build.zig.zon" ]; then
    echo "WARNING: no build.zig.zon in $d" >&2
    missing=$((missing + 1))
  fi
done
echo "Materialized $(ls "$PKG_DIR" | wc -l) packages in $PKG_DIR ($missing missing manifest)"
