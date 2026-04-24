[BITS 16]
[ORG 0x7C00]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7BFF

    mov si, message

.print_loop:
    lodsb
    cmp al, 0
    je .halt

    mov ah, 0x0E
    int 0x10

    jmp .print_loop

.halt:
    jmp 0x1000:0x0000

message:
    db 'Wassup!', 13, 10
    db 'OS to be loaded at 0x10000.', 13, 10
    db 'Bootunloader.', 0

    times 510 - ($ - $$) db 0
    dw 0xAA55