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

case "$ID" in
  ubuntu|pop|tuxedo|neon)
    if [[ "$VERSION_ID" =~ ^(25.04|24.04|22.04)$ ]]; then
      SUFFIX="${ARCH}_${VERSION_ID}"
    else
      echo "This installer is not compatible with Ubuntu $VERSION_ID"
      exit 1
    fi
    ;;
  
  elementary)
    if [[ "$UBUNTU_VERSION_ID" =~ ^(25.04|24.04|22.04)$ ]]; then
      SUFFIX="${ARCH}_${UBUNTU_VERSION_ID}"
    else
      echo "This installer is not compatible with Ubuntu $UBUNTU_VERSION_ID"
      exit 1
    fi
    ;;

  debian)
    if [ "$VERSION_CODENAME" = "trixie" ]; then
      SUFFIX="${ARCH}_${VERSION_CODENAME}"
    else
      echo "This installer is not compatible with Debian $VERSION_CODENAME"
      exit 1
    fi
    ;;

  kali)
    # Map Kali versions to Debian codenames
    declare -A KALI_TO_DEBIAN=(
      ["2025"]="trixie"
    )
    KALI_YEAR=$(echo "$VERSION_ID" | cut -d'.' -f1)
    DEBIAN_CODENAME=${KALI_TO_DEBIAN[$KALI_YEAR]}
    if [ -z "$DEBIAN_CODENAME" ]; then
      echo "This installer is not compatible with Kali Linux $VERSION_ID"
      exit 1
    fi
    SUFFIX="${ARCH}_${DEBIAN_CODENAME}"
    ;;

  linuxmint|zorin)
    if [ "$DEBIAN_CODENAME" = "trixie" ]; then
      # Handle LMDE (Linux Mint Debian Edition)
      SUFFIX="${ARCH}_${DEBIAN_CODENAME}"
    else
      declare -A SUPPORTED_VERSIONS=(
        ["plucky"]="25.04"
        ["noble"]="24.04"
        ["jammy"]="22.04"
      )

      if [[ -n "${SUPPORTED_VERSIONS[$UBUNTU_CODENAME]}" ]]; then
        SUFFIX="${ARCH}_${SUPPORTED_VERSIONS[$UBUNTU_CODENAME]}"
      else
        echo "This installer is not compatible with $ID $VERSION"
        exit 1
      fi
    fi
    ;;

  *)
    if [[ "$UBUNTU_VERSION_ID" =~ ^(25.04|24.04|22.04)$ ]]; then
      SUFFIX="${ARCH}_${UBUNTU_VERSION_ID}"
    else
      echo "This install script is not compatible with $ID."
      echo "If this distribution is based on Ubuntu, you can open an issue to add support to the install script."
      echo "https://github.com/mkasberg/ghostty-ubuntu/issues/new?template=Blank+issue"
      echo ""
      echo "Please copy and paste the following information into the issue on GitHub to identify your distribution."
      echo ""
      cat /etc/os-release
      echo ""
      echo "In the mean time, you can try manually installing a .deb file from https://github.com/mkasberg/ghostty-ubuntu?tab=readme-ov-file#manual-installation"
      exit 1
    fi
    ;;
esac


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
$SUDO apt-get install -y ./"$GHOSTTY_DEB_FILE"
rm "$GHOSTTY_DEB_FILE"
