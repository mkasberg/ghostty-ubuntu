#!/bin/bash
#
# Automated build script for Ghostty PPA
#
# Usage: ./build-ghostty.sh [OPTIONS]
#   Options:
#     -h             Show this help message
#     -c CODENAME    Ubuntu codename (noble, questing, etc.)
#     -s             Sign the package (sets SIGN_PACKAGE=true)
#     -v VERSION     Ghostty version (tip, 1.0.0, etc.)
#                Defaults to tip
#

set -e

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
CODENAME="questing"
SIGN_PACKAGE=false
VERSION="tip"
PPA_VERSION="ppa1"

# Parse command line arguments
while getopts 'hc:sv:' opt; do
    case "$opt" in
        'h')
            echo "Usage: $0 [OPTIONS]"
            echo "  Options:"
            echo "    -h             Show this help message"
            echo "    -c CODENAME    Ubuntu codename (noble, questing, etc.)"
            echo "    -s             Sign the package (sets SIGN_PACKAGE=true)"
            echo "    -v VERSION     Ghostty version (tip, 1.0.0, etc.)"
            echo "                   Defaults to tip"
            exit 0
            ;;
        'c')
            CODENAME="$OPTARG"
            ;;
        's')
            SIGN_PACKAGE=true
            ;;
        'v')
            VERSION="$OPTARG"
            ;;
        '?')
            echo "Invalid option: -$OPTARG"
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))
TIMESTAMP=$(date -u -R)

echo "Building Ghostty for version: $VERSION"
echo "Ubuntu codename: $CODENAME"
echo "Sign package: $SIGN_PACKAGE"

# Fetch the source and create .orig.tar.gz
echo "Fetching Ghostty source..."
"$SCRIPT_DIR/fetch-ghostty-orig-source.sh" "$VERSION"

# Determine the base version and PPA number
if [ "$VERSION" = "tip" ]; then
    PACKAGE_NAME="ghostty-nightly"
    # Find the REPACK_TARBALL created by fetch-ghostty-orig-source.sh
    REPACK_TARBALL=$(ls ghostty-nightly_*+nightly*~${PPA_VERSION}.orig.tar.gz 2>/dev/null | head -n1)
    if [ -z "$REPACK_TARBALL" ]; then
        echo "Error: Could not find repackaged tarball for tip build"
        exit 1
    fi
    # Extract FULL_VERSION from REPACK_TARBALL filename
    FULL_VERSION=$(echo "$REPACK_TARBALL" | sed -n 's/^ghostty-nightly_\([^)]*\)\.orig\.tar\.gz$/\1/p')
    FULL_VERSION="${FULL_VERSION}-${CODENAME}1"
else
    PACKAGE_NAME="ghostty"
    FULL_VERSION="${VERSION}~${PPA_VERSION}-${CODENAME}1"
    REPACK_TARBALL="ghostty_${VERSION}~${PPA_VERSION}.orig.tar.gz"
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
${PACKAGE_NAME} ($FULL_VERSION) $CODENAME; urgency=medium

  * Build for $CODENAME.

 -- Mike Kasberg <kasberg.mike@gmail.com>  $TIMESTAMP

$(cat "$CHANGELOG_FILE")
EOF

echo "Updated changelog:"
head -n5 "$CHANGELOG_FILE"

# Build the source package in temp directory
echo "Building source package..."
if [ "$CODENAME" = "noble" ] || [ "$CODENAME" = "plucky" ]; then
  # Maybe this?
  # https://bugs.launchpad.net/ubuntu/+source/lintian/+bug/1959629
  echo "Skipping lintian for noble/plucky"
  DEBUILD_OPTIONS="--no-lintian"
else
  DEBUILD_OPTIONS=""
fi

cd "$BUILD_DIR/$UPSTREAM_DIR"
if [ "$SIGN_PACKAGE" = 'true' ]; then
  debuild "$DEBUILD_OPTIONS" -S -sa
else
  debuild "$DEBUILD_OPTIONS" -S -sa -us -uc
fi
cd -  # return to original directory

# Move results to current directory and cleanup
echo "Moving build results and cleaning up..."
mv "$BUILD_DIR"/${PACKAGE_NAME}_* "$SCRIPT_DIR"
rm -rf "$BUILD_DIR"

echo "Build completed successfully!"
echo "Version: $FULL_VERSION"
