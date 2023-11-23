[bits 16]
extern log

global setboot
setboot:
mov [BOOT_DRIVE], dl
ret


num2char:
mov dx, 0x30 ; ascii number start
cmp ax, 0x9
jbe done
mov dx, 0x37
done:
add ax, dx
ret


global num2hex
num2hex: ;num in ax
pusha

mov cx, ax
mov bx, HEXNUMBER

shr ax, 12
call num2char
mov  [bx], al
mov ax, cx
shr ax, 8
and ax, 0xf
inc bx
call num2char
mov [bx], al
mov ax, cx
shr ax, 4
and ax, 0xf
inc bx
call num2char
mov [bx], al
mov ax, cx
and ax, 0xf
inc bx
call num2char
mov [bx], al
inc bx
mov [bx], byte 0
popa
ret



global load






; input:
; ch - cylinder to read from
; cl - sector to start read from
; dh - head to read from
; al - number of sectors to read
; es:bx - where to put stuff

; debug logs:
; bx
; ax
; cx
load:
pusha
mov dl, [BOOT_DRIVE]
push ax


xchg ax,bx
call num2hex
mov si, HEXNUMBER
call log
mov si, ENDL
call log
xchg ax,bx

call num2hex
mov si, HEXNUMBER
call log
mov si, ENDL
call log
xchg ax, cx
call num2hex
mov si, HEXNUMBER
call log
mov si, ENDL
call log
xchg ax, cx


mov ah, 0x02 ; magic number read from disk


int 0x13 ; call bios

jnc nocrash1 ; carry bit set on fail
mov si, EREAD
call log
jmp crash
nocrash1:

pop dx

cmp al, dl ; bios sets al to no of sectors read. if not 2, crash
je nocrash2
mov si, NOTENOUGH
call log

call num2hex
mov si, HEXNUMBER
call log
mov si, ENDL
call log

xchg ax,dx

call num2hex
mov si, HEXNUMBER
call log
mov si, ENDL
call log

xchg ax,dx

jmp crash

nocrash2:
popa
ret








global crash


crash:
nop
mov si, CRASH
call log

jmp $
global HEXNUMBER
BOOT_DRIVE db 0
CRASH db `Failed to load kernel\r\n`, 0
HEXNUMBER dw 0, 0, 0
EREAD db `Read failed\r\n`, 0
NOTENOUGH db `Read too little sectors\r\n`, 0
ENDL db `\r\n`, 0