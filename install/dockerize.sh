#!/bin/bash
set -eo pipefail

DOCKERIZE_VERSION=v0.9.6

ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        DOCKERIZE_ARCH=amd64
        CHECKSUM="82b1159e8faa1b30b80d238bac91894ddd20b5e07543911cf5a3d400e17fa214"
        ;;
    aarch64)
        DOCKERIZE_ARCH=arm64
        CHECKSUM="857456036b139a27152230f28751977ee7e39f22b6a2b1c447319adb616c1aa0"
        ;;
    armv7l)
        DOCKERIZE_ARCH=armhf
        CHECKSUM="966f6b7042ba79bd5b22b74ed946d39362f4996a022f207e1fd10be276d1b3f6"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

URL="https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-linux-${DOCKERIZE_ARCH}-${DOCKERIZE_VERSION}.tar.gz"

echo "Downloading dockerize from $URL"
curl -sSL -o dockerize.tar.gz "$URL"

# Verify checksum
echo "${CHECKSUM}  dockerize.tar.gz" | sha256sum -c -

# Install
tar -C /usr/local/bin -xzf dockerize.tar.gz
rm dockerize.tar.gz