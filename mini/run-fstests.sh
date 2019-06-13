#!/bin/sh

# usage: $0 [phase | test]
# phase is one of:
# - build  - unpack and build
# - prep   - load module, create dirs, add users
# - config - set up environment
# - run    - run up to the tests
# - all    - all of the above in that order

echo "RUN FSTESTS (args: $@)"
set -eu
set -- "$@"

PHASE="${1:-all}"

cd /tmp

if [ "$PHASE" = 'build' -o "$PHASE" = 'all' ]; then
	tar xf ../fstests.tar.gz
	cd fstests
	if ! [ -f 'configure' ]; then
		autoreconf -fiv --include=m4
		libtoolize -i
		./configure
	fi
	make -j 4
fi

if [ "$PHASE" = 'prep' -o "$PHASE" = 'all' ]; then
	mkdir -p /tmp/test /tmp/scratch

	modprobe loop
	modprobe btrfs

	mount -o remount,rw /
	id fsgqa || useradd fsgqa
	getent group fsgqa || groupadd fsgqa
	mkdir -p /home/fsgqa
	mount -o remount,ro /
fi

if [ "$PHASE" = 'config' -o "$PHASE" = 'all' ]; then
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
	export MOUNT_OPTIONS='-o discard'
fi

FSTESTS=${FSTESTS:-basic}
GROUP=all
#CMD=$(grep "fstests=[^ ]*" < /proc/cmdline)
CMD=

if [ "$PHASE" = 'run' -o "$PHASE" = 'all' ]; then
	echo "CMD: $CMD, FSTESTS: $FSTESTS"

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
	else
		mkfs.btrfs $MKFS_OPTIONS "$TEST_DEV"
		./check -T $FSTESTS
	fi
fi
