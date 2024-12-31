#!/bin/bash

# Sets up the environment to build Ghostty on Ubuntu

set -e

DEBIAN_FRONTEND="noninteractive"
ZIG_VERSION="0.13.0"

# Install Build Tools
apt-get -qq update && apt-get -qq -y install build-essential debhelper devscripts pandoc libonig-dev libbz2-dev wget

wget -q "https://github.com/jedisct1/minisign/releases/download/0.11/minisign-0.11-linux.tar.gz"
tar -xzf minisign-0.11-linux.tar.gz
mv minisign-linux/x86_64/minisign /usr/local/bin
rm -r minisign-linux

wget -q "https://ziglang.org/download/$ZIG_VERSION/zig-linux-x86_64-$ZIG_VERSION.tar.xz"
tar -xf "zig-linux-x86_64-$ZIG_VERSION.tar.xz" -C /opt
rm "zig-linux-x86_64-$ZIG_VERSION.tar.xz"
ln -s "/opt/zig-linux-x86_64-$ZIG_VERSION/zig" /usr/local/bin/zig

# Install Ghostty Dependencies
apt-get -qq -y install libgtk-4-dev libadwaita-1-dev
