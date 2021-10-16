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

    if len(sys.argv) > 2:
        filename = sys.argv[2].upper()
    else:
        print("no filename!")
        sys.exit(1)

    if filename == "/":
        filename = ""

    if len(sys.argv) == 4:
        partition = int(sys.argv[3])
    else:
        partition = 0

    Disk(image).get_volume(partition).list(filename)


if __name__ == '__main__':
    main()
