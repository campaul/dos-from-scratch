#!/usr/bin/env python3
from collections import namedtuple
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

    image = sys.argv[1]
    filename = sys.argv[2].upper()

    print(Disk(image).get_file(filename).decode("UTF-8"), end="", flush=True)


if __name__ == '__main__':
    main()
