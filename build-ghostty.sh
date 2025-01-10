#!/bin/sh

set -e

GHOSTTY_VERSION="1.0.1"

UBUNTU_VERSION=$(lsb_release -sr)
UBUNTU_DIST=$(lsb_release -sc)

#FULL_VERSION="$GHOSTTY_VERSION-0~${UBUNTU_DIST}1"
FULL_VERSION="$GHOSTTY_VERSION-0~ppa2"


# Fetch Ghostty Source
wget -q "https://release.files.ghostty.org/$GHOSTTY_VERSION/ghostty-$GHOSTTY_VERSION.tar.gz"
wget -q "https://release.files.ghostty.org/$GHOSTTY_VERSION/ghostty-$GHOSTTY_VERSION.tar.gz.minisig"

minisign -Vm "ghostty-$GHOSTTY_VERSION.tar.gz" -P RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV
rm ghostty-$GHOSTTY_VERSION.tar.gz.minisig

tar -xzmf "ghostty-$GHOSTTY_VERSION.tar.gz"

cd "ghostty-$GHOSTTY_VERSION"

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

# Debian control files
cp -r ../DEBIAN/ ./zig-out/DEBIAN/

# Changelog and copyright
mkdir -p ./zig-out/usr/share/doc/ghostty/
cp ../copyright ./zig-out/usr/share/doc/ghostty/
cp ../changelog.Debian ./zig-out/usr/share/doc/ghostty/
sed -i "s/DIST/$UBUNTU_DIST/" zig-out/usr/share/doc/ghostty/changelog.Debian
gzip -n -9 zig-out/usr/share/doc/ghostty/changelog.Debian

# Compress manpages
gzip -n -9 zig-out/usr/share/man/man1/ghostty.1
gzip -n -9 zig-out/usr/share/man/man5/ghostty.5

## postinst and postrm are used by dpkg-deb; ensure they are executable
chmod +x zig-out/DEBIAN/postinst
chmod +x zig-out/DEBIAN/postrm

# Package name changed after 22.04
if [ "$UBUNTU_VERSION" = "22.04" ]; then
  sed -i "s/libglib2.0-0t64/libglib2.0-0/" zig-out/DEBIAN/control
fi

# Zsh looks for /usr/local/share/zsh/site-functions/
# but looks for /usr/share/zsh/vendor-completions/
# (note the difference when we're not in /usr/local).
mv zig-out/usr/share/zsh/site-functions zig-out/usr/share/zsh/vendor-completions

dpkg-deb --build zig-out ghostty_${FULL_VERSION}_amd64.deb
mv ghostty_${FULL_VERSION}_amd64.deb ../
