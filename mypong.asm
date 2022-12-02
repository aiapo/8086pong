.model small
.stack 100h
.386
.data
   lose db 'You lose!$'
   win db 'You win!$'
   ply dw 50
   plx dw 5
   boy dw 50
   box dw 315
   ballxorg dw 170
   ballyorg dw 0
   ballx dw 170
   bally dw 0
   ballvx dw 3
   ballvy dw 3
   farx dw 305
   fary dw 200
   score1 dw 0
   score2 dw 0
   PADLEN dw 70
   ball_xmax dw 5
   ball_ymax dw 5
   pxmax dw 10
   bxmax dw 310
   pymax dw 70
   bymax dw 70
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
      mov ax,ballx
      add ax,ballvx
      mov ballx,ax
      mov ax,bally
      add ax,ballvy
      mov bally,ax
      mov ax,ball_xmax
      add ax,ballvx
      mov ball_xmax,ax
      ;mov ax,ball_ymax
      ;add ax,ballvy
      ;mov ball_ymax,ax

      ; check if the ball will hit the left edge
      ; if it does, jump to x small, if it doesn't, jump to check x big
      chxsmall:
         mov ax,ballvx
         mov bx,10
         sub bx,ax
         cmp ballx,bx
         jle xsmall
         jg cxbig

      ; invert x velocity as it hit the left edge
      ; check if ball went above player
      ; if it did, player y is greater than ball y, and jump to p2score
      ; if it didn't, player y is less than/equal to ball y, jump to player up good
      xsmall:
         mov ax,ballvx
         mov bx,-1
         mul bx
         mov ballvx,ax

         mov ax,ply
         mov bx,bally
         add bx,ball_ymax
         cmp ax,bx
         jle pupg
         jg p2score

      ; check if ball went below player
      ; if it did, player y + paddle length is less than ball y, and jump to p2score
      ; if it didn't, pl y + paddle length is greater than/equal to ball y, jump to player down good
      pupg:
         mov ax,ply
         mov bx,bally
         add bx,ball_ymax
         add ax,PADLEN
         cmp ax,bx
         jge pdowg
         jl p2score

      ; increase bot score, reset ball, check if player won or lost
      p2score:
         xor bx,bx                 ; clear bx with XOR
         pbscoresound:
             sound pitchbs+bx, periodbs+bx ; calls sound macro with offset of arrays
             add bx,2                  ; move bx 2 bytes foward
             cmp bx,4                 ; compare bx with 12
             jl pbscoresound                     ; if less than, run L2 again
         inc score2
         ;mov ballx,5
         ;mov bally,12
         mov ax,ballxorg
         mov ballx,ax
         mov ax,ballyorg
         mov bally,ax
         cmp score2,3
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
             cmp bx,2                 ; compare bx with 12
             jl p1hit 

      ; player didn't lose, continue
      notplose:   

      ; check if the ball will hit the right edge
      ; if it does, jump to x big, if it doesn't, jump to check y small
      cxbig:
         mov ax,ballvx
         mov bx,farx
         sub bx,ax
         cmp ballx,bx
         jge xbig
         jl cysmall

      ; invert x velocity as it hit the right edge
      ; check if ball went above bot
      ; if it did, bot y is greater than ball y, and jump to pscore
      ; if it didn't, bot y is less than/equal to ball y, jump to bot up good
      xbig:
         mov ax,ballvx
         mov bx,-1
         mul bx
         mov ballvx,ax

         mov ax,boy
         mov bx,bally
         cmp ax,bx
         jle bupg
         jg p1score

      ; check if ball went below bot
      ; if it did, bot y + paddle length is less than ball y, and jump to p1score
      ; if it didn't, bot y + paddle length is greater than/equal to ball y, jump to bot down good
      bupg:
         mov ax,boy
         mov bx,bally
         add bx,ball_ymax
         add ax,PADLEN
         cmp ax,bx
         jge bdowg
         jl p1score

      ; increase player score, reset ball, check if bot won or lost
      p1score:
             xor bx,bx                 ; clear bx with XOR
         p1scoresound:
             sound pitchp1s+bx, periodp1s+bx ; calls sound macro with offset of arrays
             add bx,2                  ; move bx 2 bytes foward
             cmp bx,4                 ; compare bx with 12
             jl p1scoresound                     ; if less than, run L2 again
         inc score1
         ;mov ballx,315
         ;mov bally,12
         mov ax,ballxorg
         mov ballx,ax
         mov ax,ballyorg
         mov bally,ax
         cmp score1,3
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

      ; bot didn't lose, continue
      notbplose:

      ; check if the ball will hit the top edge
      ; if it does, jump to y small, if it doesn't, jump to check y big
      cysmall:
         mov ax,ballvy
         mov bx,-1
         sub bx,ax
         cmp bally,bx
         jle ysmall
         jg cybig

      ; invert y velocity as it hit the top edge
      ysmall:
         mov ax,ballvy
         mov bx,-1
         mul bx
         mov ballvy,ax

      ; check if the ball will hit the bottom edge
      ; if it does, jump to y big, if it doesn't, jump to finish checking edges
      cybig:
         mov ax,ballvy
         mov bx,fary
         sub bx,ax
         mov cx,ball_ymax
         add cx,bally
         cmp cx,bx
         jge ybig
         jl finedge

      ; invert y velocity as it hit the bottom edge
      ybig:
         mov ax,ballvy
         mov bx,-1
         mul bx
         mov ballvy,ax

      ; finish checking edges for ball, so finished calculating ball position and effects
      finedge:
   endm

   ; draw the ball, including a length
   drwball macro
    mov bh, 0       ; set page number
    mov cx, ballx    ; X (line)
    add cx,5
    mov ball_xmax,cx
    sub cx,5
    
    horizontal:
        mov dx, bally    ; Y (column)
        vertical:
            mov ax, 0C02h  ; write pixel
            int 10h
            inc dx  ; next y
            mov ax,dx
            sub ax,bally
            cmp ax,ball_ymax  ; only draw it to max length
            jng vertical
        inc cx
        cmp cx,ball_xmax
        jbe horizontal
   endm

   ; draw the p1 paddle
   drwpl macro
    mov bh, 0      ; set page number
    mov cx, plx    ; X is fixed for a vertical line
    mov dx,PADLEN
    add dx,ply
    mov pymax,dx
    widthlinel:
        mov dx, ply    ; Y to start
        lengthlinel:
            mov ax, 0C04h ; write red pixel
            int 10h
            inc dx         ; Next Y
            cmp dx, pymax  ; only draw it to max length
            jbe lengthlinel
        inc cx ; Next x
        cmp cx, pxmax
        jbe widthlinel
   endm

   ; draw the p2 paddle
   drwbo macro
    mov bh, 0      ; set page number
    mov cx, box    ; X is fixed for a vertical line
    mov dx,PADLEN
    add dx,boy
    mov bymax,dx

    widthliner:
        mov dx, boy    ; Y to start
        lengthliner:
            mov ax, 0C04h ; write red pixel
            int 10h
            inc dx         ; Next Y
            cmp dx, bymax  ; only draw it to max length
            jbe lengthliner
        dec cx ; Next x
        cmp cx, bxmax
        jge widthliner
   endm

   ; Ai for the bot, will try and correct itself by moving up or down 1 unit per frame,
   ; ball moves at 2 units vertically per frame so it will not always keep up
   movbot macro
      ;mov ax,boy
      ;cmp ax,0
      ;je isminb
      ;mov ax,bymax
      ;cmp ax,170
      ;je ismaxb
      ;botlogic:
      ;mov ax,boy
      ;cmp ax,bally
      ;jl botdown
      ;dec boy
      ;dec bymax
      ;jmp movbote
      ;botdown:
      ;inc boy
      ;inc bymax
      ;jmp movbote
      ;isminb:
      ;  add boy,2
      ;  add bymax,2
      ;  jmp botlogic
      ;ismaxb:
      ;  sub bymax,2
      ;  sub boy,2
      ;  jmp botlogic
      ;movbote:

mov ax,boy
add ax,35
cmp ax, bally
jl incboy
jg decboy
je stayboy
incboy:
   mov ax,boy
   add ax,PADLEN
   cmp ax, 200
   je stayboy
   add boy,2
   add bymax,2
   jmp stayboy
decboy:
   mov ax,boy
   cmp ax,0
   je stayboy
   sub boy,2
   sub bymax,2
   ;jmp stayboy
stayboy:

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
      mov ax,ply
      sub ax,4
      sub pymax,4
      mov ply,ax
      cmp ax,0
      jle ismin
      jmp r
      ismin:
        ;add ax,4
        mov ply,0
        mov pymax,0
      jmp r

   ; move the p1 paddle down, but do not allow it to go below bottom of screen
   down:
      mov ax,ply
      add ax,4
      add pymax,4
      mov ply,ax
      ;mov ax,pymax
      cmp ax,130
      jge ismax
      jmp r
      ismax:
        ;sub ax,4
        mov ply,130
        mov pymax,130
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