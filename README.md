# ghostty-ubuntu
PPA packaging source for mkasberg/ghostty-ubuntu

## Zig
A recent version of zig is needed to build ghostty.

    cd zig
    uscan --repack -v
    debuild -S -sa
    dput dput ppa:mkasberg/ghostty-ubuntu ../zig_*_source.changes
