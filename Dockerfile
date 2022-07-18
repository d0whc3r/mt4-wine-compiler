FROM ubuntu:jammy

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -yq upgrade && apt-get -yq install wget dos2unix
RUN dpkg --add-architecture i386
RUN wget -nc https://dl.winehq.org/wine-builds/winehq.key -O /usr/share/keyrings/winehq-archive.key && \
    wget -nc https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources -O /etc/apt/sources.list.d/winehq-jammy.sources
RUN apt-get update && apt-get -yq --install-recommends install winehq-devel

# Add wine user.
# NOTE: You might need to change the UID/GID so the
# wine user has write access to your MetaTrader
# directory at $METATRADER_HOST_PATH.
RUN groupadd -g 1001 wine \
	&& useradd -g wine -u 1001 wine \
	&& mkdir -p /home/wine/.wine && chown -R wine:wine /home/wine

# Run MetaTrader as non privileged user.
USER wine
WORKDIR /home/wine/

RUN wget "https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4oldsetup.exe" -O ~/mt4setup.exe
RUN WINEPREFIX=~/.mt4 WINEARCH=win32 winecfg -v=win10
RUN WINEPREFIX=~/.mt4 WINEARCH=win32 wine ~/mt4setup.exe
RUN mkdir -p ~/.mt4/drive_c/mt4

COPY mt4/metaeditor.exe ~/.mt4/drive_c/mt4/metaeditor.exe
COPY mt4-zmq/Include ~/.mt4/drive_c/mt4/Include

#COPY src/copier/copier.mq4 ./.mt4/drive_c/mt4/copier.mq4
#COPY src/operator/operator.mq4 ./.mt4/drive_c/mt4/operator.mq4

#RUN WINEPREFIX=~/.mt4 WINEARCH=win32 wine ./.mt4/drive_c/mt4metaeditor.exe /compile:"C:\mt4\copier.mq4" /include:"C:\mt4" /log; exit 0
#RUN WINEPREFIX=~/.mt4 WINEARCH=win32 wine ./.mt4/drive_c/mt4metaeditor.exe /compile:"C:\mt4\operator.mq4" /include:"C:\mt4" /log; exit 0
#RUN dos2unix ./mt4/*.log
## Check errors in copier
#RUN ERROR_COPIER=$(cat ./mt4/copier.log | grep -i "0 error") && \
#    ERROR_OPERATOR=$(cat ./mt4/operator.log | grep -i "0 error") && \
#    if [ "$ERROR_COPIER" = "" ] || [ "$ERROR_OPERATOR" = "" ]; then echo "Errors in copier or operator"; exit 1; fi
