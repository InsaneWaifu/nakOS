[bits 64]
global BOOTSTRAP_START
BOOTSTRAP_START:
mov ax, bx            ; Set the A-register to bx (bootloader leaves the data GDT segment in bx)
mov ds, ax                    ; Set the data segment to the A-register.
mov es, ax                    ; Set the extra segment to the A-register.
mov fs, ax                    ; Set the F-segment to the A-register.
mov gs, ax                    ; Set the G-segment to the A-register.
mov ss, ax                    ; Set the stack segment to the A-register.
mov edi, 0xB8000              ; Set the destination index to 0xB8000.
mov rax, 0x1F201F201F201F20   ; Set the A-register to 0x1F201F201F201F20.
mov ecx, 500                  ; Set the C-register to 500.
rep stosq                     ; Clear the screen.
mov esp, 0x10000
mov [0xb8000], byte 'X'

    mov rax, 0x2f592f412f4b2f4f
    mov qword [0xb8000], rax ; write OKAY to screen

extern BSS_START,BSS_SIZE_DWORDS

; clear bss
lea edi, [BSS_START] 
xor eax, eax ; clear eax
mov ecx, BSS_SIZE_DWORDS
rep stosd





extern _start
call _start
HE db `Hello world`, 0


.bss:

