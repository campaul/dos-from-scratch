; io.asm
[bits 16]
[org 0]


; Make sure DS and ES matches CS
mov ax, cs
mov ds, ax
mov es, ax


; Load the rest of IO.SYS
mov si, IO_SYS
call get_first_sector

; Skip past the first 3 sectors that the bootloader already loaded
call get_fat_entry
call get_fat_entry
call get_fat_entry

mov cx, 0
load_io_sys_loop:
    push ax
    push cx
    add ax, 31
    mov bx, FOURTH_SECTOR
    add bx, cx
    ; TODO: this is hard coded for 1 sector per cluster
    mov cl, 1
    call load_sectors
    pop cx
    pop ax

    call get_fat_entry
    add cx, 512

    cmp ax, 0x0fff  ; TODO: there are more values this could be
    jnz load_io_sys_loop


; Register int 0x21 handler
push ds
push 0
pop ds
mov word [0x86], cs
mov word [0x84], dos_api_handler
pop ds


; Print welcome message
mov ah, 0x09
mov bx, WELCOME_MESSAGE
int 0x21


; Halt
hlt
jmp $-1


%include "lib/string.asm"
%include "lib/disk.asm"
%include "lib/fat.asm"


IO_SYS: db "IO      SYS"


; Pad file to 3 sectors to ensure code above doesn't exceed that length
times 1536-($-$$) db 0


FOURTH_SECTOR:


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


WELCOME_MESSAGE: db "Welcome to DOS from Scratch!", 0x0a, 0x0d, "$"


FAT_WINDOW: times 1536 db 0
DIRECTORY_WINDOW: times 512 db 0
