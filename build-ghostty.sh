#!/bin/sh

set -e

GHOSTTY_VERSION="1.0.1"

# Fetch Ghostty Source
wget -q "https://release.files.ghostty.org/$GHOSTTY_VERSION/ghostty-$GHOSTTY_VERSION.tar.gz"
wget -q "https://release.files.ghostty.org/$GHOSTTY_VERSION/ghostty-$GHOSTTY_VERSION.tar.gz.minisig"

minisign -Vm "ghostty-$GHOSTTY_VERSION.tar.gz" -P RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV
rm ghostty-$GHOSTTY_VERSION.tar.gz.minisig

tar -xzmf "ghostty-$GHOSTTY_VERSION.tar.gz"

cd ghostty-$GHOSTTY_VERSION

# On Ubuntu it's libbz2, not libbzip2
sed -i 's/linkSystemLibrary2("bzip2", dynamic_link_opts)/linkSystemLibrary2("bz2", dynamic_link_opts)/' build.zig

# Fetch Zig Cache
ZIG_GLOBAL_CACHE_DIR=/tmp/offline-cache ./nix/build-support/fetch-zig-cache.sh

# Build Ghostty with zig
zig build \
  --summary all \
  --prefix ./zig-out/usr \
  --system /tmp/offline-cache/p \
  -Doptimize=ReleaseFast \
  -Dcpu=baseline \
  -Dpie=true \
  -Demit-docs \
  -Dversion-string=$GHOSTTY_VERSION

# Build Ghostty Package with fpm
fpm \
  -s dir \
  -t deb \
  --name ghostty \
  --license mit \
  --version $GHOSTTY_VERSION-0~ppa2 \
  --architecture amd64 \
  --depends libadwaita-1-0 \
  --depends libc6 \
  --depends libfontconfig1 \
  --depends libfreetype6 \
  --depends libglib2.0-0t64 \
  --depends libgtk-4-1 \
  --depends libharfbuzz0b \
  --depends libonig5 \
  --depends libx11-6 \
  --deb-build-depends libgtk-4-dev \
  --deb-build-depends libadwaita-1-dev \
  --deb-build-depends libonig-dev \
  --deb-build-depends libbz2-dev \
  --description "Fast, feature-rich, and cross-platform terminal emulator." \
  --url "https://ghostty.org" \
  --maintainer "Mike Kasberg <kasberg.mike@gmail.com>" \
  --prefix /usr \
  --deb-dist $1 \
  zig-out
