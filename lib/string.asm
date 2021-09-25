; Compare 2 strings of a given length
; zero flag set if strings are equal
; ds:si: address of first string
; es:di: address of second string
; cx: length of string
compare_string:
    push si
    push di
    push cx
    push bx

    compare_string_loop
        ; Check if we're at end of loop
        ; Exiting here will leave the zero flag set
        cmp cx, 0
        je compare_string_end

        ; Compare the current bytes of string
        ; Exiting here will leave the zero flag unset
        cmpsb
        jne compare_string_end

        ; Decrement counter, increment string index
        dec cx
        jmp compare_string_loop

    compare_string_end:
        pop bx
        pop cx
        pop di
        pop si
        ret
