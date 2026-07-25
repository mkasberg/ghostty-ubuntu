#!/bin/sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# https://ghostty.org/docs/install/build
GHOSTTY_VERSION="1.3.1"

if [ "$1" == "tip" ]; then
  DEBIAN_SUFFIX="0~nightly"
  SOURCE_FILENAME="ghostty-source"
  SOURCE_URL="https://github.com/ghostty-org/ghostty/releases/download/tip/$SOURCE_FILENAME.tar.gz"
  MINISIG_URL="$SOURCE_URL.minisig"
else
  DEBIAN_SUFFIX="0~ppa2"
  SOURCE_FILENAME="ghostty-$GHOSTTY_VERSION"
  SOURCE_URL="https://release.files.ghostty.org/$GHOSTTY_VERSION/$SOURCE_FILENAME.tar.gz"
  MINISIG_URL="$SOURCE_URL.minisig"
fi


# Use 25.10 format for ubuntu versions, "bookwork" format for Debian
if [ $(lsb_release -si) = "Debian" ]; then
  DISTRO_VERSION=$(lsb_release -sc)
else
  DISTRO_VERSION=$(lsb_release -sr)
fi
DISTRO=$(lsb_release -sc)

echo "Fetch Ghostty Source"
wget -q "$SOURCE_URL"
wget -q "$MINISIG_URL"

minisign -Vm "$SOURCE_FILENAME.tar.gz" -P RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV
rm "$SOURCE_FILENAME.tar.gz.minisig"

tar -xzmf "$SOURCE_FILENAME.tar.gz"

cd ghostty-*/

if [ "$1" == "tip" ]; then
  GHOSTTY_VERSION=$(cat VERSION)
fi

echo "Fetch Zig Cache"
ZIG_GLOBAL_CACHE_DIR=vendor-zig-cache ./nix/build-support/fetch-zig-cache.sh

echo "Copy debian/ packaging"
cp -r "$REPO_DIR/build-ppa/ghostty/debian" ./debian

# Apply source patches (dpkg-buildpackage -b skips dpkg-source, so quilt
# patches from debian/patches/ aren't applied automatically).
# Exit code 2 means patches are already applied, which is fine.
QUILT_PATCHES=debian/patches quilt push -a || [ $? -eq 2 ]

# Apply distro-specific patches to debian/ packaging
case "$DISTRO_VERSION" in
  "trixie" | "forky")
    # Noble/trixie/forky: no libgtk4-layer-shell
    sed -i 's/-Doptimize=ReleaseFast/-Doptimize=ReleaseFast -fno-sys=gtk4-layer-shell/' debian/rules
    sed -i -e '/libgtk4-layer-shell0/d' -e '/libgtk4-layer-shell-dev/d' debian/control
    ;;
esac

# Generate changelog entry with correct version and distro
CLEAN_GHOSTTY_VERSION=$(echo "$GHOSTTY_VERSION" | sed "s/-/+/g")
DEBIAN_VERSION="$CLEAN_GHOSTTY_VERSION-$DEBIAN_SUFFIX"

# Prepend a new changelog entry for this build
DEBEMAIL="kasberg.mike@gmail.com" DEBFULLNAME="Mike Kasberg" \
  dch --newversion "$DEBIAN_VERSION" --distribution "$DISTRO" "Build for $DISTRO."

echo "Build Debian Package"
ZIG=zig dpkg-buildpackage -b -us -uc -d

# Move the build artifacts back to the build-binary directory
mv ../ghostty_*.deb ../ghostty_*.buildinfo ../ghostty_*.changes "$SCRIPT_DIR/"

echo "Build complete!"
ls -la "$SCRIPT_DIR"/ghostty_*.deb
