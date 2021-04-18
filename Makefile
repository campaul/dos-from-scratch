build:
	mkdir build

build/boot.img: build boot.asm
	nasm -fbin boot.asm -o build/boot.img

build/disk.img: build/boot.img
	qemu-img create build/disk.img 1474560B
	dd if=build/boot.img of=build/disk.img bs=512 count=1 conv=notrunc

.PHONY:
run: build/disk.img
	qemu-system-x86_64 -drive format=raw,if=floppy,file=build/disk.img

.PHONY:
clean:
	rm -rf build
