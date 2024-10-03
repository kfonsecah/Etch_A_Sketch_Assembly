.model small
.stack 100h

.data
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
    RELLENAR_PANTALLA 08h  ; Color blanco (0Fh)

    ; Dibuja bordes


    ; Dibuja un rectángulo en las coordenadas especificadas
    DIBUJAR_RECTANGULO 550, 90, 60, 300, 0Fh  ; Rectángulo en (375, 90), tamaño 50x300
	DIBUJAR_RECTANGULO 60, 90, 470, 300, 0Fh
    ; Dibuja los cuadrados en las posiciones exactas que tenías
    DIBUJAR_CUADRADO 564, 350, 30, 01h ; Primer cuadrado rojo
    DIBUJAR_CUADRADO 564, 300, 30, 02h ; Segundo cuadrado
    DIBUJAR_CUADRADO 564, 250, 30, 04h ; Tercer cuadrado
    DIBUJAR_CUADRADO 564, 200, 30, 06h ; Cuarto cuadrado
    DIBUJAR_CUADRADO 564, 150, 30, 09h ; Quinto cuadrado
    DIBUJAR_CUADRADO 564, 100, 30, 13h ; Sexto cuadrado

    ; Esperar una tecla indefinidamente (no regresa al modo texto)
  ; Bucle infinito hasta que se presione Esc
bucle_principal:
    mov ah, 01h       ; Verificar si se presionó una tecla
    int 16h           ; Sin esperar
    jz  bucle_principal  ; Si no se presionó tecla, volver al inicio del bucle
    
    mov ah, 00h       ; Leer la tecla presionada
    int 16h
    cmp al, 27        ; Comparar con el código ASCII de Esc (27)
    jne bucle_principal  ; Si no es Esc, volver al inicio del bucle

    ; Si se presionó Esc, salir del bucle y terminar el programa
    mov ah, 4ch
    int 21h
    ; No regresar al modo texto, el programa queda en modo gráfico

end start
