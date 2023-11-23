[bits 16]
extern log
extern load
extern setboot
extern num2hex
extern HEXNUMBER

xchg bx, bx ; bochs breakpoint

jmp 0000:START

START:
xor ax, ax    ; make sure ds is set to 0
mov ds, ax


mov bp, 0x9000
mov sp, bp

call setboot

mov si, STARTUP
call log
mov si, THANKS
call log

jmp beginload



beginload:


extern SECTORS_TO_READ
mov si, READ
call log
mov eax, SECTORS_TO_READ
call num2hex
mov si, HEXNUMBER
call log
mov si, ENDL
call log

mov cx, 0
mov dh, 0
mov cl, 2  ; start at sector 2. sector 1 was the bootloader
mov al, SECTORS_TO_READ ; amount of kernel sectors to read
mov bx, [PARTTWO]
call load



jmp word [PARTTWO]



STARTUP db `nakOS bootloader\r\n`, 0
READ db `Read bootloader of size: \r\n`, 0
THANKS db `Thank you apollyon\r\n`, 0
PARTTWO dw 0x500
ENDL db `\r\n`, 0