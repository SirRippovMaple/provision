#!/usr/bin/env bash
wget --no-verbose --output-document=/tmp/bw.zip 'https://vault.bitwarden.com/download/?app=cli&platform=linux'
unzip -o /tmp/bw.zip -d /tmp
install /tmp/bw /usr/bin
