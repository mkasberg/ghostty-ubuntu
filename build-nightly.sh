#!/bin/bash
#
# Automated nightly build script for Ghostty PPA
#
# Usage: ./build-nightly.sh [version]
#   version: defaults to "tip"
#

set -e

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [version]"
    echo "  version: defaults to 'tip'"
    echo "Example: $0 tip"
    exit 0
fi

VERSION=${1:-tip}
PPA="ppa:mkasberg/ghostty-ubuntu"
DATE=$(date -u +"%Y%m%d")
TIMESTAMP=$(date -u -R)

echo "Building Ghostty nightly for version: $VERSION"
echo "Date: $DATE (UTC)"
echo "PPA: $PPA"

# Fetch the source and create .orig.tar.gz
echo "Fetching Ghostty source..."
./fetch-ghostty-orig-source.sh "$VERSION"

# Determine the base version and PPA number
if [[ "$VERSION" == "tip" ]]; then
    BASE_VERSION="1.2.3+nightly${DATE}~vendor1"
else
    BASE_VERSION="${VERSION}~vendor1"
fi

# Parse changelog to find the latest entry and determine PPA number
CHANGELOG_FILE="ghostty/debian/changelog"
if [ -f "$CHANGELOG_FILE" ]; then
    # Get the latest version from changelog
    LATEST_VERSION=$(head -n1 "$CHANGELOG_FILE" | sed -n 's/ghostty (\([^)]*\)).*/\1/p')
    
    if [[ "$LATEST_VERSION" =~ ^${BASE_VERSION}-0~ppa([0-9]+)$ ]]; then
        LATEST_PPA=${BASH_REMATCH[1]}
        # Extract date from latest version to check if it's the same day
        if [[ "$LATEST_VERSION" =~ \+nightly([0-9]{8})~vendor1-0~ppa([0-9]+)$ ]]; then
            LATEST_DATE=${BASH_REMATCH[1]}
            LATEST_PPA_NUM=${BASH_REMATCH[2]}
            
            if [[ "$LATEST_DATE" == "$DATE" ]]; then
                # Same date, increment PPA number
                PPA_NUM=$((LATEST_PPA_NUM + 1))
                echo "Same date as latest build ($LATEST_DATE), incrementing PPA number to: $PPA_NUM"
            else
                # Different date, reset to PPA1
                PPA_NUM=1
                echo "Different date from latest build ($LATEST_DATE vs $DATE), resetting PPA number to: $PPA_NUM"
            fi
        else
            # Fallback: couldn't parse date, start with PPA1
            PPA_NUM=1
            echo "Couldn't parse date from latest version, starting with PPA number: $PPA_NUM"
        fi
    else
        # No matching version found, start with PPA1
        PPA_NUM=1
        echo "No matching version found in changelog, starting with PPA number: $PPA_NUM"
    fi
else
    # No changelog found, start with PPA1
    PPA_NUM=1
    echo "No changelog found, starting with PPA number: $PPA_NUM"
fi

FULL_VERSION="${BASE_VERSION}-0~ppa${PPA_NUM}"
echo "Full version: $FULL_VERSION"

# Update changelog
echo "Updating changelog..."
cat > "$CHANGELOG_FILE" << EOF
ghostty ($FULL_VERSION) questing; urgency=medium

  * Nightly build.

 -- Mike Kasberg <kasberg.mike@gmail.com>  $TIMESTAMP

$(cat "$CHANGELOG_FILE")
EOF

echo "Updated changelog:"
head -n5 "$CHANGELOG_FILE"

# Build the source package
echo "Building source package..."
cd ghostty
debuild -S -sa

# Upload to PPA
echo "Uploading to PPA..."
dput "$PPA" ../ghostty_*_source.changes

echo "Nightly build completed successfully!"
echo "Version: $FULL_VERSION"
echo "Uploaded to: $PPA"