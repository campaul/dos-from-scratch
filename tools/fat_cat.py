#!/usr/bin/env python3
import sys

from fat import Disk


NO_IMAGE = 'Must specify a disk image!'
NO_FILENAME = 'Must specify a filename!'


def main():
    if len(sys.argv) < 2:
        print(NO_IMAGE)
        sys.exit(1)

    if len(sys.argv) < 3:
        print(NO_FILENAME)
        sys.exit(2)

    if len(sys.argv) == 4:
        partition = int(sys.argv[3])
    else:
        partition = 0

    image = sys.argv[1]
    filename = sys.argv[2].upper()

    try:
        data, _ = Disk(image).get_volume(partition).get_file(filename)
        print(data.decode("UTF-8"), end="", flush=True)
    except Exception:
        print("File Not Found")


if __name__ == '__main__':
    main()
