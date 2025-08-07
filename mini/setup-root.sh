#!/bin/sh -x

if [ -f root ]; then
	echo "ERROR: already there, will not setup"
	exit 1
fi

touch root
chattr +Cm root
truncate -s 10G root
/sbin/mkfs.ext2 root

./root-mount || { echo "ERROR: no mount"; exit 1; }
sudo cp dumb-init mnt
if [ -f "zypp.conf" ]; then
	sudo mkdir -p mnt/etc/zypp
	sudo cp zypp.conf mnt/etc/zypp
	echo "Looks like you have manual zyp config, unpause"
	read pause
fi
# Keep it for the rest
#./root-umount

./update-init

for p in packages-*; do
	./install-list "$p"
	sync
done

./root-umount

echo "NOTE: add your testing files"
