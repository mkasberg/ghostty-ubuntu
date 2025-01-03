
![Ghostty Logo](ghostty-logo.png)

# Ghostty Ubuntu

This repository contains build scripts to produce an _unofficial_ Ubuntu package
(.deb) for [Ghostty](https://ghostty.org).

This is an unofficial community project to provide a package that's easy to
install on Ubuntu. If you're looking for the Ghostty source code, see
[ghostty-org/ghostty](https://github.com/ghostty-org/ghostty).

## Install/Update

:zap: Just paste this into your terminal and run it!

```sh
source /etc/os-release
curl -s https://api.github.com/repos/mkasberg/ghostty-ubuntu/releases/latest \
	| grep "browser_download_url.*amd64_${VERSION_ID}.deb" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| head -n 1 \
	| xargs -n 1 curl -LO
sudo dpkg -i ghostty_*amd64_${VERSION_ID}.deb
rm ghostty_*amd64_${VERSION_ID}.deb
```

> [!WARNING]
> A recent GTK is required for Ghostty to work with Nvidia (GL) drivers under
> X11. **Ubuntu 22.04 LTS has GTK 4.6 which is not new enough.** Ubuntu 23.10+ should be fine. (See the
> [note](https://ghostty.org/docs/install/build#debian-and-ubuntu) in the
> Ghostty docs.)

## Manual Installation

If you prefer to download and install the package manually instead of running the short script above, here are instructions.

1. Download the .deb package for your Ubuntu version. (Also available on our [Releases](https://github.com/mkasberg/ghostty-ubuntu/releases) page.)
   - **Ubuntu 24.10 Oracular:** [ghostty_1.0.1-0.ppa1_amd64_24.10.deb](https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.0.1-0-ppa1/ghostty_1.0.1-0.ppa1_amd64_24.10.deb)
   - **Ubuntu 24.04 LTS Noble:** [ghostty_1.0.1-0.ppa1_amd64_24.04.deb](https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.0.1-0-ppa1/ghostty_1.0.1-0.ppa1_amd64_24.04.deb)
   - **Ubuntu 22.04 LTS Jammy:** [ghostty_1.0.1-0.ppa1_amd64_22.04.deb](https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.0.1-0-ppa1/ghostty_1.0.1-0.ppa1_amd64_22.04.deb)
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

If you want to test locally, you should be able to run
[setup-env.sh](https://github.com/mkasberg/ghostty-ubuntu/blob/main/setup-env.sh)
and
[build-ghostty.sh](https://github.com/mkasberg/ghostty-ubuntu/blob/main/build-ghostty.sh)
on your own Ubuntu system or in an Ubuntu Docker container.

## Roadmap

- [x] Produce a .deb package on GitHub Releases
- [ ] Set up a PPA (or other apt repo?) for easier updates
- [ ] Ghostty is available in official Ubuntu repos
