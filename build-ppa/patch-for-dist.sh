#!/bin/bash
#
# Patch the PPA build for different ubuntu codenames
#
# Usage: ./patch-for-dist.sh [OPTIONS]
#   Options:
#     -h             Show this help message
#     -c CODENAME    Ubuntu codename (noble, questing, etc.)
#

set -e

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
CODENAME="resolute"

while getopts 'hc:' opt; do
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
        '?')
            echo "Invalid option: -$OPTARG"
            exit 1
            ;;
    esac
done

echo "Done patching packaging source for $CODENAME"
