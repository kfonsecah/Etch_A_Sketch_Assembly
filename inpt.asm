.MODEL small
.STACK 100h

.DATA
    mouse_x dw 0          ; Coordenada X del mouse
    mouse_y dw 0          ; Coordenada Y del mouse
    mouse_buttons db 0    ; Estado de los botones del mouse
    color_pixel db 1      ; Color por defecto del píxel

.CODE

; Macro para dibujar un píxel en la pantalla en modo gráfico
PINTA_PIXEL macro x, y, color
    mov ah, 0Ch
    mov al, color
    mov bh, 0
    mov cx, x
    mov dx, y
    int 10h
endm

; Inicializar el mouse
INIT_MOUSE PROC
    mov ax, 0               ; Función 0 de la interrupción 33h: inicializar el mouse
    int 33h                 ; Interrupción para interactuar con el mouse
    cmp ax, 0               ; Verificar si el mouse está presente
    je NO_MOUSE             ; Si no está, saltar a la etiqueta de error
    ret

NO_MOUSE:
    ; Si el mouse no está presente, salir al modo texto
    mov ax, 0003h
    int 10h
    mov ah, 4Ch
    int 21h
    ret
INIT_MOUSE ENDP

; Obtener las coordenadas del mouse y el estado de los botones
GET_MOUSE_STATUS PROC
    mov ax, 03h             ; Función 3: Obtener el estado del mouse
    int 33h
    mov [mouse_buttons], bl  ; Almacenar el estado de los botones
    mov [mouse_x], cx        ; Almacenar la coordenada X del mouse
    mov [mouse_y], dx        ; Almacenar la coordenada Y del mouse
    ret
GET_MOUSE_STATUS ENDP

; Dibujar el píxel en la nueva posición del mouse
DIBUJAR_MOUSE_PIXEL PROC
    call GET_MOUSE_STATUS    ; Obtener las coordenadas del mouse

    ; Verificar si el botón izquierdo del mouse fue presionado
    test [mouse_buttons], 1
    jz no_click             ; Si no fue presionado, saltar a no_click

    ; Dibujar el píxel en la nueva posición del mouse
    PINTA_PIXEL [mouse_x], [mouse_y], [color_pixel]

    ; Cambiar el color del píxel cada vez que se haga clic
    inc color_pixel
    cmp color_pixel, 0Fh    ; Limitar el color a 15 (máximo 16 colores en modo 12h)
    jbe continuar
    mov color_pixel, 1      ; Reiniciar el color si sobrepasa el límite

continuar:
    ret

no_click:
    ret
DIBUJAR_MOUSE_PIXEL ENDP

start:
    ; Inicializar segmentos de datos
    mov ax, @data
    mov ds, ax

    ; Cambiar a modo gráfico 12h (640x480, 16 colores)
    mov ax, 0012h
    int 10h

    ; Inicializar el mouse
    call INIT_MOUSE

main_loop:
    call DIBUJAR_MOUSE_PIXEL  ; Dibujar el píxel si hay un clic

    ; Leer la tecla presionada (sin esperar)
    mov ah, 01h               ; Función para verificar si hay tecla presionada
    int 16h
    jz main_loop              ; Si no hay tecla, seguir en el bucle

    mov ah, 00h               ; Leer la tecla presionada
    int 16h

    cmp al, 27       ; Comparar con Esc (código ASCII 27)
    je salir         ; Salir si se presiona Esc

    jmp main_loop    ; Volver al bucle principal

salir:
    ; Restaurar el modo de texto 03h
    mov ax, 0003h
    int 10h
    ; Terminar el programa
    mov ah, 4Ch
    int 21h
END start
