.model small
.stack 100h

.data
	POSICION macro x, y
		mov ah, 02h
		mov bh, 0
		mov dh, y
		mov dl, x
		int 10h
	endm
	
	PINTA_PIXEL macro x, y, color
		mov ah, 0Ch
		mov al, color
		mov bh, 0
		mov cx, x
		mov dx, y
		int 10h
	endm
	
	; Macro para dibujar un cuadrado en cualquier posición con tamaño y color
	DIBUJAR_CUADRADO macro x_inicial, y_inicial, tamano, color
		local FILAS_CUADRADO, COLUMNAS_CUADRADO
	
		mov di, y_inicial
	FILAS_CUADRADO:
		mov si, x_inicial
	COLUMNAS_CUADRADO:
		PINTA_PIXEL si, di, color
		inc si
		cmp si, x_inicial + tamano
		jb COLUMNAS_CUADRADO
		inc di
		cmp di, y_inicial + tamano
		jb FILAS_CUADRADO
	endm
	
	COL dw 50
	FIL dw 50

.code
start:
	MOV AX, @DATA
	MOV DS, AX

	; Modo de video 12h (640x480)
	MOV AH, 0
	MOV AL, 12h
	INT 10h

	; Dibuja bordes
	MOV CX, 590
	MOV DX, 50
BORDES_VERTICALES:
	PINTA_PIXEL 50, DX, 07h  ; Borde izquierdo
	PINTA_PIXEL 590, DX, 07h ; Borde derecho
	INC DX
	CMP DX, 380
	JBE BORDES_VERTICALES

	; Dibuja bordes horizontales
	MOV CX, 590
	MOV DX, 50
BORDES_HORIZONTALES:
	PINTA_PIXEL CX, 50, 07h  ; Borde superior
	PINTA_PIXEL CX, 380, 07h ; Borde inferior
	DEC CX
	CMP CX, 50
	JAE BORDES_HORIZONTALES

	; Rellenar el área interna
	MOV DX, 51     ; Empieza en Y = 51
RELLENAR_FILAS:
	MOV CX, 51     ; Empieza en X = 51
RELLENAR_COLUMNAS:
	PINTA_PIXEL CX, DX, 07h
	INC CX
	CMP CX, 590    ; Hasta la columna 590
	JBE RELLENAR_COLUMNAS
	INC DX
	CMP DX, 380    ; Hasta la fila 380
	JBE RELLENAR_FILAS

	; Dibuja tres cuadrados rojos donde quieras
	DIBUJAR_CUADRADO 100, 400, 30, 04h ; Primer cuadrado rojo en (100, 400) de tamaño 50x50
	DIBUJAR_CUADRADO 150, 400, 30, 01h ; Segundo cuadrado rojo en (200, 400) de tamaño 50x50
	DIBUJAR_CUADRADO 200, 400, 30, 02h ; Tercer cuadrado rojo en (300, 400) de tamaño 50x50

	; Fin del programa
	MOV AH, 4Ch
	INT 21h

end start