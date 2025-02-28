#!/bin/sh

# Usage: $0 [phase | test]
# phase is one of:
# - build  - unpack and build
# - prep   - load module, create dirs, add users
# - config - set up environment
# - run    - run up to the tests
# - all    - all of the above in that order
#
# Configure via kerne command line:
# - fstests=PRESET - pick builtin preset features (bgt, rst, quota, squota, compress)
# - runtest=btrfs/001 - run this test, once (default)
# - runtest=once:btrfs/001 - run this test, explicitly once
# - runtest=btrfs/001,btrfs/002 - list of tests
# - runtets=loop:btrfs/011 - loop all the tests
#
# Excludes:
# - EXCLUDE.version - automatically pick excludes from the main version (6.12)
# - EXCLUDE.vm - current VM environment workarounds

echo "RUN FSTESTS (args: $@)"
set -eu
set -- "$@"

PHASE="${1:-all}"
FSTESTSCONFIGBASE=/
VERSION=$(uname -r | sed -e 's/^\([0-9]\.[0-9]\+\)\..*/\1/')

cd /tmp

if [ "$PHASE" = 'build' -o "$PHASE" = 'all' ]; then
	tar xf ../fstests.tar.gz
	cd fstests
	if ! [ -f 'configure' ]; then
		autoreconf -fiv --include=m4
		./configure
	fi
	make -j 4
fi

# Show the devices
lsblk

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
else
	echo "FSTESTS: internal preset $PRESET"
fi

# run only specific test
CMD=$(grep -oP "(?<=runtest=)([^ ]*)" < /proc/cmdline || true)
TESTS='-g all'
TIMES=once
if ! [ -z "$CMD" ]; then
	key=${CMD%:*}
	value=${CMD#*:}
	case "$key" in
	once) TIMES=once;;
	loop) TIMES=loop;;
	*)    TIMES=once;;
	esac
	declare -a TMPTESTS
	OIFS="$IFS"
	IFS=, TMPTESTS=( $value )
	IFS="$OIFS"
	if ! [ -z "$TMPTESTS" ]; then
		TESTS="${TMPTESTS[@]}"
	fi

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
		#export SCRATCH_DEV_POOL=$(echo /dev/vd[b-i])
		export SCRATCH_DEV_POOL='/dev/vdb /dev/vdc /dev/vdd /dev/vde /dev/vdf /dev/vdg /dev/vdh /dev/vdi'
		export LOGWRITES_DEV=/dev/vdi
		export SCRATCH_MNT=/tmp/scratch
		#export FSTYP=xfs
		export FSTYP=btrfs
		export MKFS_OPTIONS='-K -f'
		export MOUNT_OPTIONS=''

		case "$PRESET" in
			bgt)
				MKFS_OPTIONS="$MKFS_OPTIONS -O bgt";;
			rst)
				MKFS_OPTIONS="$MKFS_OPTIONS -O rst";;
			quota)
				MKFS_OPTIONS="$MKFS_OPTIONS -O quota";;
			squota)
				MKFS_OPTIONS="$MKFS_OPTIONS -O squota";;
			compress)
				MOUNT_OPTIONS="$MOUNT_OPTIONS -o compress";;
			compress-lzo)
				MOUNT_OPTIONS="$MOUNT_OPTIONS -o compress=lzo";;
			compress-zstd)
				MOUNT_OPTIONS="$MOUNT_OPTIONS -o compress=zstd";;
			*) :;;
		esac
	fi
fi

export USE_KMEMLEAK=yes
export DIFF_LENGTH=0
EXCLUDE=
VMEXCLUDE=

if [ -f "EXCLUDE.${VERSION}" ]; then
	EXCLUDE="-E EXCLUDE.${VERSION}"
fi

# VM specific exclude list
if [ -f "/EXCDLUDE.vm" ]; then
	VMEXCLUDE="-E /EXCLUDE.vm"
fi

mkdir -p "$TEST_DIR" "$SCRATCH_MNT"

if [ "$PHASE" = 'run' -o "$PHASE" = 'all' ]; then
	echo "Use exclude: $EXCLUDE $VMEXCLUDE"
	echo "FSTESTS: mkfs test dev"
	mkfs.$FSTYP $MKFS_OPTIONS "$TEST_DEV"
	echo "START FSTESTS: $TIMES: $TESTS"
	while :; do
		# brief summary, timestamps
		./check -b -T $EXCLUDE $VMEXCLUDE $TESTS
		if ! [ "$TIMES" = "loop" ]; then
			break
		fi
		echo "LOOP FSTESTS"
	done
fi

mount -o remount,rw /
echo "RESULTS: save to /results.tar.gz"
tar czf /results.tar.gz /tmp/fstests/results
