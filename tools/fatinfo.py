#!/usr/bin/env python3
from collections import namedtuple
import sys

from fat import Disk


NO_IMAGE = 'Must specify a disk image!'


def main():
    if len(sys.argv) < 2:
        print(NO_IMAGE)
        sys.exit(1)

    image = sys.argv[1]

    bpb = Disk(image).get_info()

    print('\nOEM Identifier:', bpb.oem_identifier.decode('ascii').strip())
    print('Bytes per Sector:', bpb.bytes_per_sector)
    print('Sectors per Cluster:', bpb.sectors_per_cluster)
    print('FATs:', bpb.fats)
    print('Directory Entries:', bpb.directory_entries)
    print('Total Sectors:', bpb.total_sectors)
    print('Media Descriptor Type:', bpb.media_descriptor_type)
    print('Sectors per FAT:', bpb.sectors_per_fat)
    print('Sectors per Track:', bpb.sectors_per_track)
    print('Heads:', bpb.heads)
    print('Signature:', bpb.signature)
    print('Volume Label:', bpb.volume_label.decode('ascii').strip())
    print('FAT Type:', bpb.system_identifier.decode('ascii').strip(), '\n')


if __name__ == '__main__':
    main()
