#!/usr/bin/env bash
wget -o /tmp/bw.zip 'https://vault.bitwarden.com/download/?app=cli&platform=linux'
unzip /tmp/bw.zip -d /tmp
install /tmp/bw /usr/bin
