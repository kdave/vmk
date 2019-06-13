QEMU executor for locally built kernels and smallish VMs
--------------------------------------------------------

Starring:

* `dumb-init` as pid 1 process manager
* `init.sh` as the service manager
* `bash` as the shell
* `bzImage` as the kernel without his initrd companion

Device configuration (WIP):

QEMU block device interfaces:

* IDE
* SCSI
* virtio
  * `CONFIG_VIRTIO_BLK`
  * `CONFIG_SCSI_VIRTIO`

overall
  * `CONFIG_VIRTIO`
  * hwrng -- `CONFIG_HW_RANDOM_VIRTIO`

networking
* virtio
  * `CONFIG_VIRTIO_NET`


Dependencies
------------

* qemu (KVM)
* dumb-init: built with static version of libc
* e2fsprogs (mkfs root)
* script, telnet


Minimal VM template
-------------------

Base:

- root (set up by setup-root.sh)
- dumb-init
- init.sh, update-init
- root-mount, root-umount
- runme, runme-config
- serial-start, waittelnet
- update-kernel
- update-root-dist

Optional:

- fstests.tar.gz (symlink), run-fstests.sh, update-fstests.sh

Package management:

- install-pkg, install-list, install-sh

Autorun:

- reset-autorun
- update-autorun.sh


Workflow
--------

The VM is set up, installed. Check that runme-config has the path to linux.git,
otherwise you can specify it as an argument.

- cd linux.git
- make olconfig && make
- cd vm
- ./update-kernel
- ./runme

Without autorun, this will end with shell. Otherwise script /autorun.sh will
start in 3 seconds, press any key to stop it and got back to shell.


Other
-----

Configuration:

* IDE provides only 4 devices
* SCSI is unstable and the driver crashes under heavy load
* VIRTIO works best it seems
