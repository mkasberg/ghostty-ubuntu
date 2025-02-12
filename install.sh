#!/bin/bash

# This is the install script for ghostty-ubuntu (https://github.com/mkasberg/ghostty-ubuntu)
#
# This script is intended to be downloaded and run on the installation target in a single command,
# akin to how Homebrew (https://brew.sh) does it.
#
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
#
# The goal of this script is to:
#   - Detect the distribution, version, and arch of the installation target
#   - Handle inconsistencies like finding the right Ubuntu version for a corresponding Linux Mint version
#   - Download the correct .deb file
#   - Install it with dpkg

set -e

echo "Installing/Updating Ghostty..."

source /etc/os-release
ARCH=$(dpkg --print-architecture)

if [ "$ID" = "ubuntu" ]; then
  if [[ "$VERSION_ID" =~ ^(24.10|24.04)$ ]]; then
    SUFFIX="${ARCH}_${VERSION_ID}"
  else
    echo "This installer is not compatible with Ubuntu $VERSION_ID"
    exit 1
  fi
elif [ "$ID" = "debian" ]; then
  if [ "$VERSION_CODENAME" = "bookworm" ]; then
    SUFFIX="${ARCH}_${VERSION_CODENAME}"
  else
    echo "This installer is not compatible with Debian $VERSION_CODENAME"
    exit 1
  fi
  elif [ "$ID" = "kali" ]; then
  # Map Kali versions to Debian codenames
  declare -A KALI_TO_DEBIAN=(
    ["2022"]="bullseye"
    ["2023"]="bookworm"
    ["2024"]="bookworm"
  )
  KALI_YEAR=$(echo "$VERSION_ID" | cut -d'.' -f1)
  DEBIAN_CODENAME=${KALI_TO_DEBIAN[$KALI_YEAR]}
  if [ -z "$DEBIAN_CODENAME" ]; then
    echo "This installer is not compatible with Kali Linux $VERSION_ID"
    exit 1
  fi
  SUFFIX="${ARCH}_${DEBIAN_CODENAME}"
elif [ "$ID" = "linuxmint" ]; then
  declare -A SUPPORTED_VERSIONS=(
    ["oracular"]="24.10"
    ["noble"]="24.04"
  )

  if [[ -n "${SUPPORTED_VERSIONS[$UBUNTU_CODENAME]}" ]]; then
    SUFFIX="${ARCH}_${SUPPORTED_VERSIONS[$UBUNTU_CODENAME]}"
  else
    echo "This installer is not compatible with Linux Mint $VERSION"
    exit 1
  fi
else
  echo "This install script is not compatible with $ID."
  echo "If this distribution is based on Ubuntu, you can open an issue to add support to the install script."
  echo "https://github.com/mkasberg/ghostty-ubuntu/issues/new?template=Blank+issue"
  echo ""
  echo "In the mean time, you can try manually installing the correct .deb file."
  exit 1
fi

GHOSTTY_DEB_URL=$(
   curl -s https://api.github.com/repos/mkasberg/ghostty-ubuntu/releases/latest | \
   grep -oP "https://github.com/mkasberg/ghostty-ubuntu/releases/download/[^\s/]+/ghostty_[^\s/_]+_${SUFFIX}.deb"
)
if [[ -z "$GHOSTTY_DEB_URL" ]]; then
  echo "Error: Failed to retrieve the .deb package URL from GitHub."
  exit 1
fi
GHOSTTY_DEB_FILE=$(basename "$GHOSTTY_DEB_URL")

echo "Downloading ${GHOSTTY_DEB_FILE}..."
curl -LO "$GHOSTTY_DEB_URL"

echo "Installing ${GHOSTTY_DEB_FILE}..."
if [[ $EUID -ne 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi
$SUDO dpkg -i "$GHOSTTY_DEB_FILE"
rm "$GHOSTTY_DEB_FILE"
