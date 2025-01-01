#!/bin/sh

set -e

GHOSTTY_VERSION="1.0.1"

DEBEMAIL="kasberg.mike@gmail.com"
DEBFULLNAME="Mike Kasberg"
DEBUILD_DPKG_BUILDPACKAGE_OPTS="-i -I -us -uc"
DEBUILD_LINTIAN_OPTS="-i -I --show-overrides"
DEB_BUILD_MAINT_OPTIONS="hardening=+all"

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
