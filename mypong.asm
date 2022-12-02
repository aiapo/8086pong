.model small
.stack 100h
.386
.data
   lose db 'You lose!$'
   win db 'You win!$'
   ply db 0
   plx db 0
   boy db 8
   box db 79
   ballx db 10
   bally db 10
   ballvx db 2
   ballvy db 2
   farx db 79
   fary db 25
   score1 db 0
   score2 db 0
   PADLEN db 8
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
      mov ax,0002h
      int 10h
   endm

   ; Calculate the ball position and its effects
   calbll macro
      ; update ball position based on velocity
      mov al,ballx
      add al,ballvx
      mov ballx,al
      mov al,bally
      add al,ballvy
      mov bally,al

      ; check if the ball will hit the left edge
      ; if it does, jump to x small, if it doesn't, jump to check x big
      chxsmall:
         mov al,ballvx
         mov bl,-1
         sub bl,al
         cmp ballx,bl
         jle xsmall
         jg cxbig

      ; invert x velocity as it hit the left edge
      ; check if ball went above player
      ; if it did, player y is greater than ball y, and jump to p2score
      ; if it didn't, player y is less than/equal to ball y, jump to player up good
      xsmall:
         mov al,ballvx
         mov bl,-1
         mul bl
         mov ballvx,al

         mov al,ply
         mov bl,bally
         cmp al,bl
         jle pupg
         jg p2score

      ; check if ball went below player
      ; if it did, player y + paddle length is less than ball y, and jump to p2score
      ; if it didn't, pl y + paddle length is greater than/equal to ball y, jump to player down good
      pupg:
         mov al,ply
         mov bl,bally
         add al,PADLEN
         cmp al,bl
         jge pdowg
         jl p2score

      ; increase bot score, reset ball, check if player won or lost
      p2score:
         inc score2
         mov ballx,40
         mov bally,12
         cmp score2,3
         je plose
         jne notplose

      ; player lost
      plose:
         clrscr
         prtStr lose
         jmp exit

      ; player didn't lose, continue
      notplose:

      ; ball is between player y and player y + paddle length, so the player hit the ball, continue
      pdowg:

      ; check if the ball will hit the right edge
      ; if it does, jump to x big, if it doesn't, jump to check y small
      cxbig:
         mov al,ballvx
         mov bl,farx
         sub bl,al
         cmp ballx,bl
         jge xbig
         jl cysmall

      ; invert x velocity as it hit the right edge
      ; check if ball went above bot
      ; if it did, bot y is greater than ball y, and jump to pscore
      ; if it didn't, bot y is less than/equal to ball y, jump to bot up good
      xbig:
         mov al,ballvx
         mov bl,-1
         mul bl
         mov ballvx,al

         mov al,boy
         mov bl,bally
         cmp al,bl
         jle bupg
         jg p1score

      ; check if ball went below bot
      ; if it did, bot y + paddle length is less than ball y, and jump to p1score
      ; if it didn't, bot y + paddle length is greater than/equal to ball y, jump to bot down good
      bupg:
         mov al,boy
         mov bl,bally
         add al,PADLEN
         cmp al,bl
         jge bdowg
         jl p1score

      ; increase player score, reset ball, check if bot won or lost
      p1score:
         inc score1
         mov ballx,40
         mov bally,12
         cmp score1,3
         je blose
         jne notbplose

      ; bot lost
      blose:
         clrscr
         prtStr win
         jmp exit

      ; bot didn't lose, continue
      notbplose:

      ; ball is between bot y and bot y + paddle length, so the bot hit the ball, continue
      bdowg:

      ; check if the ball will hit the top edge
      ; if it does, jump to y small, if it doesn't, jump to check y big
      cysmall:
         mov al,ballvy
         mov bl,-1
         sub bl,al
         cmp bally,bl
         jle ysmall
         jg cybig

      ; invert y velocity as it hit the top edge
      ysmall:
         mov al,ballvy
         mov bl,-1
         mul bl
         mov ballvy,al

      ; check if the ball will hit the bottom edge
      ; if it does, jump to y big, if it doesn't, jump to finish checking edges
      cybig:
         mov al,ballvy
         mov bl,fary
         sub bl,al
         cmp bally,bl
         jge ybig
         jl finedge

      ; invert y velocity as it hit the bottom edge
      ybig:
         mov al,ballvy
         mov bl,-1
         mul bl
         mov ballvy,al

      ; finish checking edges for ball, so finished calculating ball position and effects
      finedge:
   endm

   drwball macro

   endm
      
   drwpl macro
      
   endm

   drwbo macro
      
   endm

   ; Ai for the bot, will try and correct itself by moving up or down 1 unit per frame,
   ; ball moves at 2 units vertically per frame so it will not always keep up
   movbot macro
      mov al,boy
      cmp al,bally
      jl botdown
      dec boy
      jmp movbote
      botdown:
      inc boy
      movbote:
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
   mov al,0
   mov cx,0001h         ;10 fps
   mov dx,86a0h
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

   up:
      mov al,ply
      sub al,2
      mov ply,al
      jmp r

   down:
      mov al,ply
      add al,2
      mov ply,al
      jmp r

exit:
   mov ah,4ch
   int 21h

exitesc:
   clrScr
   mov ah,4ch
   int 21h

endp
end main