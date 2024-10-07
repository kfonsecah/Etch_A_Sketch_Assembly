.MODEL small
.STACK 100h

.DATA
    color_rojo db 04h  ; Color rojo (dependiendo del modo gráfico)

.CODE

; Macro para dibujar un píxel en la pantalla en modo gráfico
PINTA_PIXEL macro x, y, color
    mov ah, 0Ch         ; Función para dibujar píxel en modo gráfico
    mov al, color       ; Color del píxel
    mov cx, x           ; Coordenada X
    mov dx, y           ; Coordenada Y
    int 10h             ; Llamada a la interrupción BIOS para dibujar el píxel
endm

; Macro para dibujar una línea diagonal de izquierda a derecha (creciente en X e Y)
DIBUJAR_LINEA_DIAGONAL_IZQ_DER macro x_inicial, y_inicial, longitud, color
    local DIAGONAL_LOOP
    mov cx, x_inicial   ; Cargar la coordenada X inicial
    mov dx, y_inicial   ; Cargar la coordenada Y inicial
    mov si, longitud    ; Longitud de la línea diagonal
DIAGONAL_LOOP:
    PINTA_PIXEL cx, dx, color
    inc cx              ; Incrementar X para ir hacia la derecha
    inc dx              ; Incrementar Y para ir hacia abajo
    dec si
    jnz DIAGONAL_LOOP
endm

; Macro para dibujar una línea diagonal de derecha a izquierda (decreciente en X e Y)
DIBUJAR_LINEA_DIAGONAL_DER_IZQ macro x_inicial, y_inicial, longitud, color
    local DIAGONAL_LOOP
    mov cx, x_inicial   ; Cargar la coordenada X inicial
    mov dx, y_inicial   ; Cargar la coordenada Y inicial
    mov si, longitud    ; Longitud de la línea diagonal
DIAGONAL_LOOP:
    PINTA_PIXEL cx, dx, color
    dec cx              ; Decrementar X para ir hacia la izquierda
    inc dx              ; Incrementar Y para ir hacia abajo
    dec si
    jnz DIAGONAL_LOOP
endm

; Macro para dibujar una línea horizontal
DIBUJAR_LINEA_HORIZONTAL macro x_inicial, y, longitud, color
    local HORIZONTAL_LOOP
    mov cx, x_inicial   ; Coordenada X inicial
    mov dx, y           ; Fila fija (coordenada Y)
    mov si, longitud    ; Longitud de la línea horizontal
HORIZONTAL_LOOP:
    PINTA_PIXEL cx, dx, color
    inc cx              ; Moverse a la derecha (aumentar X)
    dec si
    jnz HORIZONTAL_LOOP
endm

start:
    ; Inicializar segmentos de datos
    mov ax, @data
    mov ds, ax

    ; Cambiar a modo gráfico 12h (640x480, 16 colores)
    mov ax, 0012h
    int 10h

    ; Dibujar un triángulo rojo
    ; Lado izquierdo (diagonal de izquierda a derecha)
    DIBUJAR_LINEA_DIAGONAL_IZQ_DER 320, 100, 100, color_rojo  ; Lado izquierdo del triángulo

    ; Lado derecho (diagonal de derecha a izquierda)
    DIBUJAR_LINEA_DIAGONAL_DER_IZQ 420, 100, 100, color_rojo  ; Lado derecho del triángulo

    ; Base del triángulo (línea horizontal)
    DIBUJAR_LINEA_HORIZONTAL 320, 200, 100, color_rojo        ; Base del triángulo

main_loop:
    ; Esperar a que se presione una tecla antes de salir
    mov ah, 00h
    int 16h

    ; Restaurar el modo de texto 03h
    mov ax, 0003h
    int 10h

    ; Terminar el programa
    mov ah, 4Ch
    int 21h

END start
