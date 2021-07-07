; io.asm
[bits 16]
[org 0]


; Make sure DS matches CS
mov ax, cs
mov ds, ax


; Print welcome message
mov bx, WELCOME_MESSAGE
call print


; Halt
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


WELCOME_MESSAGE: db "Welcome to DOS From Scratch$"
