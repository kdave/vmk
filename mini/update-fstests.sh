#!/bin/sh

# - copy local tarball of fstests into the VM root
# - copy the run script
# - set the run script for autorun

./root-mount || { echo "ERROR: no mount"; exit 1; }

echo "Copy fstests tar"
sudo cp fstests.tar.gz run-fstests.sh mnt
echo "Set fstests as autorun"
sudo ln -sf /run-fstests.sh mnt/autorun.sh

./root-umount
