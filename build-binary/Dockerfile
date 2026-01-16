ARG DISTRO_VERSION="25.10"
ARG DISTRO="ubuntu"
FROM ${DISTRO}:${DISTRO_VERSION}

ARG DISTRO_VERSION
ENV DISTRO_VERSION=${DISTRO_VERSION}
ARG DISTRO
ENV DISTRO=${DISTRO}

# Install Dependencies
RUN DEBIAN_FRONTEND="noninteractive" apt-get -qq update && \
    apt-get -qq -y --no-install-recommends install \
    # Build Tools
    build-essential \
    libbz2-dev \
    libonig-dev \
    lintian \
    lsb-release \
    minisign \
    pandoc \
    wget \
    # Ghostty Dependencies
    # https://ghostty.org/docs/install/build#debian-and-ubuntu
    gettext \
    libadwaita-1-dev \
    libgtk-4-dev \
    libxml2-utils && \
    # Install libgtk4-layer-shell-dev but not on 24.04
    if [ "$DISTRO" = "ubuntu" ] && [ "$DISTRO_VERSION" != "24.04" ]; then \
        apt-get -qq -y --no-install-recommends install libgtk4-layer-shell-dev; \
    fi && \
    # Clean up for better caching
    rm -rf /var/lib/apt/lists/*

# Install zig
# https://ziglang.org/download/
ARG ZIG_VERSION="0.14.1"
RUN echo "https://ziglang.org/download/$ZIG_VERSION/zig-$(uname -m)-linux-$ZIG_VERSION.tar.xz"
RUN wget -q "https://ziglang.org/download/$ZIG_VERSION/zig-$(uname -m)-linux-$ZIG_VERSION.tar.xz" && \
    wget -q "https://ziglang.org/download/$ZIG_VERSION/zig-$(uname -m)-linux-$ZIG_VERSION.tar.xz.minisig" && \
    minisign -Vm "zig-$(uname -m)-linux-$ZIG_VERSION.tar.xz" -P "RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U" && \
    tar -xf "zig-$(uname -m)-linux-$ZIG_VERSION.tar.xz" -C /opt && \
    rm zig-* && \
    ln -s "/opt/zig-$(uname -m)-linux-$ZIG_VERSION/zig" /usr/local/bin/zig
