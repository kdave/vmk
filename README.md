VMK
===

A stupid-simple-standalone-shell frontend to KVM. Besides the common qemu-kvm
commandline wrapping, the vm images are stored as NOCOW files on BTRFS and use
reflinks for quick snapshots.

Status: it's usable but mostly documented "in the code"

Dependencies
------------

* btrfs to store vm images
* autoyast for installation
* zypper for installation into locally mounted vm images
* qemu-bridg-helper for networking
* qemu-kvm
* system utilities:
  * truncate, rm, rmdir, cp, mv, chattr, lsattr, telnet, grep, fusermount, dd, mkfs.fat, mount, umount, chown, chmod, stat, tee, date
  * qemu-img
  * mkisofs, isoinfo
  * guestmount

Features
--------

* supposedly easy access to virtual machines, mainly for testing purposes
  without the need of complicated and scattered configuration (though a
  system-wide or per-user configs are still possible)
* automatic installation via autoyast
* quick snapshot & run of default vm image
* serial console via telnet
* vnc access

License
-------

GNU GENERAL PUBLIC LICENSE Version 2.
