
![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/mkasberg/ghostty-ubuntu/total)
![GitHub Release](https://img.shields.io/github/v/release/mkasberg/ghostty-ubuntu)
![GitHub Release Date](https://img.shields.io/github/release-date/mkasberg/ghostty-ubuntu)

![Ghostty Logo](ghostty-logo.png)

# Ghostty Ubuntu

This repository contains build scripts to produce an _unofficial_ Ubuntu/Debian
package (.deb) and PPA for [Ghostty](https://ghostty.org).

This is an unofficial community project to provide a package that's easy to
install on Ubuntu. If you're looking for the Ghostty source code, see
[ghostty-org/ghostty](https://github.com/ghostty-org/ghostty).

> [!NOTE]
> [Ghostty is in the official Ubuntu
> repositories](https://launchpad.net/ubuntu/+source/ghostty) for Ubuntu 26.04+.
> To install Ghostty from the Ubuntu repositories, just run `sudo apt install
> ghostty`. However, that version may lag behind the latest Ghostty release. As
> of October, 2026, the official Ubuntu repositories provide Ghostty 1.3.0 and
> the PPA below provides Ghostty 1.4.0. If the official Ubuntu packages are
> recent enough for you, that may be the better option. If you want the most
> recent version of Ghostty, the PPA below will allow you to install it.

## Install/Update

:rocket: Add the [Launchpad PPA](https://launchpad.net/~mkasberg/+archive/ubuntu/ghostty-ubuntu)
and install Ghostty:

```sh
sudo add-apt-repository ppa:mkasberg/ghostty-ubuntu
sudo apt update
sudo apt install ghostty
```

After adding the PPA and installing Ghostty, updates will happen automatically
via apt!

## Supported Operating Systems

We provide amd64 and arm64 builds for:

 - Ubuntu 26.04 Resolute Raccoon
 - Ubuntu 24.04 LTS Noble Numbat (up to Ghostty 1.3.1)
 - Debian Forky
 - Debian Trixie

## Alternative Installation Methods

The PPA above is the recommended installation method for anyone who can use it.
If you can't use the PPA, or don't want to use the PPA, or your distribution
isn't compatible with the PPA, you can try one of the alternative installation
methods below.

### Curl Install/Update

:zap: Just paste this into your terminal and run it!

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
```

### Manual Installation

If you prefer to download and install the package manually instead of running the short script above, here are instructions.

1. Download the .deb package for your Ubuntu version from our
   [Releases](https://github.com/mkasberg/ghostty-ubuntu/releases) page. Make sure
   you get the correct OS, version, and arch (amd64/arm64).

2. Install the downloaded .deb package.

   ```sh
   sudo apt-get install ./ghostty_*.deb
   ```

### Updating

To update to a new version, just follow any of the installation methods above. There's no need to uninstall the old version; it will be updated correctly.

## Contributing

I want to have an easy-to-install Ghostty package for Ubuntu, so I'm doing what
I can to make it happen. (Ghostty [relies on the
community](https://ghostty.org/docs/install/binary) to produce non-macOS
packages.) I'm sure the scripts I have so far can be improved, so please open an
issue or PR if you notice any problems!

GitHub Actions will run CI on each PR to test that we can produce a build, and
the GitHub workflows at [binary-build.yml](.github/workflows/binary-build.yml),
[ppa-build-zig.yml](.github/workflows//ppa-build-zig.yml), and
[ppa-build-ghostty.yml](.github/workflows/ppa-build-ghostty.yml) are the most
up-to-date documentation of the build process.

If you want to build locally, the binary build is the easier. At a high level,
you can build the Docker image to get a build environment for any supported
distro (if you don't want to use your laptop as the build environment).

```bash
docker build -t ghostty-ubuntu:latest --build-arg DISTRO=ubuntu --build-arg DISTRO_VERSION=26.04 --build-arg ZIG_VERSION=0.17.0 build-binary/
```

For Debian, swap in a Debian base image. Debian Trixie is the current stable
release and the version most people want:

```bash
docker build -t ghostty-debian:latest --build-arg DISTRO=debian --build-arg DISTRO_VERSION=13 --build-arg ZIG_VERSION=0.17.0 build-binary/
```

Then you can use that build environment to produce a binary .deb package. The
package is written to `build-binary/` on your host.

```bash
docker run --rm -v$PWD:/workspace -w /workspace ghostty-ubuntu:latest /bin/bash build-binary/build-ghostty.sh
```

`podman` works the same way; just substitute it for `docker`, and add `:Z` to
the volume mount if you have SELinux enforcing:

```bash
podman run --rm -v$PWD:/workspace:Z -w /workspace ghostty-debian:latest /bin/bash build-binary/build-ghostty.sh
```

You can confirm the result by installing it into a clean container:

```bash
docker run --rm -v$PWD:/workspace -w /workspace debian:13 /bin/bash -c \
  'apt-get update && apt-get install -y ./build-binary/ghostty_*.deb && ghostty +version'
```

Alternatively, you can try running [build-ghostty.sh](build-binary/build-ghostty.sh) on your
own system, but you'll have to have all the build dependencies installed as in
the [Dockerfile](build-binary/Dockerfile).

## Notes on Zig Versions

Ghostty pins a specific Zig version (`minimum_zig_version` in
`build.zig.zon`), and Ghostty 1.4.0 requires Zig 0.17.0. The PPA builds Zig
itself from [build-ppa/zig0.17](build-ppa/zig0.17) because no Ubuntu release
ships a new enough version; that package needs LLVM 22, which is why PPA builds
target Ubuntu 26.04 only.

Zig 0.17 also changes how fetched dependencies are cached. It leaves them
compressed in `<cache>/p/<hash>.tar.gz` instead of unpacking them, so
`zig build --system <cache>/p` can't find them. Both build scripts run
[unpack-zig-cache.sh](unpack-zig-cache.sh) after fetching to expand them into
the directory layout `--system` expects.

Building the PPA package locally is left as an exercise for the reader.
