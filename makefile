all: os-image

# Компиляция загрузчика
boot.bin: boot.asm
	nasm -f bin boot.asm -o boot.bin

# Компиляция ядра
kernel.bin: kernel.c
	x86_64-elf-gcc -ffreestanding -m32 -c kernel.c -o kernel.o
	x86_64-elf-ld -T linker.ld -o kernel.bin kernel.o

# Объединение файлов в образ
os-image: boot.bin kernel.bin
	cat boot.bin kernel.bin > os-image.bin

# Запуск ОС в QEMU
run: os-image
	qemu-system-x86_64 -drive format=raw,file=os-image.bin

clean:
	rm -f *.bin *.o
