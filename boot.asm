; boot.asm
[bits 16]
[org 0x7c00]


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
        mov sp, main
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

    ; print disk info for first floppy disk
    mov dl, 0x00
    call print_disk_info

    ; "It's now safe to turn off your computer."
    hlt
    jmp $-1


; Prints a $ terminated string
; bx: address of the string to print
print:
    pusha

    ; SI will point to the current character
    mov si, bx

    ; Set the arguments for BIOS teletype output
    mov ah, 0x0e
    mov bx, 0

    print_loop:
        ; load the next character from memory
        mov al, [si]

        ; check if we're at the end of the string
        cmp al, '$'
        je print_exit

        ; print the character
        int 0x10

        ; move on to the next character
        add si, 1
        jmp print_loop

    print_exit:
        popa
        ret


; Prints a register value in hexadecimal
; ax: the value to print
print_hex:
    pusha

    ; Overwrite the first character of HEX_VALUE with bits 15-12
    mov bx, ax
    shr bx, 12
    mov bx, [bx + HEX_TABLE]
    mov [HEX_VALUE + 0], bl

    ; Overwrite the second character of HEX_VALUE with bits 11-8
    mov bx, ax
    shr bx, 8
    and bx, 0x000f
    mov bx, [bx + HEX_TABLE]
    mov [HEX_VALUE + 1], bl

    ; Overwrite the third character of HEX_VALUE with bits 7-4
    mov bx, ax
    shr bx, 4
    and bx, 0x000f
    mov bx, [bx + HEX_TABLE]
    mov [HEX_VALUE + 2], bl

    ; Overwrite the fourth character of HEX_VALUE with bits 3-0
    mov bx, ax
    and bx, 0x000f
    mov bx, [bx + HEX_TABLE]
    mov [HEX_VALUE + 3], bl

    ; Print the now populated HEX_VALUE
    mov bx, HEX_VALUE
    call print

    popa
    ret

    HEX_VALUE: db "****$"
    HEX_TABLE: db "0123456789ABCDEF"


; Prints words of memory in hexadecimal
; bx: address of memory to print
; cx: number of words to print
print_mem:
    pusha

    ; SI will point to the current byte of memory
    mov si, bx

    print_mem_loop:
        ; Print one word of memory
        ; This loads bytes in big endian order
        mov ah, [si]
        mov al, [si + 1]
        call print_hex

        mov bx, SPACE
        call print

        ; Advance the memory pointer by 1 word
        ; Decrement the loop counter by 1 and exit if it's 0
        add si, 2
        sub cx, 1
        cmp cx, 0
        jne print_mem_loop

    mov bx, LINE_BREAK
    call print

    popa
    ret


; Loads disk info into the I_CYLINDERS, I_HEADS, and I_SECTORS
; labels
; dl: drive index
load_disk_info:
    pusha

    mov ah, 0x08
    int 0x13

    jc disk_error

    ; isolate bits [5:0] of CX
    ; this is the number of sectors
    mov ax, cx
    and ax, 0x3f
    mov [I_SECTORS], ax

    ; isolate bits [15:8] of DX
    ; this is the number of heads - 1
    mov al, dh
    mov ah, 0
    inc ax
    mov [I_HEADS], ax

    ; isolate bits [7:6][15-8] of CX
    ; this is the number of cylinders - 1
    mov al, ch
    mov ah, cl
    shr ah, 6
    inc ax
    mov [I_CYLINDERS], ax

    popa
    ret


; Prints disk info
; dl: drive index
print_disk_info:
    pusha

    call load_disk_info

    mov bx, CYLINDERS
    call print
    mov ax, [I_CYLINDERS]
    call print_hex
    mov bx, LINE_BREAK
    call print

    mov bx, HEADS
    call print
    mov ax, [I_HEADS]
    call print_hex
    mov bx, LINE_BREAK
    call print

    mov bx, SECTORS
    call print
    mov ax, [I_SECTORS]
    call print_hex
    mov bx, LINE_BREAK
    call print

    popa
    ret


disk_error:
    mov bx, DISK_ERROR_MESSAGE
    call print
    hlt
    jmp $-1


; allocate some memory to store disk info
I_CYLINDERS: dw 0
I_HEADS: dw 0
I_SECTORS: dw 0


; strings
SPACE: db " $"
LINE_BREAK: db 0x0a, 0x0d, "$"
WELCOME_MESSAGE: db "Loading DOS from Scratch...$"
DISK_ERROR_MESSAGE: db "Error Reading Disk!$"
CYLINDERS: db "Cylinders: $"
HEADS: db "Heads: $"
SECTORS: db "Sectors: $"


; padding
times 510-($-$$) db 0

; literally magic
dw 0xaa55
