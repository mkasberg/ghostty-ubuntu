#!/bin/bash
#
# Automated build script for Zig for Ghostty PPA
#
# Usage: ./build-zig.sh
#

set -e

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 "
    exit 0
fi

PPA="ppa:mkasberg/ghostty-ubuntu"
TIMESTAMP=$(date -u -R)
VERSION="0.15.2"

echo "Building Zig for version: $VERSION"
echo "PPA: $PPA"

# Fetch the source and create .orig.tar.xz
echo "Fetching Zig source..."
cd zig0.15
uscan --repack -v
cd -

# Determine the base version and PPA number
FULL_VERSION="${VERSION}~us1-ppa3"
REPACK_TARBALL="zig0.15_${VERSION}~us1.orig.tar.xz"

echo "Full version: $FULL_VERSION"

# Create temporary build directory
BUILD_DIR=$(mktemp -d)
echo "Using temporary build directory: $BUILD_DIR"

# Extract upstream source to temp directory
echo "Extracting upstream source..."
tar -xzf "${REPACK_TARBALL}" -C "$BUILD_DIR"
UPSTREAM_DIR=$(basename "$BUILD_DIR"/*)

# Copy the upstream tarball to where dpkg-source expects it
echo "Copying upstream tarball for dpkg-source..."
cp "${REPACK_TARBALL}" "$BUILD_DIR/"

# Copy Debian packaging to temp directory
echo "Copying Debian packaging..."
cp -r "$PACKAGE_NAME/debian" "$BUILD_DIR/$UPSTREAM_DIR/"

# Update changelog in temp directory
CHANGELOG_FILE="$BUILD_DIR/$UPSTREAM_DIR/debian/changelog"
echo "Updating changelog..."
cat > "$CHANGELOG_FILE" << EOF
${PACKAGE_NAME} ($FULL_VERSION) questing; urgency=medium

  * Nightly build.

 -- Mike Kasberg <kasberg.mike@gmail.com>  $TIMESTAMP

$(cat "$CHANGELOG_FILE")
EOF

echo "Updated changelog:"
head -n5 "$CHANGELOG_FILE"

# Build the source package in temp directory
echo "Building source package..."
cd "$BUILD_DIR/$UPSTREAM_DIR"
debuild -S -sa
cd -  # return to original directory

# Move results to current directory and cleanup
echo "Moving build results and cleaning up..."
mv "$BUILD_DIR"/${PACKAGE_NAME}_* ./
rm -rf "$BUILD_DIR"

# Upload to PPA
echo "Uploading to PPA..."
dput "$PPA" ${PACKAGE_NAME}_*_source.changes

echo "Nightly build completed successfully!"
echo "Version: $FULL_VERSION"
echo "Uploaded to: $PPA"
