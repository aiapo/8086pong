.model small
.stack 100h
.386
.data
	lose db 'You lose!$'
	win db 'You win!$'

	pl_y dw 50
	pl_ymax dw 120
	pl_x dw 5
	pl_xmax dw 10
	bot_y dw 50
	bot_x dw 310
	bot_ymax dw 70
	bot_xmax dw 315
	PADLEN dw 70

	ball_xorg dw 170
	ball_yorg dw 0
	ball_vxorg dw 3
	ball_vyorg dw 2
	ball_y dw 0
	ball_ymax dw 5
	ball_x dw 170
	ball_xmax dw 5
	ball_vx dw 3
	ball_vy dw 2
	farx dw 310     ;310 = bot paddle left side
	fary dw 200

	pl_score dw 0
	bot_score dw 0

	pitchp1s dw 3043,2280
	periodp1s dw 2,2
	pitchbs dw 1000,2280
	periodbs dw 2,2
	pitchh dw 4560
	periodh dw 0
.code
main proc
	mov ax,@data
	mov ds,ax

	prtStr macro X
		mov dx, offset X
		mov ah, 09h
		int 21h	
	endm

	clrScr macro
		mov ah,00h          ; set video mode
		mov al,0dh          ; 16 color graphics
		int 10h             ; do it now

		mov ah,0bh          ; set palette
		mov bh,00h          ; set background
		mov bl,00h          ; to black
		int 10h             ; do it now
	endm

	sound macro freq,duration
		mov al, 182         ; Prepare the speaker for the
		out 43h, al         ; note.

		mov ax,freq			; Frequency number (in decimal)for middle C.
		out 42h, al         ; Output low byte.
		mov al, ah          ; Output high byte.
		out 42h, al

		in  al, 61h         ; Turn on note (get value from port 61h).
		or  al, 00000011b   ; Set bits 1 and 0.
		out 61h, al         ; Send new value.

		mov cx,duration		; Pause for duration of note.
		mov dx,0fffh
		mov ah,86h			; CX:DX = how long pause is? I'm not sure exactly how it works but it's working
		int 15h				; Pause for duration of note.

		in  al, 61h         ; Turn off note (get value from
								;  port 61h).
		and al, 11111100b   ; Reset bits 1 and 0.
		out 61h, al         ; Send new value.

		mov cx,01h			;Pause to give the notes some separation
		mov dx,08h
		mov ah,86h
		int 15h
	endm

	; Calculate the ball position and its effects
	calbll macro
		; update ball position based on velocity
		mov ax,ball_x
		add ax,ball_vx
		mov ball_x,ax
		mov ax,ball_y
		add ax,ball_vy
		mov ball_y,ax

		; check if the ball will hit the left edge
		; if it does, jump to x small, if it doesn't, jump to check x big
		chxsmall:
			mov ax,ball_vx
			mov bx,10
			sub bx,ax
			cmp ball_x,bx
			jle xsmall
			jg cxbig

		; invert x velocity as it hit the left edge
		; check if ball went above player
		; if it did, player y is greater than ball y, and jump to botscore
		; if it didn't, player y is less than/equal to ball y, jump to player up good
		xsmall:
			neg ball_vx

			mov ax,pl_y
			mov bx,ball_y
			add bx,ball_ymax
			cmp ax,bx
			jle pupg
			jg botscore

		; check if ball went below player
		; if it did, player y + paddle length is less than ball y, and jump to botscore
		; if it didn't, pl y + paddle length is greater than/equal to ball y, jump to player down good
		pupg:
			mov ax,pl_y
			mov bx,ball_y
			add ax,PADLEN
			cmp ax,bx
			jge pdowg
			jl botscore

		; increase bot score, reset ball, check if player won or lost
		botscore:
			xor bx,bx                 ; clear bx with XOR
			botscoresound:
				sound pitchbs+bx, periodbs+bx ; calls sound macro with offset of arrays
				add bx,2                  ; move bx 2 bytes foward
				cmp bx,4                 ; compare bx with 12
				jl botscoresound                     ; if less than, run L2 again
			inc bot_score
			mov ax,ball_xorg
			mov ball_x,ax
			mov ax,ball_yorg
			mov ball_y,ax
			mov ax,ball_vxorg
			mov ball_vx,ax
			mov ax,ball_vyorg
			mov ball_vy,ax
			cmp bot_score,3
			je plose
			jne notplose

		; player lost
		plose:
			mov ax,0002h          ; screen clear operation
			int 10h               ; BIOS interrupt, look at ax register
			prtStr lose
			jmp exit

		; ball is between player y and player y + paddle length, so the player hit the ball, continue
		pdowg:
			xor bx,bx
			p1hit:
				sound pitchh+bx, periodh+bx ; calls sound macro with offset of arrays
				add bx,2                  ; move bx 2 bytes foward
				cmp bx,2                 ; compare bx with 2
				jl p1hit
			; velocity manipulation based on hit position
			mov ax,ball_y
			mov bx,pl_y
			mov cx,pl_ymax
			; adjust edge "zone", top of paddle and bottom of paddle
			cmp ax,bx    ; if ball y position is the same as the top of paddle
			je edgep     ; then jump to edge label
			cmp ax,cx    ; if ball y position is the same as bottom of paddle
			je edgep     ; then jump to edge label
			add bx,cx    ; add the total position of paddle
			mov bx,2     ; divide by two to find the middle
			cmp ball_y,ax ; if ball y position is the same as the middle of the paddle
			je middlep   ; jump to middle label
			; adjust middle "zone", one above and one bellow middle
			add ax,1     ; add one to middle
			cmp ball_y,ax ; if ball y position is the same as middle+1 of paddle
			je middlep   ; jump to middle label
			sub ax,2     ; subtact 1 from middle (2 because added 1)
			cmp ball_y,ax ; if ball y position is the same as middle-1 of paddle
			je middlep   ; jump to middle label
			jmp endmodp  ; if not then leave the velocity alone
			middlep:
				inc ball_vy  ; increase velocity by 1
				jmp endmodp ; go to end
			edgep:
				dec ball_vy  ; decrease velocity by 1
			endmodp:

		; player didn't lose, continue
		notplose:   

		; check if the ball will hit the right edge
		; if it does, jump to x big, if it doesn't, jump to check y small
		cxbig:
			mov ax,ball_vx
			mov bx,farx
			sub bx,ax
			mov cx,ball_xmax
			cmp cx,bx
			jge xbig
			jl cysmall

		; invert x velocity as it hit the right edge
		; check if ball went above bot
		; if it did, bot y is greater than ball y, and jump to plscore
		; if it didn't, bot y is less than/equal to ball y, jump to bot up good
		xbig:
			neg ball_vx

			mov ax,bot_y
			mov bx,ball_y
			add bx,ball_ymax
			cmp ax,bx
			jle bupg
			jg plscore

		; check if ball went below bot
		; if it did, bot y + paddle length is less than ball y, and jump to plscore
		; if it didn't, bot y + paddle length is greater than/equal to ball y, jump to bot down good
		bupg:
			mov ax,bot_y
			mov bx,ball_y
			add ax,PADLEN
			cmp ax,bx
			jge bdowg
			jl plscore

		; increase player score, reset ball, check if bot won or lost
		plscore:
            xor bx,bx                 ; clear bx with XOR
			plscoresound:
				sound pitchp1s+bx, periodp1s+bx ; calls sound macro with offset of arrays
				add bx,2                  ; move bx 2 bytes foward
				cmp bx,4                 ; compare bx with 12
				jl plscoresound                     ; if less than, run L2 again
			inc pl_score
			mov ax,ball_xorg
			mov ball_x,ax
			mov ax,ball_yorg
			mov ball_y,ax
			mov ax,ball_vyorg
			neg ax
			mov ball_vx,ax
			mov ax,ball_vyorg
			mov ball_vy,ax
			cmp pl_score,3
			je blose
			jne notbplose

		; bot lost
		blose:
			mov ax,0002h          ; screen clear operation
			int 10h               ; BIOS interrupt, look at ax register
			prtStr win
			jmp exit

		; ball is between bot y and bot y + paddle length, so the bot hit the ball, continue
		bdowg:
			xor bx,bx
			p2hit:
				sound pitchh+bx, periodh+bx ; calls sound macro with offset of arrays
				add bx,2                  ; move bx 2 bytes foward
				cmp bx,2                 ; compare bx with 12
				jl p2hit

			; disabled the bot velocity manipulation for now, try it out and see if it needs to be adjusted
			jmp endmodb
			; velocity manipulation based on hit position
			mov ax,ball_y ; put ball y position in ax
			mov bx,bot_y   ; put paddle y position in bx
			mov cx,bot_ymax ; put paddle max y in bx
			; adjust edge "zone", top of paddle and bottom of paddle
			cmp ax,bx    ; if ball y position is the same as the top of paddle
			je edgeb     ; then jump to edge label
			cmp ax,cx    ; if ball y position is the same as bottom of paddle
			je edgeb     ; then jump to edge label
			add bx,cx    ; add the total position of paddle
			mov bx,2     ; divide by two to find the middle
			cmp ball_y,ax ; if ball y position is the same as the middle of the paddle
			je middleb   ; jump to middle label
			; adjust middle "zone", one above and one bellow middle
			add ax,1     ; add one to middle
			cmp ball_y,ax ; if ball y position is the same as middle+1 of paddle
			je middleb   ; jump to middle label
			sub ax,2     ; subtact 1 from middle (2 because added 1)
			cmp ball_y,ax ; if ball y position is the same as middle-1 of paddle
			je middleb   ; jump to middle label
			jmp endmodb  ; if not then leave the velocity alone
			middleb:
				inc ball_vy  ; increase velocity by 1
				jmp endmodb ; go to end
			edgeb:
				dec ball_vy  ; decrease velocity by 1
			endmodb:

		; bot didn't lose, continue
		notbplose:

		; check if the ball will hit the top edge
		; if it does, jump to y small, if it doesn't, jump to check y big
		cysmall:
			mov ax,ball_vy
			mov bx,-1
			sub bx,ax
			cmp ball_y,bx
			jle ysmall
			jg cybig

		; invert y velocity as it hit the top edge
		ysmall:
			neg ball_vy

		; check if the ball will hit the bottom edge
		; if it does, jump to y big, if it doesn't, jump to finish checking edges
		cybig:
			mov ax,ball_vy
			mov bx,fary
			sub bx,ax
			mov cx,ball_ymax
			add cx,ball_y
			cmp cx,bx
			jge ybig
			jl finedge

		; invert y velocity as it hit the bottom edge
		ybig:
			neg ball_vy

		; finish checking edges for ball, so finished calculating ball position and effects
		finedge:
	endm

	; draw the ball, including a length
	drwball macro
	mov bh, 0       ; set page number
    mov cx, ball_x    ; X (line)
    add cx,5
    mov ball_xmax,cx
    sub cx,5
    
    horizontal:
        mov dx, ball_y    ; Y (column)
        vertical:
            mov ax, 0C02h  ; write pixel
            int 10h
            inc dx  ; next y
            mov ax,dx
            sub ax,ball_y
            cmp ax,ball_ymax  ; only draw it to max length
            jng vertical
		inc cx
        cmp cx,ball_xmax
        jbe horizontal
	endm

	; draw the pl paddle
	drwpl macro
		mov bh, 0      ; set page number
		mov cx, pl_x    ; X is fixed for a vertical line
		mov dx,PADLEN
		add dx,pl_y
		mov pl_ymax,dx
		widthlinepl:
			mov dx, pl_y    ; Y to start
			lengthlinepl:
				mov ax, 0C04h ; write red pixel
				int 10h
				inc dx         ; Next Y
				cmp dx, pl_ymax  ; only draw it to max length
				jbe lengthlinepl
			inc cx ; Next x
			cmp cx, pl_xmax
			jbe widthlinepl
	endm

	; draw the p2 paddle
	drwbo macro
		mov bh, 0      ; set page number
		mov cx, bot_x    ; X is fixed for a vertical line
		mov dx,PADLEN
		add dx,bot_y
		mov bot_ymax,dx

		widthlinebot:
			mov dx, bot_y    ; Y to start
			lengthlinebot:
				mov ax, 0C04h ; write red pixel
				int 10h
				inc dx         ; Next Y
				cmp dx, bot_ymax  ; only draw it to max length
				jbe lengthlinebot
			inc cx ; Next x
			cmp cx, bot_xmax
			jbe widthlinebot
	endm

	; Ai for the bot, will try and correct itself by moving up or down 1 unit per frame,
	; ball moves at 2 units vertically per frame so it will not always keep up
	movbot macro
		mov ax,bot_y
		mov bx,PADLEN
		shr bx,1
		add ax,bx
		cmp ax, ball_y
		jl incbot_y
		jg decbot_y
		je staybot_y
		incbot_y:
			mov ax,bot_y
			add ax,PADLEN
			cmp ax, 200
			je staybot_y
			add bot_y,2
			add bot_ymax,2
			jmp staybot_y
		decbot_y:
			mov ax,bot_y
			cmp ax,0
			je staybot_y
			sub bot_y,2
			sub bot_ymax,2
		staybot_y:
	endm

	; r is the run loop, which runs each frame. it draws, has a wait,
	; updates player and ball positions, and handles keyboard input
	r:
		; calculate the ball position based on its velocity,
		; if it touches the edge, bounce,
		; if it touches player edge, reset and give point to bot,
		; if it touches bot edge, reset and give point to player
		calbll

		; draw to the screen
		clrScr
		drwball
		drwpl
		drwbo

		; create a time delay, which uses the concatenation of cx and dx in microseconds in hex,
		; e.g., 186a0 is 100,000 microseconds, or 0.1 seconds, or 10 fps

		;mov cx,0001h        ;16 fps
		;mov dx,0e848h
		;mov cx,0000h        ;30 fps
		;mov dx,8235h
		;mov cx,0000h        ;24 fps
		;mov dx,0a2c2h
		;mov cx,0000h        ;20 fps
		;mov dx,0c350h
		;mov cx,0001h        ;10 fps
		;mov dx,86a0h
		mov cx,0000h        ;60 fps
		mov dx,411ah

		mov al,0
		mov ah,86h
		int 15h

		; update the bot player position
		movbot

		; check if the player pressed a key,
		; if they did not press a key, then do the run loop again,
		; if they did press a key, determine what key they pressed,
		; ah = scanner, al = ascii character,
		; e.g., 48h in ah = up arrow, 1bh in al = ascii for ESC
		mov ah,01h
		int 16h
		jz r
		mov ah, 00h
		int 16h

		; Up arrow key
		cmp ah, 48h
		je up

		; Down arrow key
		cmp ah, 50h
		je down

		; Escape key
		cmp al, 1bh
		je exitesc

		; W key
		cmp al, 77h
		je up

		; S key
		cmp al, 73h
		je down

		; if they did not press a movement key or ESC, then do the run loop again
		jmp r

		; move the p1 paddle up, but do not allow it to go past the top of screen
		up:
			mov ax,pl_y
			sub ax,4
			sub pl_ymax,4
			mov pl_y,ax
			cmp ax,0
			jle ismin
			jmp r
			ismin:
				;add ax,4
				mov pl_y,0
				mov pl_ymax,0
				jmp r

		; move the p1 paddle down, but do not allow it to go below bottom of screen
		down:
			mov ax,pl_y
			add ax,4
			add pl_ymax,4
			mov pl_y,ax
			;mov ax,pl_ymax
			cmp ax,130
			jge ismax
			jmp r
			ismax:
				;sub ax,4
				mov pl_y,130
				mov pl_ymax,130
				jmp r

	exit:
		mov ah,4ch
		int 21h

	exitesc:
		mov ax,0002h          ; screen clear operation
		int 10h               ; BIOS interrupt, look at ax register
		mov ah,4ch
		int 21h

endp
end main