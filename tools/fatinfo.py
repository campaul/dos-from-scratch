#!/usr/bin/env python3
from collections import namedtuple
import struct
import sys


INVALID_IMAGE = 'Not a valid FAT formatted disk image!'
NO_IMAGE = 'Must specify a disk image!'


BIOSParameterBlock = namedtuple('BIOSParameterBlock', [
    'jump',
    'oem_identifier',
    'bytes_per_sector',
    'sectors_per_cluster',
    'reserved_sectors',
    'fats',
    'directory_entries',
    'total_sectors',
    'media_descriptor_type',
    'sectors_per_fat',
    'sectors_per_track',
    'heads',
    'hidden_sectors',
    'large_sector_count',
    'drive_number',
    'win_nt_flags',
    'signature',
    'volume_id',
    'volume_label',
    'system_identifier',
])


def main():
    if len(sys.argv) < 2:
        print(NO_IMAGE)
        sys.exit(1)

    image = sys.argv[1]

    with open(image, mode='rb') as f:
        data = f.read(512)

    try:
        bpb = BIOSParameterBlock(
            *struct.unpack_from('<3s8sHBHBHHBHHHIIBBBI11s8s',
            data,
        ))
    except:
        print(INVALID_IMAGE)
        sys.exit(2)

    if (bpb.signature != 40 and bpb.signature != 41) or bpb.jump != b'\xeb<\x90':
        print(INVALID_IMAGE)
        sys.exit(3)

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
