# qBittorrent, OpenVPN and WireGuard, qbittorrentvpn
# Optimized for GitHub Actions - All packages from Debian repos
FROM debian:bookworm-slim

WORKDIR /opt

RUN usermod -u 99 nobody

# Make directories
RUN mkdir -p /downloads /config/qBittorrent /etc/openvpn /etc/qbittorrent

# Install ALL build dependencies from Debian repos (no API calls, no compilation)
RUN apt update \
    && apt upgrade -y \
    && apt install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    libboost-dev \
    libboost-system-dev \
    libboost-chrono-dev \
    libboost-random-dev \
    libssl-dev \
    ninja-build \
    pkg-config \
    qtbase5-dev \
    qttools5-dev \
    zlib1g-dev \
    && echo "All build tools installed from Debian" \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Compile and install libtorrent-rasterbar (only external component we need)
RUN apt update \
    && apt install -y --no-install-recommends \
    ca-certificates \
    curl \
    && echo "Downloading libtorrent..." \
    && curl -L -o /opt/libtorrent.tar.gz \
       "https://github.com/arvidn/libtorrent/releases/download/v1.2.19/libtorrent-rasterbar-1.2.19.tar.gz" \
    && tar -xzf /opt/libtorrent.tar.gz -C /opt \
    && rm /opt/libtorrent.tar.gz \
    && cd /opt/libtorrent-rasterbar-1.2.19 \
    && echo "Compiling libtorrent..." \
    && cmake -G Ninja -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_CXX_STANDARD=17 \
    && cmake --build build --parallel $(nproc) \
    && cmake --install build \
    && cd /opt \
    && rm -rf /opt/* \
    && apt purge -y ca-certificates curl \
    && apt-get clean \
    && apt --purge autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Compile and install qBittorrent
RUN apt update \
    && apt install -y --no-install-recommends \
    ca-certificates \
    curl \
    && echo "Downloading qBittorrent..." \
    && QBITTORRENT_VERSION="release-5.1.4" \
    && curl -L -o /opt/qbittorrent.tar.gz \
       "https://github.com/qbittorrent/qBittorrent/archive/${QBITTORRENT_VERSION}.tar.gz" \
    && tar -xzf /opt/qbittorrent.tar.gz -C /opt \
    && rm /opt/qbittorrent.tar.gz \
    && cd /opt/qBittorrent-${QBITTORRENT_VERSION} \
    && echo "Compiling qBittorrent ${QBITTORRENT_VERSION}..." \
    && cmake -G Ninja -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DGUI=OFF \
        -DCMAKE_CXX_STANDARD=17 \
    && cmake --build build --parallel $(nproc) \
    && cmake --install build \
    && cd /opt \
    && rm -rf /opt/* \
    && apt purge -y ca-certificates curl \
    && apt-get clean \
    && apt --purge autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Remove build dependencies to reduce image size
RUN apt update \
    && apt purge -y \
    build-essential \
    cmake \
    git \
    libboost-dev \
    libboost-system-dev \
    libboost-chrono-dev \
    libboost-random-dev \
    libssl-dev \
    ninja-build \
    pkg-config \
    qtbase5-dev \
    qttools5-dev \
    zlib1g-dev \
    && apt-get clean \
    && apt --purge autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Install runtime dependencies
RUN echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/unstable-wireguard.list \
    && printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' > /etc/apt/preferences.d/limit-unstable \
    && apt update \
    && apt install -y --no-install-recommends \
    ca-certificates \
    dos2unix \
    inetutils-ping \
    ipcalc \
    iptables \
    kmod \
    libqt5network5 \
    libqt5sql5 \
    libqt5xml5 \
    libssl3 \
    moreutils \
    net-tools \
    openresolv \
    openvpn \
    procps \
    wireguard-tools \
    && apt-get clean \
    && apt --purge autoremove -y \
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
    && apt --purge autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Remove src_valid_mark from wg-quick
RUN sed -i /net\.ipv4\.conf\.all\.src_valid_mark/d `which wg-quick`

VOLUME /config /downloads

ADD openvpn/ /etc/openvpn/
ADD qbittorrent/ /etc/qbittorrent/

RUN chmod +x /etc/qbittorrent/*.sh /etc/qbittorrent/*.init /etc/openvpn/*.sh

EXPOSE 8080
EXPOSE 8999
EXPOSE 8999/udp

CMD ["/bin/bash", "/etc/openvpn/start.sh"]
