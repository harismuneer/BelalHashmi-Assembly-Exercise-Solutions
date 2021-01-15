[org 0x0100]

mov ax, 6  ; initialize the accumulator to 6
add ax, 6  ; Adding 6 to ax
add ax, 6  ; Adding 6 to ax
add ax, 6  ; Adding 6 to ax
add ax, 6  ; Adding 6 to ax
add ax, 6  ; Adding 6 to ax
; We only perform the add instruction 6 times because we initialized ax with 6

mov ax, 0x4c00
int 0x21