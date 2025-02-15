#!/bin/sh

set -e

GHOSTTY_VERSION="1.1.2"

DISTRO_VERSION=$(lsb_release -sr)
DISTRO=$(lsb_release -sc)

#FULL_VERSION="$GHOSTTY_VERSION-0~${DISTRO}1"
FULL_VERSION="$GHOSTTY_VERSION-0~ppa1"

echo "Fetch Ghostty Source"
wget -q "https://release.files.ghostty.org/$GHOSTTY_VERSION/ghostty-$GHOSTTY_VERSION.tar.gz"
wget -q "https://release.files.ghostty.org/$GHOSTTY_VERSION/ghostty-$GHOSTTY_VERSION.tar.gz.minisig"

minisign -Vm "ghostty-$GHOSTTY_VERSION.tar.gz" -P RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV
rm ghostty-$GHOSTTY_VERSION.tar.gz.minisig

tar -xzmf "ghostty-$GHOSTTY_VERSION.tar.gz"

# Temporary Fix for 1.1.1 & 1.1.2: Get fetch-zig-cache.sh from 1.1.0
# https://github.com/ghostty-org/ghostty/blob/f1f1120749b7494c89689d993d5a893c27c236a5/PACKAGING.md?plain=1#L84-L89
wget -q "https://release.files.ghostty.org/1.1.0/ghostty-1.1.0.tar.gz"
wget -q "https://release.files.ghostty.org/1.1.0/ghostty-1.1.0.tar.gz.minisig"
minisign -Vm "ghostty-1.1.0.tar.gz" -P RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV
rm ghostty-1.1.0.tar.gz.minisig
tar -xzmf "ghostty-1.1.0.tar.gz"
cp ghostty-1.1.0/nix/build-support/fetch-zig-cache.sh "ghostty-$GHOSTTY_VERSION/nix/build-support/"
rm -r ghostty-1.1.0
rm ghostty-1.1.0.tar.gz

cd "ghostty-$GHOSTTY_VERSION"

# On Ubuntu it's libbz2, not libbzip2
sed -i 's/linkSystemLibrary2("bzip2", dynamic_link_opts)/linkSystemLibrary2("bz2", dynamic_link_opts)/' src/build/SharedDeps.zig

echo "Fetch Zig Cache"
ZIG_GLOBAL_CACHE_DIR=/tmp/offline-cache ./nix/build-support/fetch-zig-cache.sh

echo "Build Ghostty with zig"
zig build \
  --summary all \
  --prefix ./zig-out/usr \
  --system /tmp/offline-cache/p \
  -Doptimize=ReleaseFast \
  -Dcpu=baseline \
  -Dpie=true \
  -Demit-docs \
  -Dversion-string=$GHOSTTY_VERSION

echo "Setup Debian Package"
UNAME_M="$(uname -m)"
if [ "${UNAME_M}" = "x86_64" ]; then
    DEBIAN_ARCH="amd64"
elif [ "${UNAME_M}" = "aarch64" ]; then \
    DEBIAN_ARCH="arm64"
fi

# Debian control files
cp -r ../DEBIAN/ ./zig-out/DEBIAN/
sed -i "s/amd64/$DEBIAN_ARCH/g" ./zig-out/DEBIAN/control

# Changelog and copyright
mkdir -p ./zig-out/usr/share/doc/ghostty/
cp ../copyright ./zig-out/usr/share/doc/ghostty/
cp ../changelog.Debian ./zig-out/usr/share/doc/ghostty/
sed -i "s/DIST/$DISTRO/" zig-out/usr/share/doc/ghostty/changelog.Debian
gzip -n -9 zig-out/usr/share/doc/ghostty/changelog.Debian

# Compress manpages
gzip -n -9 zig-out/usr/share/man/man1/ghostty.1
gzip -n -9 zig-out/usr/share/man/man5/ghostty.5

## postinst, preinst and prerm are used by dpkg-deb; ensure they are executable
chmod +x zig-out/DEBIAN/postinst
chmod +x zig-out/DEBIAN/preinst
chmod +x zig-out/DEBIAN/prerm

# Zsh looks for /usr/local/share/zsh/site-functions/
# but looks for /usr/share/zsh/vendor-completions/
# (note the difference when we're not in /usr/local).
mv zig-out/usr/share/zsh/site-functions zig-out/usr/share/zsh/vendor-completions

echo "Build Debian Package"
dpkg-deb --build zig-out "ghostty_${FULL_VERSION}_${DEBIAN_ARCH}.deb"
mv "ghostty_${FULL_VERSION}_${DEBIAN_ARCH}.deb" "../ghostty_${FULL_VERSION}_${DEBIAN_ARCH}_${DISTRO_VERSION}.deb"
