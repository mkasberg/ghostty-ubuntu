#!/bin/bash
#
# Automated build script for Zig for Ghostty PPA
#
# Usage: ./build-zig.sh [OPTIONS] [codename]
#   Options:
#     -h             Show this help message
#     -c CODENAME    Ubuntu codename (noble, questing, etc.)
#     -s             Sign the package (sets SIGN_PACKAGE=true)
#   codename: Ubuntu codename (noble, questing, etc.)
#                Defaults to questing
#

set -e

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
CODENAME="questing"
SIGN_PACKAGE=false

# Parse command line arguments
while getopts 'hc:s' opt; do
    case "$opt" in
        'h')
            echo "Usage: $0 [OPTIONS] [codename]"
            echo "  Options:"
            echo "    -h             Show this help message"
            echo "    -c CODENAME    Ubuntu codename (noble, questing, etc.)"
            echo "    -s             Sign the package (sets SIGN_PACKAGE=true)"
            echo "  codename: Ubuntu codename (noble, questing, etc.)"
            echo "                   Defaults to questing"
            exit 0
            ;;
        'c')
            CODENAME="$OPTARG"
            ;;
        's')
            SIGN_PACKAGE=true
            ;;
        '?')
            echo "Invalid option: -$OPTARG"
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

TIMESTAMP=$(date -u -R)
PACKAGE_NAME=zig0.15
VERSION="0.15.2"
PPA_VERSION="ppa5"

echo "Building Zig for version: $VERSION"
echo "Target codename: $CODENAME"
echo "Sign package: $SIGN_PACKAGE"

# Fetch the source and create .orig.tar.xz
echo "Fetching Zig source..."
cd "$SCRIPT_DIR/zig0.15"
uscan --repack -v
cd "$SCRIPT_DIR"

# Determine the base version and PPA number
FULL_VERSION="${VERSION}~us1-${PPA_VERSION}~${CODENAME}1"
REPACK_TARBALL="zig0.15_${VERSION}~us1.orig.tar.xz"

echo "Full version: $FULL_VERSION"

# Create temporary build directory
BUILD_DIR=$(mktemp -d)
echo "Using temporary build directory: $BUILD_DIR"

# Extract upstream source to temp directory
echo "Extracting upstream source..."
tar -xf "${REPACK_TARBALL}" -C "$BUILD_DIR"
UPSTREAM_DIR=$(basename "$BUILD_DIR"/*)

# Copy the upstream tarball to where dpkg-source expects it
echo "Copying upstream tarball for dpkg-source..."
cp "$SCRIPT_DIR/${REPACK_TARBALL}" "$BUILD_DIR/"

# Copy Debian packaging to temp directory
echo "Copying Debian packaging..."
cp -r "$SCRIPT_DIR/$PACKAGE_NAME/debian" "$BUILD_DIR/$UPSTREAM_DIR/"

# Handle libxml2 dependency based on Ubuntu version
echo "Adjusting libxml2 dependency for $CODENAME..."
if [[ "$CODENAME" == "questing" ]]; then
    echo "Using libxml2-16 for Ubuntu 25.10 (Questing)"
    # Keep libxml2-16 as is
else
    echo "Using libxml2 for Ubuntu 25.04 (Plucky) and earlier"
    sed -i 's/libxml2-16/libxml2/' "$BUILD_DIR/$UPSTREAM_DIR/debian/control"
fi

# Update changelog in temp directory
CHANGELOG_FILE="$BUILD_DIR/$UPSTREAM_DIR/debian/changelog"
echo "Updating changelog..."
cat > "$CHANGELOG_FILE" << EOF
${PACKAGE_NAME} ($FULL_VERSION) $CODENAME; urgency=medium

  * Build for $CODENAME.

 -- Mike Kasberg <kasberg.mike@gmail.com>  $TIMESTAMP

$(cat "$CHANGELOG_FILE")
EOF

echo "Updated changelog:"
head -n5 "$CHANGELOG_FILE"

# Build the source package in temp directory
echo "Building source package..."
cd "$BUILD_DIR/$UPSTREAM_DIR"
if [ "$SIGN_PACKAGE" = "true" ]; then
  debuild -S -sa
else
  debuild -S -sa -us -uc
fi
cd "$SCRIPT_DIR"  # return to script directory

# Move results to script directory and cleanup
echo "Moving build results and cleaning up..."
mv "$BUILD_DIR"/${PACKAGE_NAME}_* "$SCRIPT_DIR/"
rm -rf "$BUILD_DIR"

echo "Build completed successfully!"
echo "Version: $FULL_VERSION"
