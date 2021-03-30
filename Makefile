build:
	mkdir build

build/boot.img: build boot.asm
	nasm -fbin boot.asm -o build/boot.img

.PHONY:
run: build/boot.img
	qemu-system-x86_64 -drive format=raw,file=build/boot.img

.PHONY:
clean:
	rm -rf build
