build:
	mkdir build

build/boot.img: build boot.asm
	nasm -fbin boot.asm -o build/boot.img

build/disk.img: build/boot.img
	qemu-img create build/disk.img 1474560B
	mkfs.msdos -n DFS build/disk.img
	dd if=build/boot.img of=build/disk.img bs=1 count=450 seek=62 skip=62 conv=notrunc

.PHONY:
run: build/disk.img
	qemu-system-x86_64 -drive format=raw,if=floppy,file=build/disk.img

.PHONY:
clean:
	rm -rf build
