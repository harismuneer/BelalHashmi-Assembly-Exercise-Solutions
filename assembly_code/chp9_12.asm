;**************************************************************************************************
;                                         Chapter #9(Q12)
;**************************************************************************************************
; Write a TSR to show a clock in the upper right corner of the screen in the format HH:MM:SS.DD where HH is hours in 24 hour format, MM is minutes, SS is seconds and DD is hundredth of second. 
; HINT: IBM PC uses a Real Time Clock (RTC) chip to keep track of time while switched off. It provides clock and calendar functions through its two I/O ports 70h and 71h. It is used as follows: 
; mov al, <command>
; out 0x70, al ; command byte written at first port 
; jmp D1 ; waste one instruction time 
; D1: in al, 0x71 ; result of command is in AL now 

; Following are few commands: 00 - Get current second, 02 - Get current minute, 04 - Get current hour 
; All numbers returned by RTC are in BCD. E.g. if it is 6:30 the second and third command will return 0x30 and 0x06 respectively in al.




;**************************************************************************************************
;                                         Solution
;**************************************************************************************************

[org 0x0100]

    jmp main
_DD:        dw 0    ;hundredth of second [Note: a single byte is enough, but for easiness I am taking _DD of word type]


; to display a 2-digit number in its hexadecimal notation at
; ith row and jth column of video screen
; print2DigitNum(isPrintColon, column, row, number)
print2DigitNum:
            push        bp
            mov         bp,sp
            pusha

            ; get correct location on screen
            mov         al, 80
            mul         byte [bp + 6]   ;row number
            add         ax, [bp + 8]    ;column number
            shl         ax, 1           ; turn into byte count
            mov         di, ax

            mov         ax, 0xb800
            mov         es, ax       ; points ES to video memory
            mov         ax, [bp+4]   ; load number to be printed in AX
            mov         bx, 16       ; for hexadecimal notation
            mov         cx, 2        ; to count digits in a number (in our case it is 2)

            ; loop to push digits of number to the stack 
            nextDigit:
            mov         dx, 0
            div         bx           ; After divison, remainder=DX, quotient=AX
            add         dl, 0x30     ; add 30h to convert into character
            mov         dh,0x07     ; set attribute
            mov         [es:di], dx
            sub         di, 2
            loop        nextDigit

            ;to print colon at the end of number
            cmp         word [bp + 10], 1
            jne         skipColon
            mov         ax, 0x073A  ; load ':' symbol in ax with normal attribute
            mov         word [es:di + 6], ax

            skipColon:
            popa
            pop         bp
            ret         8   ;4-paramrters are passed into the subroutine
;**************************************************************************************************



; [NOTE: You can make an extra subroutine with the following format:
; output2Digits(col, row, 2DigitNum, command)
; This subroutine will get current 2DigitNum based on the command and print it
; at specific column and row of screen.
; For the sake of simplicity, I am not creating an extra subroutine.]

; subroutine to display clock at upper right corner of the screen
display_clock:
            pusha

            ; print current hours on the screen
            mov         al, 04          ;get current hour
            out         0x70, al        ;commmand byte written at first(0x70) port
            jmp         HWaste          ;waste one instruction time     
            HWaste:
            in          al, 0x71        ;result of command(hours) is in AL now
            push        word 1          ; yes/true, print colon
            push        word 70         ; column number
            push        word 1          ; row number
            xor         dx, dx          ; set DX to 0
            mov         dl, al          ; load AL in DL
            push        dx              ; push number
            call        print2DigitNum  ;print hours on the screen

            ; print current minutes on the screen
            mov         al, 02          ;get current minutes
            out         0x70, al        ;commmand byte written at first(0x70) port
            jmp         MWaste          ;waste one instruction time     
            MWaste:
            in          al, 0x71        ;result of command(hours) is in AL now
            push        word 1          ; yes/true, print colon
            push        word 73         ; column number
            push        word 1          ; row number
            xor         dx, dx          ; set DX to 0
            mov         dl, al          ; load AL in DL
            push        dx              ; push number
            call        print2DigitNum  ;print hours on the screen

            ; print current seconds on the screen
            mov         al, 00          ;get current seconds
            out         0x70, al        ;commmand byte written at first(0x70) port
            jmp         SWaste          ;waste one instruction time     
            SWaste:
            in          al, 0x71        ;result of command(hours) is in AL now
            push        word 1          ; yes/true, print colon
            push        word 76         ; column number
            push        word 1          ; row number
            xor         dx, dx          ; set DX to 0
            mov         dl, al          ; load AL in DL
            push        dx              ; push number
            call        print2DigitNum  ;print hours on the screen

            ; print current seconds on the screen
            mov         al, 00          ;get current seconds
            out         0x70, al        ;commmand byte written at first(0x70) port
            jmp         DWaste          ;waste one instruction time     
            DWaste:
            in          al, 0x71        ;result of command(hours) is in AL now
            push        word 0          ; no/false, print colon
            push        word 79         ; column number
            push        word 1          ; row number
            push        word [cs:_DD]   ; push number
            call        print2DigitNum  ;print hours on the screen

            popa
            ret
;**************************************************************************************************



;[Note: timer is generated for 1024 times per second]
; Interrupt service handler for INT8
timer:
            push        ax
            add         word [cs:_DD], 0x5
            cmp         word [cs:_DD], 90
            jle         skipUpdateDD
            mov         word [cs:_DD], 0

            skipUpdateDD:
            call        display_clock

            mov         al, 0x20
            out         0x20, al        ; send EOI to PIC

            pop         ax
            iret
;**************************************************************************************************



main:
            xor         ax, ax
            mov         es, ax          ; points to IVT table
            ;hook interrupt
            cli
            mov         word [es: 8*4], timer
            mov         word [es: 8*4 + 2], cs
            sti

            mov         dx, main        ; end of resident portion
            add         dx, 15          ; round upto next para
            mov         cl, 4           
            shr         dx, cl          ; divide dx by 16
            mov         ax, 0x3100      ; make it TSR
            int         0x21
;**************************************************************************************************