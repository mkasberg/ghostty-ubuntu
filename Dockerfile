ARG UBUNTU_VERSION="24.10"
FROM ubuntu:${UBUNTU_VERSION}

# Install Build Tools
RUN apt-get update && apt-get install -y \
    build-essential \
    debhelper \
    devscripts \
    libbz2-dev \
    libonig-dev \
    pandoc \
    wget

# Install Minisign
# https://jedisct1.github.io/minisign/
RUN wget -q "https://github.com/jedisct1/minisign/releases/download/0.11/minisign-0.11-linux.tar.gz" && \
    tar -xzf minisign-0.11-linux.tar.gz && \
    mv minisign-linux/x86_64/minisign /usr/local/bin && \
    rm -r minisign-linux

# Install zig
# https://ziglang.org/download/
ARG ZIG_VERSION="0.13.0"
RUN wget -q "https://ziglang.org/download/$ZIG_VERSION/zig-linux-x86_64-$ZIG_VERSION.tar.xz" && \
    tar -xf "zig-linux-x86_64-$ZIG_VERSION.tar.xz" -C /opt && \
    rm "zig-linux-x86_64-$ZIG_VERSION.tar.xz" && \
    ln -s "/opt/zig-linux-x86_64-$ZIG_VERSION/zig" /usr/local/bin/zig

# Install Ghostty Dependencies
RUN apt-get update && apt-get install -y libadwaita-1-dev libgtk-4-dev
