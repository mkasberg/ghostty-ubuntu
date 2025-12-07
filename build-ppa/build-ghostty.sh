#!/bin/bash
#
# Automated build script for Ghostty PPA
#
# Usage: ./build-ghostty.sh [version]
#   version: defaults to "tip"
#

set -e

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [version]"
    echo "  version: defaults to 'tip'"
    echo "Example: $0 tip"
    exit 0
fi

VERSION=${1:-tip}
TIMESTAMP=$(date -u -R)

echo "Building Ghostty for version: $VERSION"

# Fetch the source and create .orig.tar.gz
echo "Fetching Ghostty source..."
"$SCRIPT_DIR/fetch-ghostty-orig-source.sh" "$VERSION"

# Determine the base version and PPA number
if [[ "$VERSION" == "tip" ]]; then
    PACKAGE_NAME="ghostty-nightly"
    # Find the REPACK_TARBALL created by fetch-ghostty-orig-source.sh
    REPACK_TARBALL=$(ls ghostty-nightly_*+nightly*~ppa1.orig.tar.gz 2>/dev/null | head -n1)
    if [ -z "$REPACK_TARBALL" ]; then
        echo "Error: Could not find repackaged tarball for tip build"
        exit 1
    fi
    # Extract FULL_VERSION from REPACK_TARBALL filename
    FULL_VERSION=$(echo "$REPACK_TARBALL" | sed -n 's/^ghostty-nightly_\([^)]*\)\.orig\.tar\.gz$/\1/p')
else
    PACKAGE_NAME="ghostty"
    FULL_VERSION="${VERSION}~ppa1"
    REPACK_TARBALL="ghostty_${VERSION}~ppa1.orig.tar.gz"
fi

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
cp -r "$SCRIPT_DIR/$PACKAGE_NAME/debian" "$BUILD_DIR/$UPSTREAM_DIR/"

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

echo "Build completed successfully!"
echo "Version: $FULL_VERSION"
