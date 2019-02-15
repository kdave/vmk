#!/bin/sh -x -e

if [ -f root ]; then
	echo "ERROR: already there, will not setup"
	exit 1
fi

truncate -s 10G root
/sbin/mkfs.ext2 root

for p in packages-*; do
	./install-list "$p"
done

./root-mount || { echo "ERROR: no mount"; exit 1; }
sudo cp dumb-init mnt
./root-umount

./update-init

echo "NOTE: add your testing files"
