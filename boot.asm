; boot.asm
[bits 16]
[org 0x7c00]


; label for where to place the stack
; since it grows towards 0 so the top of the bootloader is a good locataion
stack:


; empty space that will be replaced with FAT information
times 62-($-$$) db 0


main:
    ; disable interrupts
    cli

    ; make sure the CPU is in a sane state
    jmp 0x0000:clear_segment_registers
    clear_segment_registers:
        xor ax, ax
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov sp, stack
        cld

    ; re-enable interrupts
    sti

    ; ensure the video mode is set to 80x25 16 colors
    ; this also clears the screen
    mov ah, 0
    mov al, 0x03
    int 0x10

    ; print loading message
    mov bx, WELCOME_MESSAGE
    call print

    mov bx, LINE_BREAK
    call print
    call print

    ; print bootloader contents
    mov bx, 0x7c00
    mov cx, 256
    call print_mem

    ; reset disk system
    mov ah, 0
    mov dl, 0
    int 0x13
    jc error

    ; load first sector of root directory
    ; TODO: compute location of root directory
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov dh, 1
    mov cl, 2
    mov dl, 0
    mov bx, 0x500
    int 0x13
    jc error

    ; load IO.SYS
    ; TODO: make sure IO.SYS is the first file in the root dir
    ; TODO: compute location of IO.SYS
    mov ah, 0x02
    mov al, 3
    mov ch, 0  ; cylinder
    mov dh, 1  ; head
    mov cl, 16 ; sector
    mov dl, 0  ; drive
    mov bx, 0x700
    int 0x13
    jc error

    ; setup information IO.SYS needs
    ; TODO: figure out what the value in dx is
    mov ax, 0       ; media descriptor (0x7c15)
    mov bx, 0x21    ; drive number (0x7c24)
    mov cx, 0xf000  ; IO.SYS sector
    mov dx, 0       ; ???

    ; jump to IO.SYS
    jmp 0x70:0


error:
    mov bx, ERROR
    call print

    hlt
    jmp $-1


%include "lib/print.asm"
%include "lib/debug.asm"


; strings
WELCOME_MESSAGE: db "Loading DOS from Scratch...$"
ERROR: db "Error loading OS!"


; padding
times 510-($-$$) db 0

; literally magic
dw 0xaa55
