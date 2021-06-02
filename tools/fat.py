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


class Fat:

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

            # If the first byte of the filename is \0x00 the directory entry and
            # all following entries are empty
            if entry.filename == b'\x00\x00\x00\x00\x00\x00\x00\x00':
                break

            # Ignore anything created by a VFAT driver
            if entry.attributes != 15:
                entries.append(entry)

            i += 32

        self.entries = entries

    def get_entry(self, filename):
        for entry in self.entries:
            if entry.matches(filename):
                return entry

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
        return Fat(self.blob[512:11*512+1])

    @property
    def _root_dir(self):
        # TODO: I think this size varies depending on disk size and FAT type
        return self.blob[19*512:33*512]

    def _get_physical_cluster(self, cluster):
        return self.blob[512*cluster:512 * (cluster + 1)]

    def _get_logical_cluster(self, cluster):
        return self._get_physical_cluster(33 + cluster - 2)

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

        return data

    def get_info(self):
        return self._bpb

    def get_file(self, path):
        current = self._root_dir

        for segment in [s for s in path.split("/") if s != ""]:
            # TODO: Things that can go wrong:
            # - segment might not exist
            # - current might not be a directory
            entry = Directory(current).get_entry(segment)
            current = self._get_file_data(
                entry.first_logical_cluster,
                entry.file_size,
                entry.attributes == 16,
            )

        # TODO: make sure current isn't a directory
        return current

    def list(self, path):
        target = self.get_file(path)
        Directory(target).list()
