; Find the first sector of a file
; si: address of the filename in memory
; TODO: figure out how to handle files that don't exist
; TODO: take DIRECTORY_WINDOW in bx
get_first_sector:
    push bx
    push cx

    mov ax, 19

    get_first_sector_loop:
        ; TODO: this is hardcoded to the root directory on a 1.44MB floppy
        cmp ax, 33
        je get_first_sector_not_found

        mov bx, DIRECTORY_WINDOW
        ; TODO: this is hard coded for 1 sector per cluster
        mov cl, 1
        call load_sectors

        push ax
        call get_directory_entry
        cmp ax, 0
        jne get_first_sector_found
        pop ax
        inc ax
        
        jmp get_first_sector_loop

    get_first_sector_not_found:
        mov ax, 0
        jmp get_first_sector_done

    get_first_sector_found:
        add sp, 2

    get_first_sector_done:
        pop cx
        pop bx
        ret


; Find the first sector of a file in a one sector slice of directory entries
; si: address of the filename in memory 
; TODO: take directory window in di
get_directory_entry:
    push bx
    push cx
    push di

    mov cx, 0
    mov ax, 0

    get_directory_entry_loop:
        cmp cx, 512
        je get_directory_entry_done

        mov di, DIRECTORY_WINDOW
        add di, cx
        push cx

        mov cx, 11
        call compare_string
        je get_directory_entry_found
        pop cx

        add cx, 32
        jmp get_directory_entry_loop

    get_directory_entry_found:
        pop cx
        mov bx, cx
        mov ax, [bx + DIRECTORY_WINDOW + 26]

    get_directory_entry_done:
        pop di
        pop cx
        pop bx
        ret


; Load the value of an entry in the FAT
; ax: number of FAT entry to load
get_fat_entry:
    push bx
    push cx
    push dx

    ; Compute location in FAT
    ; Using 3 block (1.5k) windows:
    ;   ax = index / 1024 = which window to load
    ;   dx = index % 1024 = which entry in window
    mov bx, 1024
    div bx

    ; Calculate the sector on disk where the FAT window starts
    mov bl, 3
    mul bl
    inc ax  ; ax now points to sector on disk
            ; inc gets us past the boot sector but assumes no partitions
            ; TODO: add hidden sectors instead

    ; load sector al to FAT_WINDOW
    mov bx, FAT_WINDOW
    mov cx, 3
    call load_sectors

    ; Compute the index of the FAT entry in the FAT window
    mov ax, 3
    mov bx, 2
    mul dl          ; multiply index by 3
    div bl          ; and divide by 2
    and ax, 0x00ff  ; ignore the remainder
    mov bx, ax      ; store the result in bx

    ; Load the value from the FAT window
    mov ax, [FAT_WINDOW + bx]

    ; The value will be either the upper or lower 12 bits depending on if
    ; the index being read is even or odd
    test dl, 1
    jnz get_fat_entry_odd

    get_fat_entry_even:
        and ax, 0x0fff
        jmp get_fat_entry_end

    get_fat_entry_odd:
        shr ax, 4

    get_fat_entry_end:
        pop dx
        pop cx
        pop bx
        ret
