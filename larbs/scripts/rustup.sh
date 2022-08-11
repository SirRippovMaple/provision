#!/usr/bin/env /bin/bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sudo -u "$2" sh -s -- -y
