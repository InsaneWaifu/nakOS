global log
[bits 16]
log:
pusha
loopstart:
    lodsb       ; Load the character within the AL register, and increment SI
    cmp al, 0   ; Is the AL register a null byte?
    je .done     ; return
    mov ah, 0x0e
    int 0x10    ; Trigger video services interrupt
    jmp loopstart 
.done:
popa
    ret