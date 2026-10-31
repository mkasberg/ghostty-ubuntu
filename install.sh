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

echo "Installing/Updating Ghostty..." >&2

source /etc/os-release
ARCH=$(dpkg --print-architecture)

case "$ID" in
  ubuntu|pop|tuxedo|neon)
    if [[ "$VERSION_ID" =~ ^(26.04|24.04)$ ]]; then
      SUFFIX="${ARCH}_${VERSION_ID}"
    else
      echo "This installer is not compatible with Ubuntu $VERSION_ID" >&2
      exit 1
    fi
    ;;

  elementary)
    if [[ "$UBUNTU_VERSION_ID" =~ ^(26.04|24.04)$ ]]; then
      SUFFIX="${ARCH}_${UBUNTU_VERSION_ID}"
    else
      echo "This installer is not compatible with Ubuntu $UBUNTU_VERSION_ID" >&2
      exit 1
    fi
    ;;

  debian)
    if [[ "$VERSION_CODENAME" =~ ^(trixie|forky)$ ]]; then
      SUFFIX="${ARCH}_${VERSION_CODENAME}"
    else
      echo "This installer is not compatible with Debian $VERSION_CODENAME" >&2
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
      echo "This installer is not compatible with Kali Linux $VERSION_ID" >&2
      exit 1
    fi
    SUFFIX="${ARCH}_${DEBIAN_CODENAME}"
    ;;

  sparky)
    # Map sparky versions to Debian codenames
    declare -A SPARKY_TO_DEBIAN=(
      ["8"]="trixie"
    )
    SPARKY_VERSION="$VERSION_ID"
    DEBIAN_CODENAME=${SPARKY_TO_DEBIAN[$SPARKY_VERSION]}
    if [ -z "$DEBIAN_CODENAME" ]; then
      echo "This installer is not compatible with Sparky Linux $VERSION_ID" >&2
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
        ["resolute"]="26.04"
        ["noble"]="24.04"
      )

      if [[ -n "${SUPPORTED_VERSIONS[$UBUNTU_CODENAME]}" ]]; then
        SUFFIX="${ARCH}_${SUPPORTED_VERSIONS[$UBUNTU_CODENAME]}"
      else
        echo "This installer is not compatible with $ID $VERSION" >&2
        exit 1
      fi
    fi
    ;;

  *)
    if [[ "$UBUNTU_VERSION_ID" =~ ^(26.04|24.04)$ ]]; then
      SUFFIX="${ARCH}_${UBUNTU_VERSION_ID}"
    else
      echo "This install script is not compatible with $ID." >&2
      echo "If this distribution is based on Ubuntu, you can open an issue to add support to the install script." >&2
      echo "https://github.com/mkasberg/ghostty-ubuntu/issues/new?template=Blank+issue" >&2
      echo "" >&2
      echo "Please copy and paste the following information into the issue on GitHub to identify your distribution." >&2
      echo "" >&2
      cat /etc/os-release >&2
      echo "" >&2
      echo "In the mean time, you can try manually installing a .deb file from https://github.com/mkasberg/ghostty-ubuntu?tab=readme-ov-file#manual-installation" >&2
      exit 1
    fi
    ;;
esac


# Look up the .deb download URL, resilient to GitHub API rate limits.
# Echoes the URL on stdout, or nothing on failure.
fetch_deb_url() {
  local pattern="$1"
  local response http_code body match

  # Try the JSON API with retry+backoff (3 attempts).
  for attempt in 1 2 3; do
    response=$(curl -sL -w $'\n%{http_code}' \
      "https://api.github.com/repos/mkasberg/ghostty-ubuntu/releases/latest" || true)
    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | sed '$d')

    if [[ "$http_code" == "403" ]] && echo "$body" | grep -q "rate limit"; then
      echo "  GitHub API rate-limited (attempt $attempt/3), sleeping 30s..." >&2
      sleep 30
      continue
    fi

    match=$(echo "$body" | grep -oP "$pattern" | head -1 || true)
    if [[ -n "$match" ]]; then
      echo "$match"
      return 0
    fi
    # No rate limit, no match — don't retry
    break
  done

  # Fallback: scrape the latest release's expanded_assets HTML page
  # (no API rate limit, but requires an extra redirect to find the tag name).
  echo "  API did not return a match, falling back to HTML releases page..." >&2
  local tag html
  tag=$(curl -sLI -o /dev/null -w '%{url_effective}' \
        "https://github.com/mkasberg/ghostty-ubuntu/releases/latest" \
        | grep -oP 'tag/\K[^/]+' | head -1 || true)
  if [[ -z "$tag" ]]; then
    return 1
  fi
  html=$(curl -sL "https://github.com/mkasberg/ghostty-ubuntu/releases/expanded_assets/$tag" || true)
  echo "$html" | grep -oP "$pattern" | head -1
}

echo "Looking for Ghostty .deb for ${SUFFIX}..." >&2
GHOSTTY_DEB_URL=$(fetch_deb_url \
  "https://github\.com/mkasberg/ghostty-ubuntu/releases/download/[^\s/\"]+/ghostty_[^\s/_]+_${SUFFIX}\.deb")

if [[ -z "$GHOSTTY_DEB_URL" ]]; then
  echo "" >&2
  echo "Error: Failed to retrieve the .deb package URL for ${SUFFIX}." >&2
  echo "  Searched: https://github.com/mkasberg/ghostty-ubuntu/releases" >&2
  echo "  If a matching .deb exists there, please open an issue." >&2
  exit 1
fi
GHOSTTY_DEB_FILE=$(basename "$GHOSTTY_DEB_URL")

echo "Downloading ${GHOSTTY_DEB_FILE}..." >&2
curl -fL -O "$GHOSTTY_DEB_URL"

echo "Installing ${GHOSTTY_DEB_FILE}..." >&2
if [[ $EUID -ne 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi
$SUDO apt-get install -y ./"$GHOSTTY_DEB_FILE"
rm "$GHOSTTY_DEB_FILE"
