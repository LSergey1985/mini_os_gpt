[BITS 16]
[ORG 0x7C00]  ; BIOS загружает загрузчик по адресу 0x7C00

start:
    cli               ; Запрещаем прерывания
    mov ax, 0x07C0   ; Устанавливаем сегмент данных
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFF   ; Устанавливаем стек
    sti               ; Включаем прерывания

    mov si, msg       ; Выводим сообщение
    call print

    call load_kernel  ; Загружаем ядро
    call switch_to_pm ; Переход в защищенный режим

    jmp $            ; Бесконечный цикл (если что-то пошло не так)

print:
    lodsb
    or al, al
    jz done
    mov ah, 0x0E
    int 0x10
    jmp print

done:
    ret

load_kernel:
    ; Здесь будет код для загрузки ядра с FAT16
    ret

switch_to_pm:
    cli
    lgdt [gdt_descriptor]  ; Загружаем GDT
    mov eax, cr0
    or eax, 1
    mov cr0, eax           ; Включаем защищенный режим
    jmp CODE_SEG:init_pm   ; Дальний прыжок для активации

[BITS 32]
init_pm:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000  ; Устанавливаем стек
    call kernel_main  ; Переход к ядру
    jmp $

; Описание GDT
gdt:
    dw 0x0000, 0x0000, 0x0000, 0x0000  ; NULL-сегмент
    dw 0xFFFF, 0x0000, 0x9A00, 0x00CF  ; Кодовый сегмент
    dw 0xFFFF, 0x0000, 0x9200, 0x00CF  ; Данные сегмент

gdt_descriptor:
    dw gdt_descriptor - gdt - 1
    dd gdt

CODE_SEG equ 0x08
DATA_SEG equ 0x10

msg db "Booting minimal OS...", 0

times 510-($-$$) db 0  ; Дополняем до 512 байт
DW 0xAA55               ; Boot signature
