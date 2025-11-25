# ghostty-ubuntu
PPA packaging source for mkasberg/ghostty-ubuntu

## Zig
A recent version of zig is needed to build ghostty.

    cd zig
    uscan --repack -v
    debuild -S -sa
    dput ppa:mkasberg/ghostty-ubuntu ../zig_*_source.changes

## Ghostty

    cd ghostty
    uscan -v
    debuild -S -sa
    dput ppa:mkasberg/ghostty-ubuntu ../ghostty_*_source.changes
