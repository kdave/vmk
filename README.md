VMK
===

A stupid-simple-standalone-shell frontend to KVM. Besides the common qemu-kvm
commandline wrapping, the vm images are stored as NOCOW files on BTRFS and use
reflinks for quick snapshots.

*Status: it's usable but mostly documented "in the code" and there are still
some hardcoded assumptions that will be eliminated eventually*

Dependencies
------------

* btrfs to store vm images
* autoyast for installation
* zypper for installation into locally mounted vm images
* qemu-bridge-helper for networking
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

Quick start
-----------

Generate minimal config by `vmk newconfig > vm-config` and edit manually.

* `VMK_NAME=name` - an identifier, passed (kvm: `-name`)
* `VMK_VNC=1` - number of the vnc port, also used to derive MAC, IP and hostname (kvm: `-vnc`)
* `VMK_MEM=1024` - memory size of the vm (kvm: `-m`)
* `VMK_CPU=2` - number of cpus (kvm: `-smp`)
* `VMK_DISK0=name.qcow2` - first disk image (kvm: scsi, cache=safe)
* `VMK_ISO=install.iso` - an .iso image to install from (kvm: ide cdrom)

Now run `vmk qinstall`. This will create the disk image and start booting from
the iso image. Proceed with manual installation.

Alternatively, you can provide an autoyast config which will perform the
installation without human intervention. (TODO: sample configs) Use `vmk
ayinstall` for that.

Depending on the configuration, you should be able to reach the vm via ssh. You can
generate a ssh key pair for this particular machine. Stop it first, then run
`vmk sshkeygen` to generate the pair and then `vmk sshkeyput`. This will locally mount
the first disk image (using `libguestfs') and copy the public key to `/root/.ssh/authorized_keys`.

Access though the serial console requires configuration from inside the vm. The
installation process configures the serial console and the settings are
inherited by the vm.  The actual setting for bootloader is `console=tty0
console=ttyS0,115200`, should you need to configure it that manually.

Basic commands to manage the vm:

* `run` - start on the background
* `runin` - start in the foreground, beware that Ctrl-C will kill the machine
* `info` - print the info (config), good for checking if the vm is running
* `kill` - forcibly kill based on matching process name

Start the vm on a snapshot of the first disk image (file copy, good for scratch testing):

* `snap run` - same as `run`, using file `snap-$VMK_DISK0`
* `snap runin` - same as `runin`, using file `snap-$VMK_DISK0`

Commands to manage the disk images:

* `dsnap` - create a snapshot of the first image (by reflink), a timestamp is appended
* `cpfile` - do a reflink copy of a file, preserving attributes
* `mount` - mount the first image to `mnt-disk0`
* `umount` - umount the first image from `mnt-disk0`

See `vmk help` for the rest.

VM image management
-------------------

No central image store and management. There are some supporting commands but
it's up to you where do you store the images and how do you use them.

`vmk clone -o outputdir -n vmdirname` will copy the *vm-config* and the first
disk image into directory `outputid/vmdirname`. If you need to copy the files
individually, use `vmk cpfile srcfile destfile` (note that the command really
works on files and is not a *cp* replacement).

As an example, let's assume we have a base image with some setup and config and
want to clone it for further testing. The current directory contains the base image:

`vmk clone -o .. -n test-something`

Then go to `../test-something` and edit the *vm-config* to tune the parameters.
Some basic scripting support exists, `vmk set` but so far is very limited. Only
`vnc` and `mem` are implemented.

Automatic installation
----------------------

The directory `autoinst` contains various autoyast xml files that can be used
to run automatic installation, either with some preset defaults or completely
unattended.

* `autoinst/snippets/` -- subdirectories by subsystem, named after respective autoyast xml sections

References
----------

* [Autoyast documentation (applies to recent openSUSE and SLES)](https://www.suse.com/documentation/sles-12/singlehtml/book_autoyast/book_autoyast.html)

License
-------

[GNU GENERAL PUBLIC LICENSE Version 2.](https://www.gnu.org/licenses/gpl-2.0.html)
