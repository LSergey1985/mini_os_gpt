#include <stdint.h>

#define SECTOR_SIZE 512
#define CLUSTER_SIZE 512

void kernel_main() {
    clear_screen();
    print("Minimal OS Kernel Loaded\n");
    init_fat16();
    init_multitasking();
    
    char buffer[SECTOR_SIZE * 4];
    if (fat16_read_file("KERNEL.BIN", buffer, sizeof(buffer), 19)) {
        print("File Loaded: \n");
        print(buffer);
    } else {
        print("File Not Found\n");
    }
    
    fat16_create_file("TEST.TXT");
    fat16_write_file("TEST.TXT", "Hello, FAT16!", 14);
    
    while (1) {
        char c = keyboard_getchar();
        if (c) {
            print_char(c);
        }
    }
}

void clear_screen() {
    volatile char *video = (volatile char*) 0xB8000;
    for (int i = 0; i < 80 * 25 * 2; i += 2) {
        video[i] = ' ';
        video[i+1] = 0x07;
    }
}

void print(const char *str) {
    volatile char *video = (volatile char*) 0xB8000;
    static uint16_t pos = 0;
    while (*str) {
        video[pos++] = *str++;
        video[pos++] = 0x07;
    }
}

void print_char(char c) {
    volatile char *video = (volatile char*) 0xB8000;
    static uint16_t pos = 0;
    video[pos++] = c;
    video[pos++] = 0x07;
}

char keyboard_getchar() {
    if ((inb(0x64) & 1) == 0) {
        return 0;
    }
    return inb(0x60);
}

static inline uint8_t inb(uint16_t port) {
    uint8_t value;
    asm volatile ("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

void init_fat16() {
    print("Initializing FAT16...\n");
}

void init_multitasking() {
    print("Initializing Multitasking...\n");
}

int fat16_write_file(const char *filename, const char *data, uint32_t size) {
    char sector[SECTOR_SIZE];
    read_sector(19, sector);
    
    for (int i = 0; i < SECTOR_SIZE; i += 32) {
        if (!strncmp((char*)&sector[i], filename, 11)) {
            uint16_t cluster = *(uint16_t*)&sector[i + 26];
            write_sector(33 + (cluster - 2), (char*)data);
            return 1;
        }
    }
    return 0;
}

int fat16_create_file(const char *filename) {
    char sector[SECTOR_SIZE];
    read_sector(19, sector);
    
    for (int i = 0; i < SECTOR_SIZE; i += 32) {
        if (sector[i] == 0x00) {
            memcpy(&sector[i], filename, 11);
            sector[i + 11] = 0x20;
            uint16_t cluster = 2;
            *(uint16_t*)&sector[i + 26] = cluster;
            write_sector(19, sector);
            
            char empty_sector[SECTOR_SIZE] = {0};
            write_sector(33 + (cluster - 2), empty_sector);
            return 1;
        }
    }
    return 0;
}

uint16_t fat16_next_cluster(uint16_t cluster) {
    char fat_table[SECTOR_SIZE];
    read_sector(1, fat_table);
    return *(uint16_t*)&fat_table[cluster * 2] & 0xFFF;
}

void write_sector(uint32_t lba, char *buffer) {
    outb(0x1F6, (lba >> 24) | 0xE0);
    outb(0x1F2, 1);
    outb(0x1F3, lba & 0xFF);
    outb(0x1F4, (lba >> 8) & 0xFF);
    outb(0x1F5, (lba >> 16) & 0xFF);
    outb(0x1F7, 0x30);
    
    while (!(inb(0x1F7) & 8));
    for (int i = 0; i < SECTOR_SIZE / 2; i++) {
        outw(0x1F0, ((uint16_t*)buffer)[i]);
    }
}

static inline void outb(uint16_t port, uint8_t value) {
    asm volatile ("outb %0, %1" :: "a"(value), "Nd"(port));
}

static inline uint16_t inw(uint16_t port) {
    uint16_t value;
    asm volatile ("inw %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

static inline void outw(uint16_t port, uint16_t value) {
    asm volatile ("outw %0, %1" :: "a"(value), "Nd"(port));
}
