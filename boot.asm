[BITS 16]         ; Код работает в 16-битном режиме
[ORG 0x7C00]      ; Начало загрузки BIOS

start:
    cli           ; Отключаем прерывания
    mov ax, 0x07C0
    mov ds, ax
    mov es, ax

    ; Установка видеорежима
    mov ax, 0x13
    int 0x10

    ; Читаем ядро с диска (сектор 2 и дальше)
    mov ah, 0x02
    mov al, 20
    mov ch, 0
    mov dh, 0
    mov cl, 2
    mov bx, 0x1000
    int 0x13

    ; Переход в защищённый режим
    cli
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    jmp CODE_SEG:init_pm  ; Переход в 32-битный режим

[BITS 32]         ; Переход в защищённый режим

init_pm:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000      ; Устанавливаем стек

    call kernel_main      ; Вызываем ядро

hang:
    hlt
    jmp hang

gdt_start:
gdt_null:
    dd 0
    dd 0
gdt_code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x9A
    db 0xCF
    db 0x00
gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x92
    db 0xCF
    db 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

times 510-($-$$) db 0
dw 0xAA55  ; Завершающий сигнатурный байт BIOS
