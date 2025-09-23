# We want to isntall minisign via apt if possible for build security.
# But it's not available that way in 22.04.

set -e

source /etc/os-release

if [ $(lsb_release -sr) = "22.04" ]; then
  DEBIAN_FRONTEND="noninteractive" apt-get -qq update
  apt-get -qq -y --no-install-recommends install ca-certificates
  rm -rf /var/lib/apt/lists/*
  wget -q "https://github.com/jedisct1/minisign/releases/download/0.11/minisign-0.11-linux.tar.gz"
  tar -xzf minisign-0.11-linux.tar.gz
  mv "minisign-linux/$(uname -m)/minisign" /usr/local/bin
  rm -r minisign-linux
else
  DEBIAN_FRONTEND="noninteractive" apt-get -qq update
  apt-get -qq -y --no-install-recommends install minisign
  rm -rf /var/lib/apt/lists/*
fi
