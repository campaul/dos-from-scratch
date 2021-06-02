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
        filename = ""

    Disk(image).list(filename)


if __name__ == '__main__':
    main()
