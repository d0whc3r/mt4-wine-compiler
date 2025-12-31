FROM --platform=linux/amd64 ubuntu:noble

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and Wine
# We use a single RUN instruction to reduce layers and clean up in the same step
RUN dpkg --add-architecture i386 && \
    mkdir -pm755 /etc/apt/keyrings && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    gnupg \
    xvfb \
    winbind \
    cabextract && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources && \
    apt-get update && \
    apt-get install -y --install-recommends winehq-stable && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create wine user
RUN groupadd -g 1001 wine && \
    useradd -g wine -u 1001 -m -s /bin/bash wine && \
    mkdir -p /home/wine/.mt4/drive_c/mt4 && \
    chown -R wine:wine /home/wine

USER wine
WORKDIR /home/wine

# Initialize Wine prefix
ENV WINEPREFIX=/home/wine/.mt4
ENV WINEARCH=win32
ENV WINEDLLOVERRIDES="mscoree,mshtml="

# Run winecfg to initialize the prefix (headless)
RUN xvfb-run -a winecfg -v=win10 && \
    wineserver -w

# Copy MT4 files
# We assume the context has the 'mt4' directory with metaeditor.exe and sdk
COPY --chown=wine:wine mt4/metaeditor.exe /home/wine/.mt4/drive_c/mt4/metaeditor.exe
COPY --chown=wine:wine mt4/sdk/4.0_build-1443/Include    /home/wine/.mt4/drive_c/mt4/Include
COPY --chown=wine:wine mt4/sdk/4.0_build-1443/Indicators /home/wine/.mt4/drive_c/mt4/Indicators
COPY --chown=wine:wine mt4/sdk/4.0_build-1443/Libraries  /home/wine/.mt4/drive_c/mt4/Libraries

# Copy entrypoint script
COPY --chown=wine:wine entrypoint.sh /home/wine/entrypoint.sh
RUN chmod +x /home/wine/entrypoint.sh

ENTRYPOINT ["/home/wine/entrypoint.sh"]
