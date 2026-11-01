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

# Unpack each cached tarball, then normalize: the package manifest must
# end up at the package root. Tarballs hold the package either at the
# archive root or under a single top-level directory (which `zig fetch`
# normalizes away); handle both without guessing up front.
for f in "$CACHE_DIR"/p/*.tar.gz; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .tar.gz)
  dest="$PKG_DIR/$name"
  rm -rf "$dest"
  mkdir -p "$dest"
  tar -xzf "$f" -C "$dest"
  if [ ! -f "$dest/build.zig.zon" ]; then
    if [ "$(find "$dest" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ]; then
      sub=$(find "$dest" -mindepth 1 -maxdepth 1)
      if [ -d "$sub" ]; then
        for e in "$sub"/* "$sub"/.*; do
          case "$e" in "$sub/."|"$sub/..") continue ;; esac
          [ -e "$e" ] || continue
          mv "$e" "$dest"/
        done
        rmdir "$sub"
      fi
    fi
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
# On failure, show the tarball layout so we can fix the normalization.
missing=0
for d in "$PKG_DIR"/*/; do
  [ -d "$d" ] || continue
  if [ ! -f "$d/build.zig.zon" ]; then
    echo "WARNING: no build.zig.zon in $d" >&2
    echo "  top-level: $(find "$d" -mindepth 1 -maxdepth 1 | head -n 5 | tr '\n' ' ')" >&2
    f="$CACHE_DIR/p/$(basename "$d").tar.gz"
    if [ -f "$f" ]; then
      echo "  tarball layout: $(tar -tzf "$f" 2>/dev/null | head -n 5 | tr '\n' ' ')" >&2
    fi
    missing=$((missing + 1))
  fi
done
echo "Materialized $(ls "$PKG_DIR" | wc -l) packages in $PKG_DIR ($missing missing manifest)"
