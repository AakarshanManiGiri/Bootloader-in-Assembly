[BITS 16]
[ORG 0x7C00]

KERNEL_SECTORS   equ 4
KERNEL_SEG       equ 0x1000
BOOT_INFO_ADDR   equ 0x500

; I2C GPIO pins (example: GPIO 26 = SDA, GPIO 25 = SCL on common embedded systems)
I2C_SDA_PORT     equ 0x60
I2C_SCL_PORT     equ 0x62

; E-ink controller addresses
EINK_IL0323      equ 0x48
EINK_UC8151      equ 0x4C
EINK_SSD1619     equ 0x68

; Touchscreen controller addresses
TOUCH_GT911      equ 0x5D
TOUCH_FT5436     equ 0x38

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7BFF

    mov [boot_drive], dl

    mov si, msg_boot
    call print_string_16

    ; Initialize boot info structure
    call init_boot_info

    ; Detect hardware
    call detect_storage
    call detect_eink_display
    call detect_input_device

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

; Initialize boot information structure at 0x500
init_boot_info:
    push ax
    push es
    mov ax, 0x50
    mov es, ax
    xor di, di
    
    ; Clear boot info (16 bytes)
    mov cx, 8
    xor ax, ax
.clear_loop:
    mov word [es:di], 0
    add di, 2
    loop .clear_loop
    
    pop es
    pop ax
    ret

; Detect storage device type
detect_storage:
    push ax
    push dx
    push si
    
    mov si, msg_detect_storage
    call print_string_16
    
    ; Check for SD card via BIOS (basic check)
    mov dl, [boot_drive]
    mov ah, 0x41           ; Check extensions
    mov bx, 0x55AA
    int 0x13
    
    cmp bx, 0xAA55
    jne .storage_unknown
    
    ; SD card detected
    mov si, msg_storage_sd
    call print_string_16
    
    mov ax, 0x50
    mov es, ax
    mov byte [es:1], 0x01  ; Storage type: SD card
    jmp .storage_done
    
.storage_unknown:
    mov si, msg_storage_unknown
    call print_string_16
    mov ax, 0x50
    mov es, ax
    mov byte [es:1], 0xFF  ; Storage type: unknown
    
.storage_done:
    pop si
    pop dx
    pop ax
    ret

; Detect E-ink display via I2C probe
detect_eink_display:
    push ax
    push bx
    push si
    
    mov si, msg_detect_eink
    call print_string_16
    
    ; Probe common e-ink controller addresses
    mov al, EINK_IL0323
    call i2c_probe
    cmp al, 1
    je .eink_found_il0323
    
    mov al, EINK_UC8151
    call i2c_probe
    cmp al, 1
    je .eink_found_uc8151
    
    mov al, EINK_SSD1619
    call i2c_probe
    cmp al, 1
    je .eink_found_ssd1619
    
    ; No e-ink found
    mov si, msg_eink_not_found
    call print_string_16
    mov ax, 0x50
    mov es, ax
    mov byte [es:2], 0x00
    jmp .eink_done
    
.eink_found_il0323:
    mov si, msg_eink_il0323
    call print_string_16
    mov ax, 0x50
    mov es, ax
    mov byte [es:2], 0x01
    jmp .eink_done
    
.eink_found_uc8151:
    mov si, msg_eink_uc8151
    call print_string_16
    mov ax, 0x50
    mov es, ax
    mov byte [es:2], 0x02
    jmp .eink_done
    
.eink_found_ssd1619:
    mov si, msg_eink_ssd1619
    call print_string_16
    mov ax, 0x50
    mov es, ax
    mov byte [es:2], 0x03
    
.eink_done:
    pop si
    pop bx
    pop ax
    ret

; Detect input device (touchscreen) via I2C
detect_input_device:
    push ax
    push si
    
    mov si, msg_detect_input
    call print_string_16
    
    ; Probe GT911 touchscreen
    mov al, TOUCH_GT911
    call i2c_probe
    cmp al, 1
    je .input_found_gt911
    
    ; Probe FT5436 touchscreen
    mov al, TOUCH_FT5436
    call i2c_probe
    cmp al, 1
    je .input_found_ft5436
    
    ; No touchscreen found
    mov si, msg_input_not_found
    call print_string_16
    mov ax, 0x50
    mov es, ax
    mov byte [es:3], 0x00
    jmp .input_done
    
.input_found_gt911:
    mov si, msg_input_gt911
    call print_string_16
    mov ax, 0x50
    mov es, ax
    mov byte [es:3], 0x01
    jmp .input_done
    
.input_found_ft5436:
    mov si, msg_input_ft5436
    call print_string_16
    mov ax, 0x50
    mov es, ax
    mov byte [es:3], 0x02
    
.input_done:
    pop si
    pop ax
    ret

; Simple I2C probe routine
; Input: AL = device address (7-bit)
; Output: AL = 1 if device found, 0 if not
; This is a simplified probe - just returns success for demo
i2c_probe:
    push bx
    push cx
    
    ; In a real implementation, you would:
    ; 1. Set SDA/SCL high
    ; 2. Send START condition
    ; 3. Send address byte
    ; 4. Check for ACK
    ; 5. Send STOP condition
    
    ; For bootloader demo, we simulate with a small delay
    mov bx, 0x1000
.probe_delay:
    nop
    dec bx
    cmp bx, 0
    jne .probe_delay
    
    ; Always return success for demo (in real code, check ACK)
    mov al, 1
    
    pop cx
    pop bx
    ret

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

; Hardware detection messages
msg_detect_storage:   db 'Detecting storage...', 13, 10, 0
msg_storage_sd:       db '  [OK] SD Card detected', 13, 10, 0
msg_storage_unknown:  db '  [?] Storage type unknown', 13, 10, 0

msg_detect_eink:      db 'Detecting e-ink display...', 13, 10, 0
msg_eink_not_found:   db '  [!] E-ink display NOT found', 13, 10, 0
msg_eink_il0323:      db '  [OK] E-ink controller: IL0323', 13, 10, 0
msg_eink_uc8151:      db '  [OK] E-ink controller: UC8151', 13, 10, 0
msg_eink_ssd1619:     db '  [OK] E-ink controller: SSD1619', 13, 10, 0

msg_detect_input:     db 'Detecting input device...', 13, 10, 0
msg_input_not_found:  db '  [!] Touchscreen NOT found', 13, 10, 0
msg_input_gt911:      db '  [OK] Touchscreen: GT911', 13, 10, 0
msg_input_ft5436:     db '  [OK] Touchscreen: FT5436', 13, 10, 0

    times 510 - ($ - $$) db 0
    dw 0xAA55