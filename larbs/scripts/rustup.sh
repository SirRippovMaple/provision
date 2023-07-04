#!/usr/bin/env /bin/bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sudo --login --user "$2" sh -s -- -y
