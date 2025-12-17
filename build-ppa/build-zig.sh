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

echo "Building Zig for version: $VERSION"
echo "Target codename: $CODENAME"

# Fetch the source and create .orig.tar.xz
echo "Fetching Zig source..."
cd "$SCRIPT_DIR/zig0.15"
uscan --repack -v
cd "$SCRIPT_DIR"

# Determine the base version and PPA number
FULL_VERSION="${VERSION}~us1-ppa3"
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

# Debug: Check signing environment
echo "=== Debug: SIGN_PACKAGE value ==="
echo "SIGN_PACKAGE='$SIGN_PACKAGE'"
echo "=== Debug: GPG environment ==="
env | grep -i gpg || echo "No GPG environment variables found"
echo "=== Debug: GPG agent status ==="
gpg-agent --daemon 2>&1 || echo "GPG agent not responding"
echo "=== Debug: Available GPG keys ==="
gpg --list-secret-keys --keyid-format LONG || echo "No GPG keys found"
echo "=== Debug: debuild version ==="
debuild --version

if [[ "$SIGN_PACKAGE" == 'true' ]]; then
  echo "=== Debug: Running debuild with signing ==="
  debuild -S -sa -v
else
  echo "=== Debug: Running debuild without signing ==="
  debuild -S -sa -us -uc -v
fi

# Debug: Check what files were created
echo "=== Debug: Files created by debuild ==="
ls -la ../*.changes ../*.dsc 2>/dev/null || echo "No changes/dsc files found"
echo "=== Debug: Check if changes file is signed ==="
if [ -f "../${PACKAGE_NAME}_${FULL_VERSION}_source.changes" ]; then
  file "../${PACKAGE_NAME}_${FULL_VERSION}_source.changes"
  grep -q "BEGIN PGP" "../${PACKAGE_NAME}_${FULL_VERSION}_source.changes" && echo "Changes file IS signed" || echo "Changes file is NOT signed"
else
  echo "No changes file found"
fi

cd "$SCRIPT_DIR"  # return to script directory

# Move results to script directory and cleanup
echo "Moving build results and cleaning up..."
mv "$BUILD_DIR"/${PACKAGE_NAME}_* "$SCRIPT_DIR/"
rm -rf "$BUILD_DIR"

echo "Build completed successfully!"
echo "Version: $FULL_VERSION"
