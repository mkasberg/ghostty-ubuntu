#!/bin/sh

set -e

ZIG_VERSION="0.13.0"
GHOSTTY_VERSION="1.0.1"

export DEBEMAIL="kasberg.mike@gmail.com"
export DEBFULLNAME="Mike Kasberg"
export DEBUILD_DPKG_BUILDPACKAGE_OPTS="-i -I -us -uc"
export DEBUILD_LINTIAN_OPTS="-i -I --show-overrides"
export DEB_BUILD_MAINT_OPTIONS="hardening=+all"

# Install Build Tools
apt-get -qq update && apt-get -qq install -y build-essential debhelper devscripts pandoc libonig-dev libbz2-dev wget

wget -q "https://github.com/jedisct1/minisign/releases/download/0.11/minisign-0.11-linux.tar.gz"
tar -xzf minisign-0.11-linux.tar.gz
mv minisign-linux/x86_64/minisign /usr/local/bin
rm -r minisign-linux

wget -q "https://ziglang.org/download/$ZIG_VERSION/zig-linux-x86_64-$ZIG_VERSION.tar.xz"
tar -xf "zig-linux-x86_64-$ZIG_VERSION.tar.xz" -C /opt
rm "zig-linux-x86_64-$ZIG_VERSION.tar.xz"
ln -s "/opt/zig-linux-x86_64-$ZIG_VERSION/zig" /usr/local/bin/zig

# Install Ghostty Dependencies
apt-get -qq install -y libgtk-4-dev libadwaita-1-dev

# Fetch Ghostty Source
wget -q "https://release.files.ghostty.org/$GHOSTTY_VERSION/ghostty-$GHOSTTY_VERSION.tar.gz"
wget -q "https://release.files.ghostty.org/$GHOSTTY_VERSION/ghostty-$GHOSTTY_VERSION.tar.gz.minisig"

minisign -Vm "ghostty-$GHOSTTY_VERSION.tar.gz" -P RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV
rm ghostty-$GHOSTTY_VERSION.tar.gz.minisig

tar -xzmf "ghostty-$GHOSTTY_VERSION.tar.gz"
ln -s "ghostty-$GHOSTTY_VERSION.tar.gz" "ghostty_$GHOSTTY_VERSION.orig.tar.gz"

cp -r debian "ghostty-$GHOSTTY_VERSION/debian"

# Build Ghostty
cd "ghostty-$GHOSTTY_VERSION"

debuild --prepend-path /usr/local/bin -us -uc $@
