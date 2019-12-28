#!/bin/sh
cp ../FreeDOS_502MB_HDD.bin /tmp/freedos.img
dd if=../BIOS_Next186.bin of=/tmp/freedos.img bs=512 seek=1 conv=notrunc
