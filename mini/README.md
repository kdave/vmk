QEMU executor for locally built kernels and smallish VMs
--------------------------------------------------------

Starring:

* `dumb-init` as pid 1 process manager
* `init.sh` as the service manager
* `bash` as the shell

Device configuration (WIP):

qemu block device interfaces:

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

* qemu
* dumb-init: static version of libc
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


TODO
----

* cache RPMs from the VM after installation

