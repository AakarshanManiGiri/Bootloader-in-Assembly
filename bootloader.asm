[BITS 16]
[ORG 0x7C00]

KERNEL_SECTORS   equ 4
KERNEL_SEG       equ 0x1000

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7BFF

    mov [boot_drive], dl

    mov si, msg_boot
    call print_string_16

    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    mov bx, KERNEL_SEG
    mov es, bx
    xor bx, bx
    int 0x13
    jc .disk_error

    xor ax, ax
    mov es, ax

    mov si, msg_kernel_loaded
    call print_string_16

    in al, 0x92
    test al, 2
    jnz .a20_done
    or al, 2
    and al, 0xFE
    out 0x92, al
.a20_done:

    cli

    lgdt [gdt_descriptor]

    mov eax, cr0
    or  eax, 1
    mov cr0, eax

    jmp 0x08:pm_entry

print_string_16:
    lodsb
    cmp al, 0
    je  .done
    mov ah, 0x0E
    int 0x10
    jmp print_string_16
.done:
    ret

.disk_error:
    mov si, msg_disk_error
    call print_string_16
    cli
    hlt

[BITS 32]

pm_entry:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    jmp KERNEL_SEG * 16

align 8

gdt_start:
    dq 0

gdt_code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00

gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

boot_drive:      db 0
msg_boot:        db 'Stage 1: Bootloader running...', 13, 10, 0
msg_kernel_loaded: db 'Stage 1: Kernel loaded at 0x10000.', 13, 10, 0
msg_disk_error:  db 'ERROR: Could not read kernel from disk!', 13, 10, 0

    times 510 - ($ - $$) db 0
    dw 0xAA55