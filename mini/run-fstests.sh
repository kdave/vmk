#!/bin/sh

echo 'RUN FSTESTS'
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

export TEST_DEV=/dev/vda
export TEST_DIR=/tmp/test
#export SCRATCH_DEV=/dev/vdb
unset SCRATCH_DEV
# 1234567
# bcdefgh
export SCRATCH_DEV_POOL=$(echo /dev/vd[b-g])
export LOGWRITES_DEV=/dev/vdh
export SCRATCH_MNT=/tmp/scratch
export FSTYP=btrfs
export MKFS_OPTIONS='-K -f'
export MOUNT_OPTIONS=''

FSTESTS=basic
GROUP=all
#CMD=$(grep "fstests=[^ ]*" < /proc/cmdline)
CMD=

echo "CMD: $CMD"

if ! [ -z "$CMD" ]; then
	V=${CMD#*=}
	if [ "$V" = 'full' ]; then
		FSTESTS=full
	fi
fi

echo "START FSTESTS: $FSTESTS group=$GROUP"

if [ "$FSTESTS" = 'basic' ]; then
	mkfs.btrfs $MKFS_OPTIONS "$TEST_DEV"
	./check -T -g "$GROUP"
elif [ "$FSTESTS" = 'full' ]; then

	echo "=== MARKER: defaults"
	export MKFS_OPTIONS='-K -f'
	export MOUNT_OPTIONS=''
	mkfs.btrfs $MKFS_OPTIONS "$TEST_DEV"
	./check -T -g "$GROUP"
	echo '=== MARKER: results'

	umount "$TEST_DEV" "$SCRATCH_MNT"

	echo "=== MARKER: mkfs no-hole, mount fst"
	export MKFS_OPTIONS='-K -f -O no-holes'
	export MOUNT_OPTIONS='-o space_cache=v2'
	mkfs.btrfs $MKFS_OPTIONS "$TEST_DEV"
	./check -T -g "$GROUP"
	echo '=== MARKER: results'
fi
