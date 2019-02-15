#!/bin/sh

sudo /sbin/modprobe kvm-intel --allow-unsupported
sudo /sbin/modprobe tun
sudo chmod 666 /dev/kvm
