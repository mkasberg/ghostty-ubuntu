# Agent Notes

This is a packaging repository for an Ubuntu PPA for Ghostty. We also build zig
because we need a more recent version than Ubuntu offers.

Ghostty packaging has two variants:
- `ghostty/debian` - Stable releases
- `ghostty-nightly/debian` - Nightly builds

Both packages conflict with each other to prevent simultaneous installation.

Zig packaging source is at `zig0.14/debian`. We also have some non-standard scripts at the root of this
repository.

