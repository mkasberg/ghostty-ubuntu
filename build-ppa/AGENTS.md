# Agent Notes

This is a packaging repository for an Ubuntu PPA for Ghostty. We also build zig
because we need a more recent/specific version than Ubuntu offers.

Ghostty packaging has two variants:
- `ghostty` - Stable releases
- `ghostty-nightly` - Nightly builds

We build ghostty-nightly from our own main branch to keep up with changes, and we'll create a release branch for each stable release going forward. Both packages conflict with each other to prevent simultaneous installation.

Zig packaging source is at `zig0.15/debian`. We also have some non-standard scripts in this build-ppa dir to fetch sources, do minor workarounds, and perform the PPA builds.
