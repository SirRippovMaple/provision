#!/usr/bin/env /bin/bash
cat progs.csv|grep -v '^#'|cut -f2 -d,|sort > /tmp/progs.txt
pacman -Qet|cut -f1 -d" "|sort > /tmp/pacman.txt
comm -23 /tmp/pacman.txt /tmp/progs.txt
