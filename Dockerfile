FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get -yq install wget dos2unix sudo apt-utils && \
    apt-get -yq upgrade

RUN dpkg --add-architecture i386
RUN wget -nc https://dl.winehq.org/wine-builds/winehq.key -O /usr/share/keyrings/winehq-archive.key && \
    wget -nc https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources -O /etc/apt/sources.list.d/winehq-jammy.sources
RUN apt-get update && \
    apt-get -yq --install-recommends install winehq-devel

RUN apt-get clean && \
    rm -rf /var/cache/apt/archives /var/lib/apt/lists/*

RUN groupadd -g 1001 wine && \
    useradd -g wine -u 1001 wine && \
    usermod -aG sudo wine && \
    mkdir -p /home/wine && \
    chown -R wine:wine /home/wine && \
    echo "wine ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER wine
WORKDIR /home/wine/
RUN wget "https://download.mql5.com/cdn/web/oanda.corporation/mt4/oanda4setup.exe" -O ~/oanda4setup.exe && \
    WINEPREFIX=/home/wine/.mt4 WINEARCH=win32 winecfg -v=win10 && \
    WINEPREFIX=/home/wine/.mt4 WINEARCH=win32 wine /home/wine/oanda4setup.exe && \
    mkdir -p /home/wine/.mt4/drive_c/mt4 && \
    rm -rf /home/wine/oanda4setup.exe .cache .wget-hsts

COPY mt4/metaeditor.exe /home/wine/.mt4/drive_c/mt4/oanda4setup.exe
COPY mt4-zmq/Include /home/wine/.mt4/drive_c/mt4/Include
RUN sudo chown -R wine:wine /home/wine/.mt4/drive_c/mt4
