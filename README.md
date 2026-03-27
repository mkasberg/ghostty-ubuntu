
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

We provide amd64 and and arm64 builds for:

 - Ubuntu 25.10 Jammy
 - Ubuntu 24.04 LTS Noble
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
   sudo dpkg -i <filename>.deb
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
you can build the Docker image to get a build environment for any Ubuntu version
(if you don't want to use your laptop as the build environment).

```bash
cd build-binary
docker build -t ghostty-ubuntu:latest --build-arg DISTRO=ubuntu --build-arg DISTRO_VERSION=25.10 --build-arg ZIG_VERSION=0.15.2 .
```

Then you can use that build environment to produce a binary .deb package.

```bash
docker run --rm -v$PWD:/workspace -w /workspace ghostty-ubuntu:latest /bin/bash build-ghostty.sh
```

Alternatively, you can try running [build-ghostty.sh](build-ghostty.sh) on your
own system, but you'll have to have all the build dependencies installed as in
the [Dockerfile](build-binary/Dockerfile).

Building the PPA package locally is left as an exercise for the reader.
