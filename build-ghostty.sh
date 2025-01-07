#!/bin/sh

set -e

GHOSTTY_VERSION="1.0.1"

UBUNTU_VERSION=$(lsb_release -sr)
UBUNTU_DIST=$(lsb_release -sc)

#FULL_VERSION="$GHOSTTY_VERSION-0~${UBUNTU_DIST}1"
FULL_VERSION="$GHOSTTY_VERSION-0~ppa2"


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
sed -i "s/DIST/$UBUNTU_DIST/" "ghostty-$GHOSTTY_VERSION/debian/changelog"

# Build Ghostty
cd "ghostty-$GHOSTTY_VERSION"
# TODO remove --prepend-path so we can work on a PPA build server
debuild --prepend-path /usr/local/bin -S -us -uc
