; io.asm
[bits 16]
[org 0]


; Register int 0x21 handler
push 0
pop ds
mov word [0x86], cs
mov word [0x84], dos_api_handler


; Make sure DS matches CS
mov ax, cs
mov ds, ax


; Print welcome message
mov ah, 0x09
mov bx, WELCOME_MESSAGE
int 0x21


; Halt
hlt
jmp $-1


WELCOME_MESSAGE: db "Welcome to DOS from Scratch!$"


dos_api_handler:
    push si

    ; Load the address stored in the dos_api_functions array below
    ; dos_api_functions[ah * 2]
    mov si, ax
    shr si, 8
    shl si, 1
    add si, dos_api_functions
    mov si, [si]

    ; Call the appropriate handler
    call si

    pop si
    iret

    dos_api_functions:
        dw unknown_function_code  ; 0x00 program terminate
        dw unknown_function_code  ; 0x01 character input
        dw unknown_function_code  ; 0x02 character output
        dw unknown_function_code  ; 0x03 auxiliary input
        dw unknown_function_code  ; 0x04 auxiliary output
        dw unknown_function_code  ; 0x05 printer output
        dw unknown_function_code  ; 0x06 direct console I/O
        dw unknown_function_code  ; 0x07 direct console input without echo
        dw unknown_function_code  ; 0x07 console input without echo
        dw print                  ; 0x09 display string

        ; Fill out a full 256 entries so any unknown value of ah will result
        ; in a useful error message.
        times 256-($-dos_api_functions)/2 dw unknown_function_code


unknown_function_code:
    mov bx, UNKNOWN_FUNCTION
    call print

    shr ax, 8
    call print_hex

    hlt
    jmp $-1

    UNKNOWN_FUNCTION: db "Unknown function code: $"


%include "lib/print.asm"
%include "lib/debug.asm"
