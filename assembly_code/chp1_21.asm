; solution developed by https://github.com/DarkShadowFT/


; Write a program in assembly language that calculates the square of 
; six by adding six to the accumulator six times.
[org 0x0100]

mov ax, 6                   ; moves six to the acculumator

add ax, 6                   ; adding six to the acculumator until ax=36
                            ; (or 24 in hex)
add ax, 6
add ax, 6
add ax, 6
add ax, 6

mov ax, 0x4c00              ; exit.
int 0x21
