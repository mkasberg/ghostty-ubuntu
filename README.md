
![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/mkasberg/ghostty-ubuntu/total)
![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/mkasberg/ghostty-ubuntu/latest/total)
![GitHub Release](https://img.shields.io/github/v/release/mkasberg/ghostty-ubuntu)
![GitHub Release Date](https://img.shields.io/github/release-date/mkasberg/ghostty-ubuntu)

![Ghostty Logo](ghostty-logo.png)

# Ghostty Ubuntu

This repository contains build scripts to produce an _unofficial_ Ubuntu/Debian
package (.deb) for [Ghostty](https://ghostty.org).

This is an unofficial community project to provide a package that's easy to
install on Ubuntu. If you're looking for the Ghostty source code, see
[ghostty-org/ghostty](https://github.com/ghostty-org/ghostty).

## Install/Update

:zap: Just paste this into your terminal and run it!

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
```

> [!WARNING]
> A recent GTK is required for Ghostty to work with Nvidia (GL) drivers under
> X11. **Ubuntu 22.04 LTS has GTK 4.6 which is not new enough.** Ubuntu 23.10+ should be fine. (See the
> [note](https://ghostty.org/docs/install/build#debian-and-ubuntu) in the
> Ghostty docs.)

## Manual Installation

If you prefer to download and install the package manually instead of running the short script above, here are instructions.

1. Download the .deb package for your Ubuntu version. (Also available on our [Releases](https://github.com/mkasberg/ghostty-ubuntu/releases) page.)
   - **Ubuntu 25.04 Plucky:** [ghostty_1.1.3-0.ppa2_amd64_25.04.deb](https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.1.3-0-ppa2/ghostty_1.1.3-0.ppa2_amd64_25.04.deb)
   - **Ubuntu 24.10 Oracular:** [ghostty_1.1.3-0.ppa2_amd64_24.10.deb](https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.1.3-0-ppa2/ghostty_1.1.3-0.ppa2_amd64_24.10.deb)
   - **Ubuntu 24.04 LTS Noble:** [ghostty_1.1.3-0.ppa2_amd64_24.04.deb](https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.1.3-0-ppa2/ghostty_1.1.3-0.ppa2_amd64_24.04.deb)
   - **Ubuntu 22.04 LTS Jammy:** [ghostty_1.1.3-0.ppa2_amd64_22.04.deb](https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.1.3-0-ppa2/ghostty_1.1.3-0.ppa2_amd64_22.04.deb)
   - **Debian Bookworm:** [ghostty_1.1.3-0.ppa2_amd64_bookworm.deb](https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.1.3-0-ppa2/ghostty_1.1.3-0.ppa2_amd64_bookworm.deb)
   - **Arm64 Ubuntu 25.04 Plucky:** [ghostty_1.1.3-0.ppa2_arm64_25.04.deb](https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.1.3-0-ppa2/ghostty_1.1.3-0.ppa2_arm64_25.04.deb)
   - **Arm64 Ubuntu 24.10 Oracular:** [ghostty_1.1.3-0.ppa2_arm64_24.10.deb](https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.1.3-0-ppa2/ghostty_1.1.3-0.ppa2_arm64_24.10.deb)
   - **Arm64 Ubuntu 24.04 LTS Noble:** [ghostty_1.1.3-0.ppa2_arm64_24.04.deb](https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.1.3-0-ppa2/ghostty_1.1.3-0.ppa2_arm64_24.04.deb)
   - **Arm64 Ubuntu 22.04 LTS Jammy:** [ghostty_1.1.3-0.ppa2_arm64_22.04.deb](https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.1.3-0-ppa2/ghostty_1.1.3-0.ppa2_arm64_22.04.deb)
   - **Arm64 Debian Bookworm:** [ghostty_1.1.3-0.ppa2_arm64_bookworm.deb](https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.1.3-0-ppa2/ghostty_1.1.3-0.ppa2_arm64_bookworm.deb)
2. Install the downloaded .deb package.

   ```sh
   sudo dpkg -i <filename>.deb
   ```
## Updating

To update to a new version, just follow any of the installation methods above. There's no need to uninstall the old version; it will be updated correctly.

## Contributing

I want to have an easy-to-install Ghostty package for Ubuntu, so I'm doing what
I can to make it happen. (Ghostty [relies on the
community](https://ghostty.org/docs/install/binary) to produce non-macOS
packages.) I'm sure the scripts I have so far can be improved, so please open an
issue or PR if you notice any problems!

GitHub Actions will run CI on each PR to test that we can produce a build.

If you want to test locally, our current approach uses Docker for a build
environment. The details of how the process works are in
[build.yml](.github/workflows//build.yml), but at a high level you can build the
docker image

```bash
docker build -t ghostty-ubuntu:latest --build-arg DISTRO=ubuntu --build-arg DISTRO_VERSION=24.10 .
```

And then use that build environment to produce a binary .deb package

```bash
docker run --rm -v$PWD:/workspace -w /workspace ghostty-ubuntu:latest /bin/bash build-ghostty.sh
```

Alternatively, you can try running [build-ghostty.sh](build-ghostty.sh) on your
own system, but you'll have to have all the build dependencies installed as in
the [Dockerfile](Dockerfile).

## Roadmap

- [x] Produce a .deb package on GitHub Releases
- [ ] Set up a PPA (or other apt repo?) for easier updates
- [ ] Ghostty is available in official Ubuntu repos
