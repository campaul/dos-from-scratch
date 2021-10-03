; Loads an LBA sector from disk
; TODO: this is currently hardcoded for a 1.44MB floppy
; ax: sector to load
; bx: location to load it
; cl: number of sectors to read
load_sectors:
    pusha

    push ax

    ; Calculate Cylinder
    ; ch <- LBA ÷ (36)
    mov dh, 36
    div dh
    mov ch, al

    ; Calculate Head
    ; dh <- (LBA / 18) mod 2
    pop ax
    mov dh, 18
    div dh
    push ax  ; Store (LBA / 18) for use when calculating s
    mov ah, 0
    mov dh, 2
    div dh
    mov dh, ah

    ; Calculate Sector
    ; cl <- (LBA mod 18) + 1
    ; al < number of sectors to read
    pop ax
    inc ah
    mov al, ah
    xchg cl, al

    ; Perform Disk Read
    ; TODO: This is currently hardcoded for disk 0
    mov ah, 0x02
    mov dl, 0
    int 0x13
    jc disk_error

    popa
    ret


disk_error:
    mov bx, DISK_ERROR_MESSAGE
    call print

    hlt
    jmp $-1

    DISK_ERROR_MESSAGE: db "Error reading disk!$"

TEST_MESSAGE: db "Reading Disk", 0x0a, 0x0d, "$"
