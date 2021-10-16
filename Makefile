build:
	mkdir build

build/boot.img: build boot.asm lib/print.asm lib/debug.asm lib/disk.asm
	nasm -fbin boot.asm -o build/boot.img

build/IO.SYS: build io.asm lib/print.asm lib/debug.asm lib/disk.asm lib/fat.asm lib/string.asm
	nasm -fbin io.asm -o build/IO.SYS

build/disk.img: build/boot.img build/IO.SYS README.md
	# TODO: make IO.SYS first entry in root directory
	# TODO: format disk using mtools
	qemu-img create build/disk.img 1474560B && \
	tools/format.sh DFS build/disk.img && \
	mcopy -i build/disk.img build/IO.SYS ::IO.SYS && \
	mcopy -i build/disk.img README.md ::README.md && \
	dd if=build/boot.img of=build/disk.img bs=1 count=450 seek=62 skip=62 conv=notrunc || \
	(rm build/disk.img && false)

build/msdos.img: build/boot.img msdos/disk.img README.md
	cp msdos/disk.img build/msdos.img && \
	mcopy -i build/msdos.img README.md ::README.md && \
	dd if=build/boot.img of=build/msdos.img bs=1 count=450 seek=62 skip=62 conv=notrunc || \
	(rm build/msdos.img && false)

build/hdd.img:
	qemu-img create build/hdd.img 21411840B

.PHONY:
run: build/disk.img build/hdd.img
	qemu-system-x86_64 -drive format=raw,if=floppy,file=build/disk.img -monitor stdio -drive file=build/hdd.img,format=raw,if=ide --boot order=a

.PHONY:
run_msdos: build/msdos.img build/hdd.img
	qemu-system-x86_64 -drive format=raw,if=floppy,file=build/msdos.img -monitor stdio -drive file=build/hdd.img,format=raw,if=ide --boot order=a

.PHONY:
clean:
	rm -rf build
