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

    ; print a dollar sign
    mov bx, msg
    call print

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


msg:
    db "Hello World!"
    crlf db 0x0d, 0x0a
    endstr db '$'


; padding
times 510-($-$$) db 0

; literally magic
dw 0xaa55
