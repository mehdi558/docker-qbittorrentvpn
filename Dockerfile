# qBittorrent, OpenVPN and WireGuard, qbittorrentvpn
# Optimized for GitHub Actions - Uses Debian packages instead of compiling Boost
FROM debian:bookworm-slim

WORKDIR /opt

RUN usermod -u 99 nobody

# Make directories
RUN mkdir -p /downloads /config/qBittorrent /etc/openvpn /etc/qbittorrent

# Install Boost from Debian repos (faster, more reliable for GitHub Actions)
# This avoids the 10-15 min compilation that can timeout
RUN apt update \
    && apt upgrade -y \
    && apt install -y --no-install-recommends \
    libboost-dev \
    libboost-system-dev \
    libboost-chrono-dev \
    libboost-random-dev \
    && echo "Boost installed from Debian packages" \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Ninja
RUN apt update \
    && apt install -y --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    unzip \
    && NINJA_URL=$(curl -sL https://api.github.com/repos/ninja-build/ninja/releases/latest | jq -r '.assets[] | select(.name | contains("linux")) | .browser_download_url') \
    && echo "Downloading Ninja from ${NINJA_URL}" \
    && curl -o /opt/ninja-linux.zip -L "${NINJA_URL}" \
    && unzip -q /opt/ninja-linux.zip -d /opt \
    && mv /opt/ninja /usr/local/bin/ninja \
    && chmod +x /usr/local/bin/ninja \
    && rm -rf /opt/* \
    && apt purge -y ca-certificates curl jq unzip \
    && apt-get clean \
    && apt --purge autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Install cmake
RUN apt update \
    && apt install -y --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    && CMAKE_URL=$(curl -sL https://api.github.com/repos/Kitware/CMake/releases/latest | jq -r '.assets[] | select(.name | contains("Linux-x86_64.sh")) | .browser_download_url') \
    && echo "Downloading CMake from ${CMAKE_URL}" \
    && curl -o /opt/cmake.sh -L "${CMAKE_URL}" \
    && chmod +x /opt/cmake.sh \
    && /bin/bash /opt/cmake.sh --skip-license --prefix=/usr \
    && rm -rf /opt/* \
    && apt purge -y ca-certificates curl jq \
    && apt-get clean \
    && apt --purge autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Compile and install libtorrent-rasterbar
RUN apt update \
    && apt install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    jq \
    libssl-dev \
    && echo "Fetching latest libtorrent RC_1_2 release..." \
    && LIBTORRENT_URL=$(curl -sL "https://api.github.com/repos/arvidn/libtorrent/releases" | jq -r '[.[] | select(.prerelease==false) | select(.target_commitish=="RC_1_2")] | .[0] | .assets[0] | .browser_download_url') \
    && LIBTORRENT_NAME=$(curl -sL "https://api.github.com/repos/arvidn/libtorrent/releases" | jq -r '[.[] | select(.prerelease==false) | select(.target_commitish=="RC_1_2")] | .[0] | .assets[0] | .name') \
    && echo "Downloading ${LIBTORRENT_NAME} from ${LIBTORRENT_URL}" \
    && curl -o /opt/${LIBTORRENT_NAME} -L "${LIBTORRENT_URL}" \
    && tar -xzf /opt/${LIBTORRENT_NAME} -C /opt \
    && rm /opt/${LIBTORRENT_NAME} \
    && cd /opt/libtorrent-rasterbar* \
    && echo "Compiling libtorrent..." \
    && cmake -G Ninja -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX:PATH=/usr \
        -DCMAKE_CXX_STANDARD=17 \
    && cmake --build build --parallel $(nproc) \
    && cmake --install build \
    && cd /opt \
    && rm -rf /opt/* \
    && apt purge -y build-essential ca-certificates curl jq libssl-dev \
    && apt-get clean \
    && apt --purge autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Compile and install qBittorrent
RUN apt update \
    && apt install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    jq \
    libssl-dev \
    pkg-config \
    qtbase5-dev \
    qttools5-dev \
    zlib1g-dev \
    && QBITTORRENT_RELEASE=$(curl -sL "https://api.github.com/repos/qBittorrent/qBittorrent/releases/latest" | jq -r '.tag_name') \
    && echo "Building qBittorrent ${QBITTORRENT_RELEASE} on Debian Bookworm with Qt5" \
    && curl -o /opt/qBittorrent-${QBITTORRENT_RELEASE}.tar.gz -L "https://github.com/qbittorrent/qBittorrent/archive/${QBITTORRENT_RELEASE}.tar.gz" \
    && tar -xzf /opt/qBittorrent-${QBITTORRENT_RELEASE}.tar.gz -C /opt \
    && rm /opt/qBittorrent-${QBITTORRENT_RELEASE}.tar.gz \
    && cd /opt/qBittorrent-${QBITTORRENT_RELEASE} \
    && echo "Compiling qBittorrent..." \
    && cmake -G Ninja -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DGUI=OFF \
        -DCMAKE_CXX_STANDARD=17 \
    && cmake --build build --parallel $(nproc) \
    && cmake --install build \
    && cd /opt \
    && rm -rf /opt/* \
    && apt purge -y build-essential ca-certificates curl git jq libssl-dev pkg-config qtbase5-dev qttools5-dev zlib1g-dev \
    && apt-get clean \
    && apt --purge autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Install WireGuard and runtime dependencies
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
    libqt5xml5 \
    libqt5sql5 \
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
    unrar \
    p7zip-full \
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
