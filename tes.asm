.MODEL small
.STACK 100h

.DATA
    current_x dw 320         ; Coordenada X inicial (centro de la pantalla)
    current_y dw 240         ; Coordenada Y inicial (centro de la pantalla)
    color_pixel db 0Ah       ; Color del píxel (blanco)

; Macro para dibujar un píxel en la pantalla
PINTA_PIXEL macro x, y, color
    mov ah, 0Ch
    mov al, color
    mov bh, 0
    mov cx, x
    mov dx, y
    int 10h
endm

.CODE
start:
    ; Inicializar segmentos de datos
    mov ax, @data
    mov ds, ax

    ; Cambiar a modo gráfico 12h (640x480, 16 colores)
    mov ax, 0012h
    int 10h

    ; Dibujar el primer píxel en la posición inicial
    call dibujar_trazo

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
    cmp [current_y], 0         ; Verificar si no se excede el borde superior
    jle main_loop              ; Si está en el borde, no mover más arriba
    dec word ptr [current_y]   ; Mover hacia arriba
    call dibujar_trazo
    jmp main_loop

mover_abajo:
    cmp [current_y], 479       ; Verificar si no se excede el borde inferior
    jge main_loop              ; Si está en el borde, no mover más abajo
    inc word ptr [current_y]   ; Mover hacia abajo
    call dibujar_trazo
    jmp main_loop

mover_izquierda:
    ; Verificar si no se excede el borde izquierdo
    cmp [current_x], 1 ; Comparamos con 1 para evitar que el píxel quede fuera de la pantalla
    jle main_loop
    dec word ptr [current_x] ; Mover hacia la izquierda
    call dibujar_trazo
    jmp main_loop

mover_derecha:
    ; Verificar si no se excede el borde derecho
    cmp [current_x], 638 ; Comparamos con 638 para evitar que el píxel quede fuera de la pantalla
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
