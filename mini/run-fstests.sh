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
FSTESTSCONFIGBASE=/

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

# pwd is now /tmp/fstests

if [ "$PHASE" = 'prep' -o "$PHASE" = 'all' ]; then
	mkdir -p /tmp/test /tmp/scratch

	modprobe loop
	modprobe btrfs

	mount -o remount,rw /
	id fsgqa || useradd fsgqa
	getent group fsgqa || groupadd fsgqa
	mkdir -p /home/fsgqa
	mount -o remount,ro / || true
fi

# preset name
# CMD has only one word $W, expected to be fstests.$W that is linked
# to /tmp/fstests/
CMD=$(grep -oP "(?<=fstests=)([^ ]*)" < /proc/cmdline || true)
PRESET=$CMD
PRESET=${PRESET:-default}
pfile="$FSTESTSCONFIGBASE/fstests.$PRESET"
if [ -f "$pfile" ]; then
	echo "FSTESTS: link preset $pfile to fstests"
	ln -sf "$pfile" local.config
fi

if [ "$PHASE" = 'config' -o "$PHASE" = 'all' ]; then
	if [ -f "local.config" ]; then
		echo "FSTESTS: source local.config (`readlink -f local.config`)"
		echo "===="
		# sectioned config not supported, can't find TEST_DEV/TEST_MNT
		# to precreate and it fails later
		source ./local.config
		cat ./local.config
		echo "===="
	else
		# fallback config
		echo "FSTESTS: using built-in config"
		export TEST_DEV=/dev/vda
		export TEST_DIR=/tmp/test
		unset SCRATCH_DEV
		export SCRATCH_DEV_POOL=$(echo /dev/vd[b-g])
		export LOGWRITES_DEV=/dev/vdh
		export SCRATCH_MNT=/tmp/scratch
		export FSTYP=btrfs
		export MKFS_OPTIONS='-K -f'
		export MOUNT_OPTIONS=''
	fi
fi

if [ "$PHASE" = 'run' -o "$PHASE" = 'all' ]; then
	echo "FSTESTS: mkfs test dev"
	mkfs.btrfs $MKFS_OPTIONS "$TEST_DEV"
	echo "START FSTESTS"
	./check -T -g all
fi
