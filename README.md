# MT4 compiler
Docker image used to compile .mq4 files and check for errors

## Docker compose example

```docker-compose.yml
version: "3.9"
services:
  compiler:
    image: ghcr.io/d0whc3r/mt4-wine-compiler:master
    command: >
      bash -c "cp -r src/myfile.mq4 /home/wine/.mt4/drive_c/mt4/myfile.mq4
      && WINEPREFIX=/home/wine/.mt4 WINEARCH=win32 wine /home/wine/.mt4/drive_c/mt4/metaeditor.exe /compile:"C:\mt4\myfile.mq4" /include:"C:\mt4" /log; exit 0
      && cat /home/wine/.mt4/drive_c/mt4/myfile.log"
    volumes:
      - ./src:/home/wine/src
      - ./scripts:/home/wine/scripts

```
