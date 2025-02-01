ARG DISTRO_VERSION="24.10"
ARG DISTRO="ubuntu"
FROM ${DISTRO}:${DISTRO_VERSION}

# Install Dependencies
RUN DEBIAN_FRONTEND="noninteractive" apt-get -qq update && \
    apt-get -qq -y --no-install-recommends install \
    # Build Tools
    build-essential \
    libbz2-dev \
    libonig-dev \
    lintian \
    lsb-release \
    pandoc \
    wget \
    # Ghostty Dependencies
    libadwaita-1-dev \
    libgtk-4-dev && \
    # Clean up for better caching
    rm -rf /var/lib/apt/lists/*

ADD install-minisign.sh .
RUN bash install-minisign.sh

# Install zig
# https://ziglang.org/download/
ARG ZIG_VERSION="0.13.0"
RUN wget -q "https://ziglang.org/download/$ZIG_VERSION/zig-linux-$(uname -m)-$ZIG_VERSION.tar.xz" && \
    wget -q "https://ziglang.org/download/$ZIG_VERSION/zig-linux-$(uname -m)-$ZIG_VERSION.tar.xz.minisig" && \
    minisign -Vm "zig-linux-$(uname -m)-$ZIG_VERSION.tar.xz" -P "RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U" && \
    tar -xf "zig-linux-$(uname -m)-$ZIG_VERSION.tar.xz" -C /opt && \
    rm zig-linux-* && \
    ln -s "/opt/zig-linux-$(uname -m)-$ZIG_VERSION/zig" /usr/local/bin/zig
