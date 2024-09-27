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
	MOV DX, 90
BORDES_VERTICALES:
	PINTA_PIXEL 50, DX, 07h  ; Borde izquierdo
	PINTA_PIXEL 500, DX, 07h ; Borde derecho
	INC DX
	CMP DX, 380
	JBE BORDES_VERTICALES

	; Dibuja bordes horizontales
	MOV CX, 500
	MOV DX, 50
BORDES_HORIZONTALES:
	PINTA_PIXEL CX, 90, 07h  ; Borde superior
	PINTA_PIXEL CX, 380, 07h ; Borde inferior
	DEC CX
	CMP CX, 50
	JAE BORDES_HORIZONTALES

	; Rellenar el área interna
	MOV DX, 90     ; Empieza en Y = 51
RELLENAR_FILAS:
	MOV CX, 51     ; Empieza en X = 51
RELLENAR_COLUMNAS:
	PINTA_PIXEL CX, DX, 07h
	INC CX
	CMP CX, 500    ; Hasta la columna 590
	JBE RELLENAR_COLUMNAS
	INC DX
	CMP DX, 380    ; Hasta la fila 380
	JBE RELLENAR_FILAS

	DIBUJAR_RECTANGULO macro x_inicial, y_inicial, ancho, alto, color
		local FILAS_RECTANGULO, COLUMNAS_RECTANGULO
	
		mov di, y_inicial
	FILAS_RECTANGULO:
		mov si, x_inicial
	COLUMNAS_RECTANGULO:
		PINTA_PIXEL si, di, color
		inc si
		cmp si, x_inicial + ancho
		jb COLUMNAS_RECTANGULO
		inc di
		cmp di, y_inicial + alto
		jb FILAS_RECTANGULO
	endm
DIBUJAR_RECTANGULO 3750, 90, 50, 300, 07h 
	; Dibuja tres cuadrados rojos donde quieras
	DIBUJAR_CUADRADO 3760, 350, 30, 01h ; Primer cuadrado rojo en (100, 400) de tamaño 50x50
	DIBUJAR_CUADRADO 3760, 300, 30, 02h
	DIBUJAR_CUADRADO 3760, 250, 30, 04h
	DIBUJAR_CUADRADO 3760, 200, 30, 06h
	DIBUJAR_CUADRADO 3760, 150, 30, 09h
	DIBUJAR_CUADRADO 3760, 100, 30, 13h

	 ; Primer rectángulo con ancho 100 y alto 50

	; Fin del programa
	MOV AH, 4Ch
	INT 21h

end start