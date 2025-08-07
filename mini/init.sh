#!/dumb-init /bin/bash

# Parameters read from /proc/cmdline
# net - start network and run ssh
# keepme - keep machine running after autorun ends

net=0
cgroups=0
keepmerunning=0
debugfs=false

echo "INIT: set up proc, dev, sys, tmp"
/usr/bin/mount -t proc none /proc
/usr/bin/mount -t sysfs none /sys
/usr/bin/mount -t tmpfs none /tmp
/usr/bin/mount -t tmpfs none /run
/usr/bin/mkdir -p /dev/pts
/usr/bin/mkdir -p /dev/mapper
/usr/bin/ln -s /proc/self/fd /dev/fd
/usr/bin/mount -t devpts none /dev/pts
$debugfs && /usr/bin/mount -t debugfs none /sys/kernel/debug
if [ "$cgroups" = 1 ]; then
	/usr/bin/mount -t cgroup none /sys/fs/cgroup
	/usr/bin/mount -t cgroup2 none /sys/fs/cgroup/unified
fi

if ! [ -d /share ]; then
	mount -o remount,rw /
	mkdir /share
	mount -o remount,ro /
fi

if grep -q 9p /proc/filesystems; then
	echo "INIT: mount shared direcoty /share"
	mount -t 9p virtshare /share
fi

ip a add 127.0.0.1/8 dev lo

export PS1='\u@\h:\w\$ '
export PATH=/bin:/sbin:/usr/bin/:/usr/sbin
export SHELL=/bin/bash
export LANG=en_US.UTF-8
mkdir /run/tmux
chmod 1777 /run/tmux
mkdir /run/tmux/0
chmod 600 /run/tmux/0

# Resize terminal magic
resize() {
	old=$(stty -g)
	stty -echo
	printf '\033[18t'
	IFS=';' read -d t _ rows cols _
	stty "$old"
	stty cols "$cols" rows "$rows"
}

resize

# 2nd serial console
#/dumb-init /sbin/agetty -a root ttyS1 linux &

if grep -w keepme /proc/cmdline; then
	keepmerunning=1
fi

if grep -w net /proc/cmdline; then
	net=1
fi

if [ "$net" = 1 ]; then
	echo "INIT: remount / read-write"
	mount -o remount,rw /
	echo "INIT: set up networking, ssh"
	/usr/bin/ifconfig eth0 up
	/sbin/dhclient eth0
	if ! /usr/sbin/sshd; then
		/usr/sbin/sshd-gen-keys-start
		/usr/sbin/sshd
	fi
	# Qemu user network:
	type -p route && route add default gw 10.0.2.2
fi

AUTORUN=$(grep -oP "(?<=autorun=)([^ ]*)" < /proc/cmdline || true)
if [ -z "$AUTORUN" ]; then
	if [ -f '/autorun.sh' ]; then
		AUTORUN="/autorun.sh"
	fi
fi
if [ -f "$AUTORUN" ]; then
	full=$(readlink -f "$AUTORUN")
	echo "INIT: autorun.sh ($full) found, starting in 3 seconds, press key to skip"
	x=
	for i in 2 1 0; do
		read -N 1 -t 1 x
		echo "... $i"
		[ "$x" != '' ] && break
	done
	if [ "$x" = '' ]; then
		if [ "$cgroups" = 1 ]; then
			echo "INIT: enable cgroups"
			mkdir -p /sys/fs/cgroup/foo
			echo $$ > /sys/fs/cgroup/foo/cgroup.procs
			echo +io +memory > /sys/fs/cgroup/foo/cgroup.contollers
		fi

		echo "INIT: start autorun"
		"$full"
		if [ "$keepmerunning" = 1 ]; then
			echo "INIT: autorun finished, back to shell"
			resize
			/bin/bash
		else
			echo "INIT: autorun finished, poweroff"
		fi
	else
		echo "INIT: autorun skipped, starting shell"
		resize
		/bin/bash
	fi
else
	echo "INIT: no autorun ($AUTORUN), starting shell"
	resize
	/bin/bash
fi

#killall agetty
#wait

echo s > /proc/sysrq-trigger
echo u > /proc/sysrq-trigger
echo o > /proc/sysrq-trigger
# Give it some time to avoid panic for killing init
sleep 10
