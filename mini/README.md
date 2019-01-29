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
