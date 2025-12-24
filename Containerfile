ARG BASE_VERSION=15
FROM ghcr.io/daemonless/base:${BASE_VERSION}

# Disable Tautulli internal auto-updater (updates via container rebuild)
ENV TAUTULLI_DOCKER=True

ARG FREEBSD_ARCH=amd64
LABEL org.opencontainers.image.title="tautulli" \
      org.opencontainers.image.description="Tautulli Plex monitoring on FreeBSD" \
      org.opencontainers.image.source="https://github.com/daemonless/tautulli" \
      org.opencontainers.image.url="https://tautulli.com/" \
      org.opencontainers.image.documentation="https://github.com/Tautulli/Tautulli/wiki" \
      org.opencontainers.image.licenses="GPL-3.0-only" \
      org.opencontainers.image.vendor="daemonless" \
      org.opencontainers.image.authors="daemonless" \
      io.daemonless.port="8181" \
      io.daemonless.arch="${FREEBSD_ARCH}"

# Install dependencies (py311-setuptools provides pkg_resources for bundled apscheduler)
# (pkg repos are already configured in base image)
RUN pkg update && \
    pkg install -y \
        python311 \
        py311-pip \
        py311-setuptools \
        py311-sqlite3 \
        git-lite \
        ca_root_nss && \
    pkg clean -ay && \
    rm -rf /var/cache/pkg/* /var/db/pkg/repos/*

# Download and install Tautulli
RUN mkdir -p /app/tautulli && \
    chmod 755 /app && \
    TAUTULLI_VERSION=$(fetch -qo - "https://api.github.com/repos/Tautulli/Tautulli/releases/latest" | \
        grep -o '"tag_name":"[^"]*"' | sed 's/"tag_name":"//;s/"//') && \
    echo "Downloading Tautulli ${TAUTULLI_VERSION}" && \
    fetch -qo - "https://github.com/Tautulli/Tautulli/archive/refs/tags/${TAUTULLI_VERSION}.tar.gz" | \
        tar xzf - -C /app/tautulli --strip-components=1 && \
    chmod -R o+rX /app/tautulli && \
    echo "$TAUTULLI_VERSION" > /app/version

# Create config directory
RUN mkdir -p /config && \
    chown -R bsd:bsd /app/tautulli /config

# Copy service definition and init scripts
COPY root/ /

# Make scripts executable
RUN chmod +x /healthz /etc/services.d/tautulli/run /etc/cont-init.d/* 2>/dev/null || true

# Set up s6 service link

EXPOSE 8181
VOLUME /config


