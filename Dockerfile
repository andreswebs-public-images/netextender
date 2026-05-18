# syntax=docker/dockerfile:1
FROM docker.io/debian:trixie

ARG DEBIAN_FRONTEND="noninteractive"
ARG DEBCONF_NONINTERACTIVE_SEEN="true"

ARG NX_VERSION="10.3.5-36"
ARG S6_OVERLAY_VERSION="3.2.3.0"

RUN <<EOT
    set -o errexit
    apt-get update
    apt-get install --yes --no-install-recommends \
        bsdextrautils \
        ca-certificates \
        iproute2 \
        iptables \
        net-tools
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOT

RUN <<EOT
    set -o errexit

    apt-get update
    apt-get install --yes --no-install-recommends \
        curl \
        xz-utils

    DPKG_ARCH=$(dpkg --print-architecture)
    case "${DPKG_ARCH}" in
        amd64)  NX_ARCH="amd64"; S6_ARCH="x86_64" ;;
        arm64)  NX_ARCH="arm64"; S6_ARCH="aarch64" ;;
        *)      echo "unsupported arch: ${DPKG_ARCH}" >&2; exit 1 ;;
    esac

    DOWNLOAD_DIR=$(mktemp -d)

    curl \
        --fail \
        --silent \
        --location \
        --output "${DOWNLOAD_DIR}/netextender.deb" \
        "https://software.sonicwall.com/NetExtender/NetExtender-linux-${NX_ARCH}-${NX_VERSION}.deb"
    dpkg --install "${DOWNLOAD_DIR}/netextender.deb"

    curl \
        --fail \
        --silent \
        --location \
        --output "${DOWNLOAD_DIR}/s6-overlay-noarch.tar.xz" \
        "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz"
    curl \
        --fail \
        --silent \
        --location \
        --output "${DOWNLOAD_DIR}/s6-overlay-bin.tar.xz" \
        "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz"
    tar --directory / --extract --xz --preserve-permissions --file "${DOWNLOAD_DIR}/s6-overlay-noarch.tar.xz"
    tar --directory / --extract --xz --preserve-permissions --file "${DOWNLOAD_DIR}/s6-overlay-bin.tar.xz"

    rm -rf "${DOWNLOAD_DIR}"

    apt-get purge --yes --autoremove curl xz-utils
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOT

RUN echo pppoe > /etc/modules

COPY rootfs/ /

RUN <<EOT
    set -o errexit
    chmod 0755 \
        /etc/s6-overlay/scripts/nx-connect \
        /etc/s6-overlay/s6-rc.d/neservice/run \
        /etc/s6-overlay/s6-rc.d/neservice/finish
EOT

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_KEEP_ENV=1
ENV VPN_ALWAYS_TRUST=1

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD script --quiet --return --command "nxcli status" /dev/null | grep --fixed-strings --quiet "NetExtender has been connected"

ENTRYPOINT ["/init"]
