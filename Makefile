build:
	mkdir build

build/boot.img: build boot.asm
	nasm -fbin boot.asm -o build/boot.img

build/IO.SYS: build io.asm
	nasm -fbin io.asm -o build/IO.SYS

build/disk.img: build/boot.img build/IO.SYS
	# TODO: make IO.SYS first entry in root directory
	# TODO: format disk using mtools
	qemu-img create build/disk.img 1474560B && \
	tools/format.sh DFS build/disk.img && \
	mcopy -i build/disk.img build/IO.SYS ::IO.SYS && \
	mcopy -i build/disk.img README.md ::README.md && \
	dd if=build/boot.img of=build/disk.img bs=1 count=450 seek=62 skip=62 conv=notrunc || \
	(rm build/disk.img && false)

build/msdos.img: build/boot.img msdos/disk.img
	cp msdos/disk.img build/msdos.img && \
	dd if=build/boot.img of=build/msdos.img bs=1 count=450 seek=62 skip=62 conv=notrunc || \
	(rm build/msdos.img && false)

.PHONY:
run: build/disk.img
	qemu-system-x86_64 -drive format=raw,if=floppy,file=build/disk.img

.PHONY:
run_msdos: build/msdos.img
	qemu-system-x86_64 -drive format=raw,if=floppy,file=build/msdos.img

.PHONY:
clean:
	rm -rf build
