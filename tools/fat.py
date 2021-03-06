# TODO: support other drive sizes
# TODO: support different cluster sizes
# TODO: support FAT16
# TODO: don't list root as file

from collections import namedtuple
import struct


INVALID_IMAGE = 'WARNING: Not a valid FAT formatted disk image!'


_BIOSParameterBlock = namedtuple('_BIOSParameterBlock', [
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


class BIOSParameterBlock(_BIOSParameterBlock):

    def __new__(cls, blob):
        fields = struct.unpack_from('<3s8sHBHBHHBHHHIIBBBI11s8s', blob)
        bpb = super().__new__(cls, *fields)

        if (bpb.signature != 40 and bpb.signature != 41) or bpb.jump != b'\xeb<\x90':
            # TODO: this should probably crash
            print(INVALID_IMAGE)

        return bpb


class FAT:

    def __init__(self, blob):
        self.blob = blob

    def __getitem__(self, n):
        i = int((3 * (n)) / 2)

        if n % 2 == 0:
            low = self.blob[i]
            high = int(self.blob[i + 1] & 0xf) << 8
        else:
            low = self.blob[i] >> 4
            high = int(self.blob[i + 1]) << 4

        return low + high


_DirectoryEntry = namedtuple('_DirectoryEntry', [
    'filename',
    'extension',
    'attributes',
    'reserved',
    'creation_time',
    'creation_date',
    'last_access_date',
    'last_write_time',
    'last_write_date',
    'first_logical_cluster',
    'file_size',
])


class DirectoryEntry(_DirectoryEntry):

    def __new__(cls, blob):
        fields = struct.unpack_from('<8s3sBHHHHxxHHHI', blob)
        return super().__new__(cls, *fields)

    def format(self):
        name = self.filename.decode('UTF-8').strip()
        extension = self.extension.decode('UTF-8').strip()

        if extension:
            return '.'.join([name, extension])
        else:
            return name

    def matches(self, filename):
        return filename == self.format()


class Directory:

    def __init__(self, blob):
        entries = []
        i = 0

        while i < len(blob):
            entry = DirectoryEntry(blob[i:i + 32])

            # If the first byte of the filename is \x00 the directory entry and
            # all following entries are empty
            if entry.filename.startswith(b'\x00'):
                break

            # Ignore anything created by a VFAT driver
            # TODO: properly handle all attribute values
            if entry.attributes != 15:
                entries.append(entry)

            i += 32

        self.entries = entries

    def get_entry(self, filename):
        for entry in self.entries:
            if entry.matches(filename):
                return entry

        raise FileNotFoundError

    def list(self):
        for entry in self.entries:
            print(entry.format())


class Disk:

    def __init__(self, image):
        with open(image, mode='rb') as f:
            self.blob = f.read()

    @property
    def _bpb(self):
        return BIOSParameterBlock(self.blob[0:512])

    @property
    def _fat(self):
        start = 512
        end = (self._bpb.sectors_per_fat + 1) * 512

        return FAT(self.blob[start:end])

    @property
    def _root_dir(self):
        # The root directory starts immediately after the FATs
        # The FATs start immediately after the single boot sector
        start = ((self._bpb.sectors_per_fat * self._bpb.fats) + 1) * 512
        # We can caluclate the end of the root directory by multiplying
        # the number of entries with the size of an entry and adding that
        # to start.
        end = start + (32 * self._bpb.directory_entries)

        return self.blob[start:end]

    def _logical_to_physical(self, cluster):
        # TODO: handle different fat sizes
        return 33 + cluster - 2

    def _get_physical_cluster(self, cluster):
        return self.blob[512*cluster:512 * (cluster + 1)]

    def _get_logical_cluster(self, cluster):
        return self._get_physical_cluster(self._logical_to_physical(cluster))

    def _get_cluster_list(self, cluster):
        clusters = [cluster]

        next_cluster = self._fat[cluster]

        # TODO: Handle these cases instead of just exiting
        if next_cluster == 0x00:
            pass
        elif next_cluster >= 0xF00 and next_cluster <= 0xFF6:
            pass
        elif next_cluster == 0xFF7:
            pass
        elif next_cluster >= 0xFF8 and next_cluster <= 0xFFF:
            pass
        else:
            clusters.extend(self._get_cluster_list(next_cluster))

        return clusters

    def _get_file_data(self, first_cluster, size, is_directory):
        logical_clusters = self._get_cluster_list(first_cluster)
        data = b''.join(
            [self._get_logical_cluster(cluster) for cluster in logical_clusters]
        )

        # TODO: Verify that ignoring the file size when dealing with a
        # directory is valid behavior. It appears that directories have
        # a file size of 0, but I can't find that referenced anywhere.
        if not is_directory:
            data = data[0:size]

        return data, [self._logical_to_physical(s) for s in logical_clusters]

    def get_info(self):
        return self._bpb

    def get_file(self, path):
        current = self._root_dir
        clusters = []

        for segment in [s for s in path.split('/') if s != '']:
            # TODO: Things that can go wrong:
            # - current might not be a directory
            entry = Directory(current).get_entry(segment)
            current, clusters = self._get_file_data(
                entry.first_logical_cluster,
                entry.file_size,
                # TODO: add an `is_directory` method instead of relying on
                # a magic number here.
                # (alsom add similar methods for other attributes)
                entry.attributes == 16,
            )

        return current, clusters

    def list(self, path):
        # TODO: better output information
        # TODO: this should probably return a list of directory entries
        target, _ = self.get_file(path)
        Directory(target).list()
