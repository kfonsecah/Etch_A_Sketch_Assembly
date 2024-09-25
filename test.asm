.model small

.stack 100h

.data


    txt db "Hola",13,10, "$" ;variable de tipo byte, dw variable de 16 bits

   
    POSICION macro x,y
	  mov ah,02h
	  mov bh,0
	  mov dh, x
	  mov dl,y
	  int 10h
    endm
	
	PINTA_PIXEL macro x,y
	  	MOV AH, 0CH
		MOV AL, 04H
		MOV BH, 00
		MOV CX, X
		MOV DX, Y
		INT 10H
    endm
		
	COL DW 50
	FIL DW 50

.code

start:
	MOV AX,@DATA
	MOV DS,AX
   
	MOV CX, 10
	CMP CX, 10
	JE NADA
	  ;CODIGO
	NADA:
   
    MOV AH, 00
	MOV AL, 12H
	INT 10H
	
	CALL CLEAN
	
	MOV CX, 540
	CICLITO:
		PUSH CX
		PINTA_PIXEL COL, 50
		PINTA_PIXEL COL, 380
		INC COL ; ADD COL, 1		
		POP CX
	LOOP CICLITO

	MOV CX, 331
	CICLOTE:
		PUSH CX
		PINTA_PIXEL 50, FIL
		PINTA_PIXEL 590, FIL
		INC FIL 		
		POP CX
	LOOP CICLOTE
	
	;POSICION 12,38
	;MOV CX, 1
	;SALTITO:
	;	MOV AH, 09H
	;	LEA DX, TXT
	;	INT 21H
	;LOOP SALTITO
   
	MOV AH, 4CH
	INT 21H


   clean proc
	mov ax,0700h 
	mov bh,83h ; primer digito color de fondo/ segundo digito color de letra
	mov cx, 0h
	mov dx,1F4fh
	int 10h
	ret
  clean endp
  
end start