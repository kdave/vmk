#!/bin/sh

./root-mount || { echo "ERROR: no mount"; exit 1; }

echo "Copy fstests tar"
sudo cp fstests.tar.gz run-fstests.sh mnt
echo "Set fstests as autorun"
sudo ln -sf /run-fstests.sh mnt/autorun.sh

./root-umount
