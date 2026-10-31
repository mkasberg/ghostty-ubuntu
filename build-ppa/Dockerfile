ARG CODENAME="noble"
FROM ubuntu:${CODENAME}

ARG CODENAME
ENV CODENAME=${CODENAME}

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install base tools needed for PPA builds
RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
        git \
        devscripts \
        build-essential \
        debhelper \
        wget \
        minisign \
        dput \
        gnupg \
        equivs \
        software-properties-common && \
    rm -rf /var/lib/apt/lists/*

# Install Zig build dependencies (Zig is less likely to change, so install first for better caching)
COPY zig0.15/debian/control /tmp/zig-control/
RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
        chrpath \
        cmake \
        help2man \
        libbsd-dev \
        libclang-20-dev \
        libclang-cpp20-dev \
        libedit-dev \
        libffi-dev \
        liblld-20-dev \
        libmd-dev \
        libncurses-dev \
        libunwind-dev \
        libxml2-dev \
        llvm-20-dev && \
    cd /tmp/zig-control && \
    mk-build-deps -i -t 'apt-get -y -qq --no-install-recommends' control && \
    rm -f *.deb && \
    rm -rf /tmp/zig-control /var/lib/apt/lists/*

# Install Ghostty build dependencies (Ghostty is more likely to change, so install last)
# Note: libgtk4-layer-shell-dev is not available on 24.04 (noble)
COPY ghostty/debian/control /tmp/ghostty-control/
RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
        pandoc \
        pkgconf \
        libadwaita-1-dev \
        libbz2-dev \
        libgtk-4-dev \
        libonig-dev \
        libxml2-utils && \
    if [ "${CODENAME}" != "noble" ]; then \
        apt-get install -y -qq --no-install-recommends libgtk4-layer-shell-dev; \
    fi && \
    cd /tmp/ghostty-control && \
    mk-build-deps -i -t 'apt-get -y -qq --no-install-recommends' control && \
    rm -f *.deb && \
    rm -rf /tmp/ghostty-control /var/lib/apt/lists/*

# Set up working directory
WORKDIR /workspace

LABEL org.opencontainers.image.source="https://github.com/mkasberg/ghostty-ubuntu"
LABEL org.opencontainers.image.description="Pre-built PPA builder image for Ghostty and Zig packaging"
LABEL org.opencontainers.image.licenses="MIT"
