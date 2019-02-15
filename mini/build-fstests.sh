#!/bin/sh

# build fstests inside the VM
# expecting:
# - exported git tarball in /fstests.tar.gz
# - preinstalled all required packages (from packages-build-fstests)

echo 'BUILD FSTESTS'
set -eu

cd /tmp
tar xf ../fstests.tar.gz
cd fstests
if ! [ -f 'configure' ]; then
	autoreconf -fiv --include=m4
	libtoolize -i
	./configure
fi
make -j 4

mkdir -p /tmp/test /tmp/scratch

modprobe loop
modprobe btrfs

mount -o remount,rw /
id fsgqa || useradd fsgqa
getent group fsgqa || groupadd fsgqa
mkdir -p /home/fsgqa
mount -o remount,ro /

echo "Finished"
