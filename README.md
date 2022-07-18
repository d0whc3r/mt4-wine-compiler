# MT4 compiler
Docker image used to compile .mq4 files and check for errors

## Docker compose example

```docker-compose.yml
version: "3.9"
services:
  compiler:
    image: ghcr.io/d0whc3r/mt4-wine-compiler:master
    command:
      - cp -r src/copier/copier.mq4 /home/wine/.mt4/drive_c/mt4/copier.mq4
      - cp -r src/operator/operator.mq4 /home/wine/.mt4/drive_c/mt4/operator.mq4
      - bash scripts/compile-mq4.sh
      - bash scripts/check-mq4-logs.sh
    volumes:
      - ./src:/home/wine/src
      - ./scripts:/home/wine/scripts
```

## Compile command

```bash
WINEPREFIX=/home/wine/.mt4 WINEARCH=win32 wine /home/wine/.mt4/drive_c/mt4/metaeditor.exe /compile:"C:\mt4\myfile.mq4" /include:"C:\mt4" /log
```
