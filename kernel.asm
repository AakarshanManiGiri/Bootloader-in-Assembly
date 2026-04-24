[BITS 32]
[ORG 0x10000]

VGA_WIDTH   equ 80
VGA_HEIGHT  equ 25
VGA_BUFFER  equ 0xB8000
VGA_COLS    equ 80

COL_BLACK   equ 0x00
COL_BLUE    equ 0x01
COL_GREEN   equ 0x02
COL_CYAN    equ 0x03
COL_RED     equ 0x04
COL_MAGENTA equ 0x05
COL_BROWN   equ 0x06
COL_WHITE   equ 0x07
COL_YELLOW  equ 0x0E

kernel_start:
    mov esp, 0x80000

    call clear_screen

    mov esi, msg_welcome
    mov ah, (COL_WHITE << 8) | COL_CYAN
    call print_string

    mov esi, msg_info
    mov ah, (COL_WHITE << 8) | COL_GREEN
    call print_string

    mov esi, msg_ready
    mov ah, (COL_YELLOW << 8) | COL_BLACK
    call print_string

.idle:
.idle:
    hlt
    jmp .idle

clear_screen:
    pusha
    mov edi, VGA_BUFFER
    mov ecx, VGA_WIDTH * VGA_HEIGHT
    mov ax, (COL_BLACK << 8) | COL_WHITE | (' ' << 8)
.clear_loop:
    stosw
    dec ecx
    jnz .clear_loop
    popa
    ret

print_string:
    pusha
    mov edi, VGA_BUFFER + (VGA_COLS * 2 * 0)
.print_char:
    lodsb
    cmp al, 0
    je  .done
    stosw
    jmp .print_char
.done:
    popa
    ret

msg_welcome:
    db '===  MyOS  ===', 13, 10
    db '32-bit Protected Mode Kernel', 13, 10
    db 'Running at linear address 0x10000', 13, 10, 13, 10, 0

msg_info:
    db 'CPU : IA-32 (protected mode)', 13, 10
    db 'GDT : Flat model 0-4 GB', 13, 10
    db 'VGA : 80x25 text mode', 13, 10, 13, 10, 0

msg_ready:
    db 'System ready. Type on keyboard (no handler yet).', 13, 10, 0

    times (4 * 512) - ($ - $$) db 0
