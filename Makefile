build:
	mkdir build

build/boot.img: build boot.asm
	nasm -fbin boot.asm -o build/boot.img

build/disk.img: build/boot.img README.md
	qemu-img create build/disk.img 1474560B && \
	tools/format.sh DFS build/disk.img && \
	mcopy -i build/disk.img README.md ::README.md && \
	dd if=build/boot.img of=build/disk.img bs=1 count=450 seek=62 skip=62 conv=notrunc || \
	(rm build/disk.img && false)

.PHONY:
run: build/disk.img
	qemu-system-x86_64 -drive format=raw,if=floppy,file=build/disk.img

.PHONY:
clean:
	rm -rf build
