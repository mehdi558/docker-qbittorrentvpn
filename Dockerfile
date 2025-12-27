# qBittorrent, OpenVPN and WireGuard
# Ultra-fast build using Debian packages
FROM debian:bookworm-slim

WORKDIR /opt

RUN usermod -u 99 nobody

# Make directories
RUN mkdir -p /downloads /config/qBittorrent /etc/openvpn /etc/qbittorrent

# Install qBittorrent and all dependencies in one go
RUN apt update && apt upgrade -y \
    && apt install -y --no-install-recommends \
    ca-certificates \
    dos2unix \
    inetutils-ping \
    ipcalc \
    iptables \
    kmod \
    moreutils \
    net-tools \
    openresolv \
    openvpn \
    procps \
    qbittorrent-nox \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install WireGuard from unstable
RUN echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/unstable-wireguard.list \
    && printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' > /etc/apt/preferences.d/limit-unstable \
    && apt update \
    && apt install -y --no-install-recommends wireguard-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install compression tools
RUN echo "deb http://deb.debian.org/debian/ bookworm non-free non-free-firmware" > /etc/apt/sources.list.d/non-free-unrar.list \
    && printf 'Package: *\nPin: release a=non-free\nPin-Priority: 150\n' > /etc/apt/preferences.d/limit-non-free \
    && apt update \
    && apt install -y --no-install-recommends \
    p7zip-full \
    unrar \
    unzip \
    zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Verify qBittorrent installation
RUN qbittorrent-nox --version

# Remove src_valid_mark from wg-quick
RUN sed -i /net\.ipv4\.conf\.all\.src_valid_mark/d `which wg-quick`

VOLUME /config /downloads

ADD openvpn/ /etc/openvpn/
ADD qbittorrent/ /etc/qbittorrent/

RUN chmod +x /etc/qbittorrent/*.sh /etc/qbittorrent/*.init /etc/openvpn/*.sh

EXPOSE 8080 8999 8999/udp

CMD ["/bin/bash", "/etc/openvpn/start.sh"]
