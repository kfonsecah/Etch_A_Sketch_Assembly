.model small
.stack 100h

.data
    xPos dw 160        ; Posición X inicial (centro de la pantalla)
    yPos dw 100        ; Posición Y inicial (centro de la pantalla)

.code
start:
    mov ax, @data
    mov ds, ax

    ; Cambiar al modo gráfico 13h (320x200, 256 colores)
    mov ax, 13h
    int 10h

draw_square:
    ; Dibujar un cuadrado 6x6 en la posición actual
    mov ax, 0A000h             ; Segmento de la memoria de video
    mov es, ax

    mov dx, [yPos]             ; Cargar Y inicial en DX
    mov cx, 6                  ; Establecer el número de filas (6)

draw_row:
    push cx                    ; Guardar el contador de filas
    mov bx, [xPos]             ; Cargar X inicial en BX
    mov cx, 6                  ; Establecer el número de columnas (6)

draw_column:
    ; Calcular la dirección de memoria de video
    mov ax, dx                 ; Cargar Y actual en AX
    mov di, 320                ; El ancho de la pantalla es 320
    mul di                     ; Y * 320
    add ax, bx                 ; Sumar la posición X
    mov di, ax                 ; Guardar el resultado en DI

    ; Dibujar un píxel rojo (índice 4 en la paleta VGA)
    mov al, 4                  ; Color rojo
    stosb                      ; Dibujar el píxel

    inc bx                     ; Avanzar a la siguiente columna (X)
    dec cx                     ; Reducir el contador de columnas
    jnz draw_column            ; Si no hemos terminado, repetir

    ; Avanzar a la siguiente fila
    inc dx                     ; Incrementar la posición Y (siguiente fila)
    pop cx                     ; Restaurar el contador de filas
    dec cx                     ; Reducir el contador de filas
    jnz draw_row               ; Si no hemos terminado, repetir

    ; Esperar para redibujar
    jmp wait_key

wait_key:
    ; Esperar una tecla
    mov ah, 00h
    int 16h

    ; Verificar qué tecla fue presionada
    cmp al, 'w'
    je move_up
    cmp al, 's'
    je move_down
    cmp al, 'a'
    je move_left
    cmp al, 'd'
    je move_right
    cmp al, 27                 ; Esc para salir
    je quit

    jmp wait_key

move_up:
    ; Mover hacia arriba
    cmp word ptr [yPos], 0      ; No exceder el borde superior
    jle wait_key
    sub word ptr [yPos], 6      ; Decrementar la posición Y (por tamaño del cuadrado)
    jmp draw_square             ; Dibujar en la nueva posición

move_down:
    ; Mover hacia abajo
    cmp word ptr [yPos], 194    ; No exceder el borde inferior (199 - 6)
    jge wait_key
    add word ptr [yPos], 6      ; Incrementar la posición Y (por tamaño del cuadrado)
    jmp draw_square             ; Dibujar en la nueva posición

move_left:
    ; Mover hacia la izquierda
    cmp word ptr [xPos], 0      ; No exceder el borde izquierdo
    jle wait_key
    sub word ptr [xPos], 6      ; Decrementar la posición X (por tamaño del cuadrado)
    jmp draw_square             ; Dibujar en la nueva posición

move_right:
    ; Mover hacia la derecha
    cmp word ptr [xPos], 314    ; No exceder el borde derecho (320 - 6)
    jge wait_key
    add word ptr [xPos], 6      ; Incrementar la posición X (por tamaño del cuadrado)
    jmp draw_square             ; Dibujar en la nueva posición

quit:
    ; Regresar al modo texto
    mov ax, 03h
    int 10h
    ; Terminar el programa
    mov ax, 4C00h
    int 21h
END start
