#!/usr/bin/env sh

if command -v mkfs.msdos ; then
    mkfs.msdos -n $1 $2
elif command -v newfs_msdos ; then
    newfs_msdos -L $1 $2
else
    echo "Missing either mkfs.msdos or new_fs_msdos"
    exit 1
fi
