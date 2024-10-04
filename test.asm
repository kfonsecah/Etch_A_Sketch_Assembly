.model small
.stack 100h

.data

    current_x dw 320        ; Coordenada X inicial (centro de la pantalla)
    current_y dw 240        ; Coordenada Y inicial (centro de la pantalla)
    color_pixel db 01h 

    POSICION macro x, y
        mov ah, 07h
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

    ; Macro para dibujar un rectángulo con ancho, alto y color
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

    ; Nueva macro para rellenar la pantalla con un color
    RELLENAR_PANTALLA macro color
        MOV DX, 0      ; Empieza en Y = 0
    RELLENAR_FILAS:
        MOV CX, 0      ; Empieza en X = 0
    RELLENAR_COLUMNAS:
        PINTA_PIXEL CX, DX, color  ; Pintar con el color pasado
        INC CX
        CMP CX, 640   ; Hasta la columna 640
        JBE RELLENAR_COLUMNAS
        INC DX
        CMP DX, 480   ; Hasta la fila 480
        JBE RELLENAR_FILAS
    endm
    
    COL dw 50
    FIL dw 50

.code
start:
    ; Establecer el modo gráfico 12h (640x480, 16 colores) sin consola
    MOV AX, 0012h  ; Modo gráfico 12h
    INT 10h        ; Llamada a la interrupción BIOS para cambiar al modo gráfico

    ; Llamar a la nueva macro para rellenar la pantalla con color blanco
    RELLENAR_PANTALLA 08h 

    ; Dibuja bordes

    DIBUJAR_RECTANGULO 60, 50, 360, 30, 0Fh
    DIBUJAR_RECTANGULO 425, 50, 110, 30, 0Fh
    ; Dibuja un rectángulo en las coordenadas especificadas
    DIBUJAR_RECTANGULO 550, 90, 60, 300, 0Fh  
	DIBUJAR_RECTANGULO 136, 90, 398, 300, 0Fh ;Cuadro de dibujo
    DIBUJAR_RECTANGULO 60, 90, 60, 300, 0Fh

 
    DIBUJAR_CUADRADO 564, 350, 30, 01h ; Primer cuadrado rojo
    DIBUJAR_CUADRADO 564, 300, 30, 02h ; Segundo cuadrado
    DIBUJAR_CUADRADO 564, 250, 30, 04h ; Tercer cuadrado
    DIBUJAR_CUADRADO 564, 200, 30, 05h ; Cuarto cuadrado
    DIBUJAR_CUADRADO 564, 150, 30, 06h ; Quinto cuadrado
    DIBUJAR_CUADRADO 564, 100, 30, 07h ; Sexto cuadrado

    DIBUJAR_CUADRADO 75, 350, 30, 08h ; Primer cuadrado rojo
    DIBUJAR_CUADRADO 75, 300, 30, 09h ; Segundo cuadrado
    DIBUJAR_CUADRADO 75, 250, 30, 10h ; Tercer cuadrado
    DIBUJAR_CUADRADO 75, 200, 30, 11h ; Cuarto cuadrado
    DIBUJAR_CUADRADO 75, 150, 30, 0Ah ; Quinto cuadrado
    DIBUJAR_CUADRADO 75, 100, 30, 0Bh ; Sexto cuadrado

    DIBUJAR_CUADRADO 564, 410, 30, 0Fh ;tecla arriba
    DIBUJAR_CUADRADO 564, 445, 30, 0Fh ;tecla ABAJO
    DIBUJAR_CUADRADO 529, 445, 30, 0Fh ;tecla IZQ
    DIBUJAR_CUADRADO 600, 445, 30, 0Fh ;tecla DER


    DIBUJAR_RECTANGULO 60, 400, 100, 30, 0Fh
    DIBUJAR_RECTANGULO 60, 435, 100, 30, 0Fh
    DIBUJAR_RECTANGULO 167, 400, 255, 30, 0Fh;CAMPO TEXTO
    DIBUJAR_RECTANGULO 430, 400, 105, 30, 0Fh;iNSERTAR IMAGEN


    mov ax, [current_x]
    mov dx, [current_y]
    PINTA_PIXEL ax, dx, color_pixel
bucle_principal:
    mov ah, 01h       ; Verificar si se presionó una tecla
    int 16h           ; Sin esperar
    jz  bucle_principal  ; Si no se presionó tecla, volver al inicio del bucle
    
    mov ah, 00h       ; Leer la tecla presionada
    int 16h

    cmp al, 27        ; Comparar con Esc
    je salir          ; Si se presiona Esc, salir del programa

    cmp al, ' '       ; Si se presiona espacio, dibujar un píxel negro
    je dibujar_pixel

    cmp al, 72        ; Flecha arriba
    je mover_arriba

    cmp al, 80        ; Flecha abajo
    je mover_abajo

    cmp al, 75        ; Flecha izquierda
    je mover_izquierda

    cmp al, 77        ; Flecha derecha
    je mover_derecha

    jmp bucle_principal

; Funciones de movimiento
mover_arriba:
    cmp [current_y], 0  ; No exceder el borde superior
    jle bucle_principal
    dec word ptr [current_y]
    jmp bucle_principal

mover_abajo:
    cmp [current_y], 479  ; No exceder el borde inferior
    jge bucle_principal
    inc word ptr [current_y]
    jmp bucle_principal

mover_izquierda:
    cmp [current_x], 0  ; No exceder el borde izquierdo
    jle bucle_principal
    dec word ptr [current_x]
    jmp bucle_principal

mover_derecha:
    cmp [current_x], 639  ; No exceder el borde derecho
    jge bucle_principal
    inc word ptr [current_x]
    jmp bucle_principal

; Dibuja el píxel en la posición actual
dibujar_pixel:
    mov ax, [current_x]
    mov dx, [current_y]
    PINTA_PIXEL ax, dx, color_pixel
    jmp bucle_principal

; Salir del programa
salir:
    mov ah, 4Ch
    int 21h

end start
