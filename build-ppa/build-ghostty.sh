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
#     -o TARBALL     Use existing .orig.tar.gz instead of fetching.
#                Required for multi-distro uploads: all codenames must
#                reference a byte-identical .orig.tar.gz, so it is built
#                once and shared.
#

set -e

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
CODENAME="resolute"
SIGN_PACKAGE=false
VERSION="tip"
ORIG_TARBALL=""
PPA_VERSION="ppa4"
PACKAGE_NAME="ghostty"

# Parse command line arguments
while getopts 'hc:sv:o:' opt; do
    case "$opt" in
        'h')
            echo "Usage: $0 [OPTIONS]"
            echo "  Options:"
            echo "    -h             Show this help message"
            echo "    -c CODENAME    Ubuntu codename (noble, questing, etc.)"
            echo "    -s             Sign the package (sets SIGN_PACKAGE=true)"
            echo "    -v VERSION     Ghostty version (tip, 1.0.0, etc.)"
            echo "                   Defaults to tip"
            echo "    -o TARBALL     Use existing .orig.tar.gz instead of fetching"
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
        'o')
            ORIG_TARBALL="$OPTARG"
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

# Fetch the source and create .orig.tar.gz, unless a shared one was provided.
# All codenames uploaded from one run must reference a byte-identical
# .orig.tar.gz (Launchpad rejects a same-named orig with different contents),
# so multi-distro builds share a single tarball via -o instead of each
# regenerating their own.
REPACK_TARBALL=""
if [ -n "$ORIG_TARBALL" ]; then
    echo "Using provided orig tarball: $ORIG_TARBALL"
    if [ ! -f "$ORIG_TARBALL" ]; then
        echo "Error: provided orig tarball not found: $ORIG_TARBALL"
        exit 1
    fi
    REPACK_TARBALL="$ORIG_TARBALL"
else
    echo "Fetching Ghostty source..."
    "$SCRIPT_DIR/fetch-ghostty-orig-source.sh" "$VERSION"
fi

# Determine the base version and PPA number
if [ "$VERSION" = "tip" ]; then
    if [ -z "$REPACK_TARBALL" ]; then
        # Find the REPACK_TARBALL created by fetch-ghostty-orig-source.sh
        REPACK_TARBALL=$(ls ghostty_*+nightly*~${PPA_VERSION}.orig.tar.gz 2>/dev/null | head -n1)
        if [ -z "$REPACK_TARBALL" ]; then
            echo "Error: Could not find repackaged tarball for tip build"
            exit 1
        fi
    fi
    # Extract FULL_VERSION from REPACK_TARBALL filename
    FULL_VERSION=$(basename "$REPACK_TARBALL" | sed -n 's/^ghostty_\([^)]*\)\.orig\.tar\.gz$/\1/p')
    FULL_VERSION="${FULL_VERSION}-${CODENAME}1"
else
    FULL_VERSION="${VERSION}~${PPA_VERSION}-${CODENAME}1"
    if [ -z "$REPACK_TARBALL" ]; then
        REPACK_TARBALL="ghostty_${VERSION}~${PPA_VERSION}.orig.tar.gz"
    fi
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
DEBUILD_OPTIONS=""

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
