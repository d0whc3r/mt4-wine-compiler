FROM ubuntu:jammy

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -yq upgrade && apt-get -yq install wget dos2unix sudo
RUN dpkg --add-architecture i386
RUN wget -nc https://dl.winehq.org/wine-builds/winehq.key -O /usr/share/keyrings/winehq-archive.key && \
    wget -nc https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources -O /etc/apt/sources.list.d/winehq-jammy.sources
RUN apt-get update && apt-get -yq --install-recommends install winehq-devel

RUN groupadd -g 1001 wine \
	&& useradd -g wine -u 1001 wine \
	&& mkdir -p /home/wine/.wine && chown -R wine:wine /home/wine \

RUN usermod -aG sudo wine

USER wine
WORKDIR /home/wine/

RUN wget "https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4oldsetup.exe" -O ~/mt4setup.exe
RUN WINEPREFIX=/home/wine/.mt4 WINEARCH=win32 winecfg -v=win10
RUN WINEPREFIX=/home/wine/.mt4 WINEARCH=win32 wine /home/wine/mt4setup.exe
RUN mkdir -p /home/wine/.mt4/drive_c/mt4

COPY mt4/metaeditor.exe /home/wine/.mt4/drive_c/mt4/metaeditor.exe
COPY mt4-zmq/Include /home/wine/.mt4/drive_c/mt4/Include
