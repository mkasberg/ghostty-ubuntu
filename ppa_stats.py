#!/usr/bin/env -S uv run --script
# /// script
# dependencies = [
#   "launchpadlib",
# ]
# ///

# Use this script to get download (install) counts from Launchpad.
# No authentication required. These are public stats that anyone can view.
# Run it with uv:
#   uv run ppa_stats.py

import os
import collections
from launchpadlib.launchpad import Launchpad

# Configuration
PPA_OWNER = 'mkasberg'
PPA_NAME = 'ghostty-ubuntu'
PACKAGE_NAME = 'ghostty'
CACHE_DIR = os.path.expanduser('~/.launchpadlib/cache/')

def get_ppa_stats():
    # Login anonymously for read-only access
    lp = Launchpad.login_anonymously('ppa-stats-client', 'production', CACHE_DIR)
    
    # Get the PPA owner and the specific PPA
    try:
        owner = lp.people[PPA_OWNER]
        ppa = owner.getPPAByName(name=PPA_NAME)
    except Exception as e:
        print(f"Error finding PPA: {e}")
        return

    print(f"Fetching statistics for {PPA_OWNER}/{PPA_NAME}/{PACKAGE_NAME}...")
    
    # Get all published binaries for the package
    binaries = ppa.getPublishedBinaries(binary_name=PACKAGE_NAME)
    
    stats = collections.defaultdict(int)
    
    for binary in binaries:
        # Explicitly check that the package name matches exactly
        if binary.binary_package_name != PACKAGE_NAME:
            continue
            
        count = binary.getDownloadCount()
        if count > 0:
            stats[binary.binary_package_version] += count
            
    if not stats:
        print("No download statistics found.")
        return

    # Sort versions (roughly, since they are strings)
    sorted_versions = sorted(stats.keys(), reverse=True)

    print(f"\n{'Version':<40} | {'Downloads'}")
    print("-" * 55)
    
    total_downloads = 0
    for version in sorted_versions:
        count = stats[version]
        total_downloads += count
        print(f"{version:<40} | {count}")
            
    print("-" * 55)
    print(f"Total Downloads: {total_downloads}")

if __name__ == "__main__":
    get_ppa_stats()
