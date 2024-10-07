.MODEL small
.STACK 100h

.DATA
    current_x dw 320         ; Coordenada X inicial (centro de la pantalla)
    current_y dw 240         ; Coordenada Y inicial (centro de la pantalla)
    color_pixel db 00h  
    mensaje1 db ' Limpiar ', 0  ; Texto 1 a mostrar
    mensaje2 db ' Dibujo sin nombre ', 0  
    mensaje3 db ' Guardar Bosquejo ', 0 
    mensaje4 db ' Cargar Bosquejo ', 0 
    mensaje5 db ' Campo de texto ', 0 
    mensaje6 db ' Insertar imagen ', 0 


; Macro para dibujar un píxel en la pantalla
PINTA_PIXEL macro x, y, color
    mov ah, 0Ch
    mov al, color
    mov bh, 0
    mov cx, x
    mov dx, y
    int 10h
endm

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

   IMPRIMIR_TEXTO macro fila, columna, mensaje, color
    local IMPRIMIR_CADENA, FIN
    mov ah, 02h          ; Función para mover el cursor
    mov bh, 0            ; Página de la pantalla
    mov dh, fila         ; Fila del cursor
    mov dl, columna      ; Columna del cursor
    int 10h              ; Llamar a BIOS para mover el cursor

    lea si, mensaje      ; Cargar la dirección del mensaje
IMPRIMIR_CADENA:
    lodsb                ; Cargar el siguiente carácter en AL
    cmp al, 0            ; Verificar si es el fin de la cadena
    je FIN
    mov ah, 0Eh          ; Función de BIOS para imprimir el carácter
    mov al, al           ; El carácter a imprimir
    mov bl, color        ; Color del texto
    int 10h              ; Llamar a BIOS para mostrar el carácter
    jmp IMPRIMIR_CADENA
FIN:
endm

.CODE
start:
    ; Inicializar segmentos de datos
    mov ax, @data
    mov ds, ax

    ; Cambiar a modo gráfico 12h (640x480, 16 colores)
    mov ax, 0012h
    int 10h

    RELLENAR_PANTALLA 08h 

    ; Dibujar el primer píxel en la posición inicial
   
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
    DIBUJAR_RECTANGULO 430, 400, 105, 30, 0Fh;

    IMPRIMIR_TEXTO  4, 54, mensaje1, 1Fh  ;Limpiar
    IMPRIMIR_TEXTO 4, 20, mensaje2, 2Fh   ;Dibujo sin nombre
    IMPRIMIR_TEXTO  26, 7, mensaje3, 1Fh  ;Guardar Bosquejo
    IMPRIMIR_TEXTO 28, 7, mensaje4, 2Fh  ;Cargar Bosquejo
    IMPRIMIR_TEXTO 26, 28, mensaje5, 2Fh  ;Campo de texto
    IMPRIMIR_TEXTO 26, 54, mensaje6, 2Fh  ;Campo de texto
    


main_loop:
    ; Leer la tecla presionada (sin esperar)
    mov ah, 00h
    int 16h

    ; Comparar las teclas 'W', 'A', 'S', 'D' por sus códigos ASCII
    cmp al, 'w'
    je mover_arriba

    cmp al, 's'
    je mover_abajo

    cmp al, 'a'
    je mover_izquierda

    cmp al, 'd'
    je mover_derecha

    cmp al, 27       ; Comparar con Esc (código ASCII 27)
    je salir         ; Salir si se presiona Esc

    jmp main_loop    ; Volver al bucle principal

; Funciones de movimiento
mover_arriba:
    cmp [current_y], 90         ; Verificar si no se excede el borde superior
    jle main_loop              ; Si está en el borde, no mover más arriba
    dec word ptr [current_y]   ; Mover hacia arriba
    call dibujar_trazo
    jmp main_loop

mover_abajo:
    cmp [current_y], 389       ; Verificar si no se excede el borde inferior
    jge main_loop              ; Si está en el borde, no mover más abajo
    inc word ptr [current_y]   ; Mover hacia abajo
    call dibujar_trazo
    jmp main_loop

mover_izquierda:
    ; Verificar si no se excede el borde izquierdo
    cmp [current_x], 136 ; Comparamos con 1 para evitar que el píxel quede fuera de la pantalla
    jle main_loop
    dec word ptr [current_x] ; Mover hacia la izquierda
    call dibujar_trazo
    jmp main_loop

mover_derecha:
    ; Verificar si no se excede el borde derecho
    cmp [current_x], 533 ; Comparamos con 638 para evitar que el píxel quede fuera de la pantalla
    jge main_loop
    inc word ptr [current_x] ; Mover hacia la derecha
    call dibujar_trazo
    jmp main_loop

; Dibuja el píxel en la nueva posición
dibujar_trazo:
    mov ax, [current_x]        ; Cargar la nueva coordenada X en AX
    mov dx, [current_y]        ; Cargar la nueva coordenada Y en DX
     PINTA_PIXEL [current_x], [current_y], color_pixel ; Llamar a la macro con los valores correctos
    ret

; Salir del programa
salir:
    ; Restaurar el modo de texto 03h
    mov ax, 0003h
    int 10h
    ; Terminar el programa
    mov ah, 4Ch
    int 21h

END start
