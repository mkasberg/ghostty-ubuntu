# Agent Notes

This is a packaging repository for an Ubuntu PPA for Ghostty. We also build zig
because we need a more recent/specific version than Ubuntu offers.

## Binary Builds

`build-binary/` contains scripts to build a binary debian package with dpkg-deb. We build and publish this on GitHub, we can't upload binary packages to a PPA.

## PPA Builds

`build-ppa/` contains scripts to build a source debian package with debuild (debhelper) for upload to a PPA.

Ghostty packaging has two PPAs:
- mkasberg/ghostty-ubuntu-nightly gets nightly builds from nightly.yml.
- mkasberg/ghostty gets stable versioned builds.

Ghostty PPA packaging source is at `build-ppa/ghostty`. Ghostty publishes a "tip" source that we use for nightly builds. Our scripts take this into account, and consruct a date-based package version to make sure it's increasing. The same scripts accept different arguments to publish a stable version of ghostty (from a versioned source download).

Zig PPA packaging source is at `zig0.15/debian`. We also have some non-standard scripts in this build-ppa dir to fetch sources, do minor workarounds, and perform the PPA builds.
