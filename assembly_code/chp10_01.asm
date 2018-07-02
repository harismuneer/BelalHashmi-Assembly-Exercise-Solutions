; multitasking and dynamic thread registration
[org 0x0100]

jmp start

; PCB layout:
; ax,bx,cx,dx,si,di,bp,sp,ip,cs,ds,ss,es,flags,next,turns
; 0, 2, 4, 6, 8,10,12,14,16,18,20,22,24, 26 , 28 , 30


pcb: 		times 32*16 dw 0 	; space for 32 PCBs
stack: 		times 32*256 dw 0 	; space for 32 512 byte stacks

nextpcb: 	dw 1 				; index of next free pcb
current: 	dw 0 				; index of current pcb
lineno: 	dw 0 				; line number for next thread


temp:		dw 0 				; this is used to store the no. of times the timer interrupt
								; would be called after a particular task will be changed. (It changes from task to task)

flag:		dw 0


count:       dw 20 				; no. of turns a particular process should be given
								; initially it is 20
;--------------------------------------------------------------------------


; subroutine to print a number at top left of screen
; takes the number to be printed as its parameter
printnum: 	push bp
			mov bp, sp

			push es
			push ax
			push bx
			push cx
			push dx
			push di
			
			mov ax, 0xb800
			mov es, ax ; point es to video base

			;Pointing to the desired location on the screen

			mov al, 80			; load al with columns per row
			mul byte [bp+8]		; multiply with y position
			add ax, [bp+6]		;add x position
			shl ax, 1
			mov di, ax
			
			mov ax, [bp+4] 		; load number in ax
			mov bx, 10 			; use base 10 for division
			mov cx, 0 			; initialize count of digits
			
nextdigit: 	mov dx, 0 			; zero upper half of dividend
			div bx 				; divide by 10
			add dl, 0x30 		; convert digit into ascii value
			push dx 			; save ascii value on stack
			inc cx 				; increment count of values
			cmp ax, 0 			; is the quotient zero
			jnz nextdigit 		; if no divide it again


nextpos: 	pop dx 				; remove a digit from the stack
			mov dh, 0x07 		; use normal attribute
			mov [es:di], dx 	; print char on screen
			add di, 2 			; move to next screen location
			loop nextpos 		; repeat for all digits on stack
			
			pop di
			pop dx
			pop cx
			pop bx
			pop ax
			pop es
			pop bp
			ret 6


;--------------------------------------------

;Task whose multiple instances are to be multi-threaded


; mytask subroutine to be run as a thread
; takes line number as parameter
mytask: 	push bp
			mov bp, sp

			sub sp, 2 				; thread local variable

			push ax
			push bx

			mov ax, [bp+4] 			; load line number parameter
			mov bx, 70 				; use column number 70
			mov word [bp-2], 0 		; initialize local variable
			
printagain: push ax 				; line number
			push bx 				; column number
			push word [bp-2] 		; number to be printed
			call printnum 			; print the number
			inc word [bp-2] 		; increment the local variable
			jmp printagain 			; infinitely print
			
			pop bx
			pop ax
			mov sp, bp
			pop bp
			ret 2 					; Even though the function will never return, because it is in an infinite loop. 

			
;-----------------------------------------------------------------------------			
			
;Initializer (KERNEL)

; subroutine to register a new thread
; takes the segment, offset of the thread routine and a parameter
; for the target thread subroutine

initpcb: push bp
		 mov bp, sp
		 push ax
		 push bx
		 push cx
		 push si

		 mov bx, [nextpcb]  ; read next available pcb index
		 cmp bx, 32 		; are all PCBs used
		 je exit 			; yes, exit


		 mov cl, 5
		 shl bx, cl ; multiply by 32 for pcb start


		 ;No. of turns this proccess should be given
		 mov ax, [count]
		 mov word [pcb+bx+30], ax
		 add word [count], 5

		 mov ax, [bp+8] 				; read segment parameter
		 mov [pcb+bx+18], ax			; save in pcb space for cs
		 mov ax, [bp+6] 				; read offset parameter
		 mov [pcb+bx+16], ax	 		; save in pcb space for ip

		 mov [pcb+bx+22], ds 			; set stack to our segment
		 mov si, [nextpcb] 				; read this pcb index
		 mov cl, 9
		 shl si, cl 					; multiply by 512 bytes
		 add si, 256*2+stack 			; end of stack for this thread
		 mov ax, [bp+4] 				; read parameter for subroutine
		 sub si, 2 						; decrement thread stack pointer
		 mov [si], ax 					; pushing parameter on thread stack
		 sub si, 2 						; space for return address

		 mov [pcb+bx+14], si 			; save si in pcb space for sp

		 mov word [pcb+bx+26], 0x0200 	; initialize thread flags



		 ;Code which updates the execution list and adds the new thread in the list

		 mov ax, [pcb+28] 				; read next of 0th thread in ax
		 mov [pcb+bx+28], ax 			; set as next of new thread
		 mov ax, [nextpcb] 				; read new thread index
		 mov [pcb+28], ax 				; set as next of 0th thread

		 inc word [nextpcb] 			; this pcb is now used
		 
exit: 	 pop si
		 pop cx
		 pop bx
		 pop ax
		 pop bp
		 ret 6

		 
;-----------------------------------------------------------------------------

;Scheduler
		 
; timer interrupt service routine
timer:	push ds
		push bx

		push cs
		pop  ds 						; initialize ds to data segment

		mov bx, [current] 				; read index of current in bx

		shl bx, 1
		shl bx, 1
		shl bx, 1
		shl bx, 1
		shl bx, 1 						; multiply by 32 for pcb start


		cmp word [flag], 1
		jz checkCount

		push ax
		mov word [flag], 1
		mov ax, [pcb+bx+30] 			; saving the count of that particular task in a temp variable
		mov word [temp], ax
		pop ax 



checkCount:		cmp word [pcb+bx+30], 0
				jz changeTask			; if pcb+bx+30 has become zero then change the task otherwise just decrement pcb+bx+30
										; and run the same task 

				dec word [pcb+bx+30]

				pop bx
				pop ds 

				push ax
				mov al, 0x20 			; send EOI
				out 0x20, al
				pop ax

				iret 
		

changeTask:		push ax
				mov ax , [temp]
				mov [pcb+bx+30], ax
				mov word [temp], 0
				mov word [flag], 0
				pop ax 


				;Saving the current task's states
	
				mov [pcb+bx+0], ax				; save ax in current pcb
				mov [pcb+bx+4], cx				; save cx in current pcb
				mov [pcb+bx+6], dx 				; save dx in current pcb
				mov [pcb+bx+8], si 				; save si in current pcb
				mov [pcb+bx+10], di 			; save di in current pcb
				mov [pcb+bx+12], bp 			; save bp in current pcb
				mov [pcb+bx+24], es 			; save es in current pcb


				pop ax 							; read original bx from stack
				mov [pcb+bx+2], ax 				; save bx in current pcb
				pop ax 							; read original ds from stack
				mov [pcb+bx+20], ax  			; save ds in current pcb
				pop ax  						; read original ip from stack
				mov [pcb+bx+16], ax  			; save ip in current pcb
				pop ax  						; read original cs from stack
				mov [pcb+bx+18], ax  			; save cs in current pcb
				pop ax  						; read original flags from stack
				mov [pcb+bx+26], ax 			; save flags in current pcb

				mov [pcb+bx+22], ss 			; save ss in current pcb
				mov [pcb+bx+14], sp 			; save sp in current pcb


				mov bx, [pcb+bx+28] 			; read next pcb of this pcb
				mov [current], bx 				; update current to new pcb


				mov cl, 5
				shl bx, cl ; multiply by 32 for pcb start


				;Restoring the new task's state

				mov cx, [pcb+bx+4] 				; read cx of new process
				mov dx, [pcb+bx+6]  			; read dx of new process
				mov si, [pcb+bx+8]  			; read si of new process
				mov di, [pcb+bx+10]  			; read di of new process

				mov bp, [pcb+bx+12] 			; read bp of new process
				mov es, [pcb+bx+24]  			; read es of new process
				mov ss, [pcb+bx+22]  			; read ss of new process
				mov sp, [pcb+bx+14]  			; read sp of new process

				;Re-directing timer to new task 
				push word [pcb+bx+26] 			; push flags of new process
				push word [pcb+bx+18]  			; push cs of new process
				push word [pcb+bx+16]  			; push ip of new process

				push word [pcb+bx+20]  			; push ds of new process

				mov al, 0x20
				out 0x20, al ; send EOI to PIC

				mov ax, [pcb+bx+0] 				; read ax of new process
				mov bx, [pcb+bx+2] 				; read bx of new process

				pop ds 							; read ds of new process
		
				iret 							; return to new process
		
	

;-----------------------------------------------------------------------------
	



start:  xor ax, ax
	    mov es, ax ; point es to IVT base
	   
	    cli
	    mov word [es:8*4], timer
	    mov [es:8*4+2], cs ; hook timer interrupt
	    sti
	   

nextkey: 	xor ah, ah  ; service 0 – get keystroke
	     	int 0x16 	; bios keyboard services

	     	;After every key press, initialize a new task

	     	;Passing three things to the Initializer : CS, IP , Parameter

	     	push cs 			; use current code segment
	     	mov ax, mytask
	     	push ax 			; use mytask as offset
	     	push word [lineno]	; thread parameter

	     	call initpcb 		; register the thread

	     	inc word [lineno] 	; update line number
		 
	     	jmp nextkey 		; wait for next keypress
		 
		 
		 