[bits 16]
extern log
extern load
extern num2hex
extern HEXNUMBER
extern KERNEL_START_SECTOR

mov si, MODE32
call log

call enable_a20

; now, at addresses 0x0 - 0x20, lets place some information about the system that the kernel can use
mov ah, 0 ; set vga mode
mov al, 3 ; colour text 80x25
int 10h

; read video mode
mov ah, 0x0f
int 10h
xchg bx, bx

; al = video mode, ah = character columns
mov byte [0x01], ah
mov byte [0x02], al


; first sector of kernel has a 16-bit number with the amount of sectors
mov cx, 0x1000
mov es, cx ; extra segment
mov ebx, KERNEL_START_SECTOR
mov cl, bl
mov ch, 0
mov dh, 0
mov al, 1 ; read 1 512-byte sector
mov ebx, 0 ; place at 0. bios places bx offset by es

call load

mov eax, dword es:[bx] ; kernel header at byte 0 has kernel length as a dword
mov cx, 0
mov es, cx ; reset segments

mov si, KSIZE
call log

; print kernel size
rol eax, 16
call num2hex
mov si, HEXNUMBER
call log
rol eax, 16
call num2hex
mov si, HEXNUMBER
call log
mov si, ENDL
call log

mov cx, 0x1000
mov es, cx ; extra segment
mov [KERNEL_SIZE], eax ; eax still has the kernel size from before 
add ebx, 4 ; add 4 bytes
mov eax, dword es:[ebx] ; read 4 bytes past 
mov [BOOTSTRAP_START], eax ; save addr to jump to 

mov si, BSTART
call log

; print bootstrap start addr
rol eax, 16
call num2hex
mov si, HEXNUMBER
call log
rol eax, 16
call num2hex
mov si, HEXNUMBER
call log
mov si, ENDL
call log

; while the kernel size is under 130 kb we can use one intr call and the lower bits of eax

mov ebx, KERNEL_START_SECTOR
inc ebx
mov cl, bl
mov ch, 0
mov dh, 0
mov eax, [KERNEL_SIZE]
mov ebx, 0 ; place at 0. offset by es*16 so its actually 0x10000
global loadstuff
loadstuff:


call load


mov si, KCOUNT
call log
call num2hex
mov si, HEXNUMBER
call log

mov cx, 0
mov es, cx ; reset segments



; enable protected mode ready for the kernel
cli                     ; 1. disable interrupts
lgdt [GDT.Pointer]   ; 2. load GDT descriptor
mov eax, cr0
or eax, 0x1             ; 3. enable protected mode
mov cr0, eax
jmp GDT.Code:init_32bit ; 4. far jump

[bits 32]
init_32bit:


mov ax, word GDT.Data        ; 5. update segment registers
mov ds, ax
mov ss, ax
mov es, ax
mov fs, ax
mov gs, ax

mov ebp, 0x90000        ; 6. setup stack
mov esp, ebp

; https://wiki.osdev.org/Setting_Up_Long_Mode#Setting_up_the_Paging
mov edi, 0x1000    ; Set the destination index to 0x1000.
mov cr3, edi       ; Set control register 3 to the destination index.
xor eax, eax       ; Nullify the A-register.
mov ecx, 0x1000      ; repeat write 0x1000 times
rep stosd          ; Clear the memory.
mov edi, cr3       ; Set the destination index to control register 3.


p4_table equ 0x1000
p3_table equ 0x2000
p2_table equ 0x3000
p1_table equ 0x4000



; map first P4 entry to P3 table
mov eax, p3_table
or eax, 0b11 ; present + writable
mov [p4_table], eax

; map first P3 entry to P2 table
mov eax, p2_table
or eax, 0b11 ; present + writable
mov [p3_table], eax

mov ecx, 0         ; counter variable

.map_p2_table:
; map ecx-th P2 entry to a huge page that starts at address 2MiB*ecx
mov eax, 0x200000  ; 2MiB
mul ecx            ; start address of ecx-th page
or eax, 0b10000011 ; present + writable + huge
mov [p2_table + ecx * 8], eax ; map ecx-th entry

inc ecx            ; increase counter
cmp ecx, 512       ; if counter == 512, the whole P2 table is mapped
jne .map_p2_table  ; else map the next entry




mov eax, cr4                 ; Set the A-register to control register 4.
or eax, 1 << 5               ; Set the PAE-bit, which is the 6th bit (bit 5).
mov cr4, eax                 ; Set control register 4 to the A-register.

mov ecx, 0xC0000080          ; Set the C-register to 0xC0000080, which is the EFER MSR.
rdmsr                        ; Read from the model-specific register.
or eax, 1 << 8               ; Set the LM-bit which is the 9th bit (bit 8).
wrmsr                        ; Write to the model-specific register.


mov eax, cr0                 ; Set the A-register to control register 0.
or eax, 1 << 31              ; Set the PG-bit, which is the 31nd bit, and the PM-bit, which is the 0th bit.
mov cr0, eax                 ; Set control register 0 to the A-register.


global enable_long
enable_long:



mov eax, [BOOTSTRAP_START]

mov bx, GDT64.Data

lgdt [GDT64.Pointer]
jmp GDT64.Code:bit64s

bit64s:
[bits 64]

xchg bx, bx ; bochs breakpoint
jmp rax


%include "enable_a20.asm"
.data:
%include "gdt.asm"
MODE32 db `Loading kernel\r\n`, 0
KSIZE db `Kernel size:\r\n`, 0
BSTART db `Kernel boostrap start:\r\n`, 0
KCOUNT db `Successfully read kernel:\r\n`, 0
ENDL db `\r\n`, 0
BOOTSTRAP_START dd 0
KERNEL_SIZE dd 0