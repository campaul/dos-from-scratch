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
