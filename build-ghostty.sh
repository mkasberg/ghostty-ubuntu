#!/bin/sh

set -e

ZIG_VERSION="0.13.0"
GHOSTTY_VERSION="1.0.0"

export DEBEMAIL="kasberg.mike@gmail.com"
export DEBFULLNAME="Mike Kasberg"
export DEBUILD_DPKG_BUILDPACKAGE_OPTS="-i -I -us -uc"
export DEBUILD_LINTIAN_OPTS="-i -I --show-overrides"

# Fetch Ghostty Source
wget "https://release.files.ghostty.org/$GHOSTTY_VERSION/ghostty-source.tar.gz"
wget "https://release.files.ghostty.org/$GHOSTTY_VERSION/ghostty-source.tar.gz.minisig"

minisign -Vm "ghostty-source.tar.gz" -P RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV
rm ghostty-source.tar.gz.minisig
mv ghostty-source.tar.gz "ghostty-$GHOSTTY_VERSION.tar.gz"

tar -xzmf "ghostty-$GHOSTTY_VERSION.tar.gz"
mv ghostty-source "ghostty-$GHOSTTY_VERSION"
ln -s "ghostty-$GHOSTTY_VERSION.tar.gz" "ghostty_$GHOSTTY_VERSION.orig.tar.gz"

cp -r debian "ghostty-$GHOSTTY_VERSION/debian"

# Build Ghostty
cd "ghostty-$GHOSTTY_VERSION"
debuild --prepend-path /usr/local/bin -us -uc
