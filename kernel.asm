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

; Boot info structure offsets
BOOT_INFO_BASE equ 0x500
STORAGE_TYPE   equ 0x01
EINK_TYPE      equ 0x02
INPUT_TYPE     equ 0x03

kernel_start:
    mov esp, 0x80000

    call clear_screen

    mov esi, msg_welcome
    mov ah, (COL_WHITE << 8) | COL_CYAN
    call print_string

    ; Display detected hardware
    call display_hardware_info

    mov esi, msg_ready
    mov ah, (COL_YELLOW << 8) | COL_BLACK
    call print_string

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

display_hardware_info:
    pusha
    
    mov edi, VGA_BUFFER + (VGA_COLS * 2 * 5)
    
    ; Display storage info
    mov esi, msg_storage_info
    mov ah, (COL_WHITE << 8) | COL_GREEN
    call print_string_at
    
    mov eax, [BOOT_INFO_BASE + STORAGE_TYPE]
    cmp al, 0x01
    je .storage_sd
    jmp .storage_unknown
    
.storage_sd:
    mov esi, msg_storage_sd_info
    jmp .storage_print
.storage_unknown:
    mov esi, msg_storage_unknown_info
.storage_print:
    call print_string_at
    
    ; Display e-ink info
    add edi, VGA_COLS * 2
    mov esi, msg_eink_info
    call print_string_at
    
    mov eax, [BOOT_INFO_BASE + EINK_TYPE]
    cmp al, 0x01
    je .eink_il0323
    cmp al, 0x02
    je .eink_uc8151
    cmp al, 0x03
    je .eink_ssd1619
    jmp .eink_unknown
    
.eink_il0323:
    mov esi, msg_eink_il0323_info
    jmp .eink_print
.eink_uc8151:
    mov esi, msg_eink_uc8151_info
    jmp .eink_print
.eink_ssd1619:
    mov esi, msg_eink_ssd1619_info
    jmp .eink_print
.eink_unknown:
    mov esi, msg_eink_unknown_info
.eink_print:
    call print_string_at
    
    ; Display input device info
    add edi, VGA_COLS * 2
    mov esi, msg_input_info
    call print_string_at
    
    mov eax, [BOOT_INFO_BASE + INPUT_TYPE]
    cmp al, 0x01
    je .input_gt911
    cmp al, 0x02
    je .input_ft5436
    jmp .input_unknown
    
.input_gt911:
    mov esi, msg_input_gt911_info
    jmp .input_print
.input_ft5436:
    mov esi, msg_input_ft5436_info
    jmp .input_print
.input_unknown:
    mov esi, msg_input_unknown_info
.input_print:
    call print_string_at
    
    popa
    ret

print_string_at:
    push ax
.print_char_at:
    lodsb
    cmp al, 0
    je  .done_at
    mov ax, [edi]
    mov al, [esi - 1]
    mov [edi], ax
    add edi, 2
    jmp .print_char_at
.done_at:
    pop ax
    ret

msg_welcome:
    db '===  MyOS E-Reader  ===', 13, 10
    db '32-bit Protected Mode Kernel', 13, 10
    db 'Running at linear address 0x10000', 13, 10, 13, 10, 0

msg_storage_info:     db 'Storage: ', 0
msg_storage_sd_info:  db 'SD Card', 13, 10, 0
msg_storage_unknown_info: db 'Unknown', 13, 10, 0

msg_eink_info:        db 'Display: ', 0
msg_eink_il0323_info: db 'IL0323 (2.9 inch)', 13, 10, 0
msg_eink_uc8151_info: db 'UC8151 (2.7 inch)', 13, 10, 0
msg_eink_ssd1619_info: db 'SSD1619 (4.2 inch)', 13, 10, 0
msg_eink_unknown_info: db 'Not detected', 13, 10, 0

msg_input_info:       db 'Input: ', 0
msg_input_gt911_info: db 'GT911 Touchscreen', 13, 10, 0
msg_input_ft5436_info: db 'FT5436 Touchscreen', 13, 10, 0
msg_input_unknown_info: db 'Not detected', 13, 10, 0

msg_ready:

    times (4 * 512) - ($ - $$) db 0
