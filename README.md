# DOS from Scratch

![build](https://github.com/campaul/dos-from-scratch/actions/workflows/dfs.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Implementing a DOS compatible operating system from scratch

## Requirements

Building and running this project requires the following tools:

- sh
- make
- nasm
- qemu
- qemu-utils
- dosfstools or newfs_msdos
- mtools

Additionally, the following reqirements may be necessary to run some optional tools:

- python

## Usage

To run the OS, do `make run`

If you have an MS-DOS boot disk, you can place it at `msdos/disk.img` and do `make run_msdos` to run that disk using the DOS from Scratch bootloader.

## Blog Posts

The development of this project is being documented in a series of [blog posts](https://toast.zeroflag.net/dos-from-scratch-introduction).
