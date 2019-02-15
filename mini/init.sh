#!/dumb-init /bin/bash

net=0

echo "INIT: set up proc, dev, sys, tmp"
/usr/bin/mount -t proc none /proc
/usr/bin/mount -t sysfs none /sys
/usr/bin/mount -t tmpfs none /tmp
/usr/bin/mkdir -p /dev/pts
/usr/bin/mkdir -p /dev/mapper
/usr/bin/ln -s /proc/self/fd /dev/fd
/usr/bin/mount -t devpts none /dev/pts
/usr/bin/mount -t debugfs none /sys/kernel/debug

export PS1='\u@\h:\w\$ '
export PATH=/bin:/sbin:/usr/bin/:/usr/sbin
export SHELL=/bin/bash

# 2nd serial console
#/dumb-init /sbin/agetty -a root ttyS1 linux &

if [ "$net" = 1 ]; then
	echo "INIT: set up networking, ssh"
	/usr/bin/ifconfig eth0 up
	/sbin/dhclient eth0
	/usr/sbin/sshd -p 22
fi

if [ -f '/autorun.sh' ]; then
	full=$(readlink -f /autorun.sh)
	echo "INIT: autorun.sh ($full) found, starting in 3 seconds, press key to skip"
	x=
	for i in 2 1 0; do
		read -N 1 -t 1 x
		echo "... $i"
		[ "$x" != '' ] && break
	done
	if [ "$x" = '' ]; then
		echo "INIT: start autorun"
		/autorun.sh
		echo "INIT: autorun finished, back to shell"
	else
		echo "INIT: autorun skipped"
	fi
fi

echo "Init shell, exec /bin/bash"
/bin/bash

#killall agetty
#wait

echo s > /proc/sysrq-trigger
echo u > /proc/sysrq-trigger
echo o > /proc/sysrq-trigger
