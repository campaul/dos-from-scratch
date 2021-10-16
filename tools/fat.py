from collections import namedtuple
import struct


INVALID_IMAGE = 'WARNING: Not a valid FAT formatted disk image!'
DIRECTORY_SIZE = 32
SECTOR_SIZE = 512


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

        # TODO: find better way of testing for valid bpb
        if (bpb.signature != 40 and bpb.signature != 41) or bpb.jump != b'\xeb<\x90':
            # TODO: this should probably crash
            print(INVALID_IMAGE)

        return bpb


class FAT:

    def __init__(self, blob, fat_type):
        self.blob = blob
        self.fat_type = fat_type.decode("ascii").strip()

    def is_unused(self, cluster):
        return cluster == 0

    def is_reserved(self, cluster):
        if self.fat_type == "FAT12":
            min = 0xF00
            max = 0xFF6
        elif self.fat_type == "FAT16":
            min = 0xFF00
            max = 0xFFF6

        return cluster >= min and cluster <= max

    def is_bad(self, cluster):
        if self.fat_type == "FAT12":
            bad = 0xFF7
        elif self.fat_type == "FAT16":
            bad = 0xFFF7

        return cluster == bad

    def is_final(self, cluster):
        if self.fat_type == "FAT12":
            min = 0xFF8
            max = 0xFFF
        elif self.fat_type == "FAT16":
            min = 0xFFF8
            max = 0xFFFF

        return cluster >= min and cluster <= max

    def __getitem__(self, n):
        if self.fat_type == "FAT12":
            i = int((3 * (n)) / 2)

            if n % 2 == 0:
                low = self.blob[i]
                high = int(self.blob[i + 1] & 0xf) << 8
            else:
                low = self.blob[i] >> 4
                high = int(self.blob[i + 1]) << 4

            next_cluster = low + high

        elif self.fat_type == "FAT16":
            i = n * 2

            low = self.blob[i]
            high = self.blob[i + 1] << 8

            next_cluster = low + high
        else:
            raise Exception

        # TODO: Handle these cases instead of just returning None
        if self.is_unused(next_cluster):
            next_cluster = None
        elif self.is_reserved(next_cluster):
            next_cluster = None
        elif self.is_bad(next_cluster):
            next_cluster = None
        elif self.is_final(next_cluster):
            next_cluster = None

        return next_cluster


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
            entry = DirectoryEntry(blob[i:i + DIRECTORY_SIZE])

            # If the first byte of the filename is \x00 the directory entry and
            # all following entries are empty
            if entry.filename.startswith(b'\x00'):
                break

            # Ignore anything created by a VFAT driver
            # TODO: properly handle all attribute values
            if entry.attributes != 15:
                entries.append(entry)

            i += DIRECTORY_SIZE

        self.entries = entries

    def get_entry(self, filename):
        for entry in self.entries:
            if entry.matches(filename):
                return entry

        raise FileNotFoundError

    def list(self):
        for entry in self.entries:
            if entry.first_logical_cluster:
                print(entry.format())


_PartitionEntry = namedtuple('_PartitionEntry', [
    'status',
    'chs_partition_start',
    'partition_type',
    'chs_partition_end',
    'lba_partition_start',
    'number_of_sectors',
])


class PartitionEntry(_PartitionEntry):

    def __new__(cls, blob):
        fields = struct.unpack_from('<c3sc3sII', blob)
        return super().__new__(cls, *fields)


class Disk:

    def __init__(self, image):
        with open(image, mode='rb') as f:
            self.blob = f.read()

    def get_volume(self, volume):
        if volume == 0:
            assert self.blob[0:3] == b'\xeb<\x90'
            return Volume(self.blob)
        else:
            index = volume - 1
            partition_entry_start = 446 + index * 16
            partition_entry_end = partition_entry_start + 16
            partition_entry = PartitionEntry(self.blob[partition_entry_start:partition_entry_end])

            start = partition_entry.lba_partition_start * SECTOR_SIZE
            end = start + partition_entry.number_of_sectors * SECTOR_SIZE

            return Volume(self.blob[start:end])


class Volume:

    def __init__(self, blob):
        self.blob = blob

    @property
    def _bpb(self):
        return BIOSParameterBlock(self.blob[0:SECTOR_SIZE])

    @property
    def _fat(self):
        start = SECTOR_SIZE
        end = (self._bpb.sectors_per_fat + 1) * SECTOR_SIZE

        return FAT(self.blob[start:end], self._bpb.system_identifier)

    @property
    def _root_dir(self):
        # The root directory starts immediately after the FATs
        # The FATs start immediately after the single boot sector
        start = ((self._bpb.sectors_per_fat * self._bpb.fats) + 1) * SECTOR_SIZE
        # We can caluclate the end of the root directory by multiplying
        # the number of entries with the size of an entry and adding that
        # to start.
        end = start + (DIRECTORY_SIZE * self._bpb.directory_entries)

        return self.blob[start:end]

    def _logical_cluster_to_physical_sector(self, cluster):
        fat_size = self._bpb.sectors_per_fat * self._bpb.fats
        root_dir_size = int(self._bpb.directory_entries * DIRECTORY_SIZE / SECTOR_SIZE)
        data_start = fat_size + root_dir_size + 1
        return data_start + (cluster * self._bpb.sectors_per_cluster) - (2 * self._bpb.sectors_per_cluster)

    def _get_logical_cluster(self, cluster):
        first_sector_of_cluster = self._logical_cluster_to_physical_sector(cluster)
        bytes_per_cluster = self._bpb.sectors_per_cluster * SECTOR_SIZE
        start = SECTOR_SIZE * first_sector_of_cluster
        end = start + bytes_per_cluster
        return self.blob[start:end]

    def _get_cluster_list(self, cluster):
        clusters = [cluster]

        next_cluster = self._fat[cluster]
        if next_cluster:
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

        return data, [self._logical_cluster_to_physical_sector(s) for s in logical_clusters]

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
