.model small
.stack 100h

.data
    xPos dw 160        ; Posición X inicial (centro de la pantalla)
    yPos dw 100        ; Posición Y inicial (centro de la pantalla)
    mouseX dw 0        ; Posición X del ratón
    mouseY dw 0        ; Posición Y del ratón

.code
start:
    mov ax, @data
    mov ds, ax

    ; Cambiar al modo gráfico 13h (320x200, 256 colores)
    mov ax, 13h
    int 10h

    ; Inicializar el ratón
    xor ax, ax           ; Inicializar el ratón
    int 33h
    mov ax, 1            ; Mostrar el cursor del ratón
    int 33h

draw_pixel:
    ; Dibujar el píxel en la posición actual
    mov ax, 0A000h             ; Segmento de la memoria de video
    mov es, ax
    mov ax, [yPos]             ; Cargar yPos en AX
    mov bx, 320                ; Ancho de la pantalla
    mul bx                     ; Multiplicar Y por 320 (filas)
    add ax, [xPos]             ; Sumar la posición X al resultado
    mov di, ax                 ; Cargar en DI la dirección calculada
    mov al, 15                 ; Color del píxel (blanco)
    stosb                      ; Dibujar el píxel

    ; Esperar para redibujar
    jmp wait_key

wait_key:
    ; Verificar si hay movimiento del ratón o un clic
    mov ax, 3
    int 33h
    mov [mouseX], cx           ; Guardar la posición X del ratón
    mov [mouseY], dx           ; Guardar la posición Y del ratón
    test bx, 1                 ; Verificar si el botón izquierdo está presionado
    jnz mouse_click            ; Si está presionado, ejecutar acción

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
    dec word ptr [yPos]         ; Decrementar la posición Y
    jmp draw_pixel              ; Dibujar en la nueva posición

move_down:
    ; Mover hacia abajo
    cmp word ptr [yPos], 199    ; No exceder el borde inferior
    jge wait_key
    inc word ptr [yPos]         ; Incrementar la posición Y
    jmp draw_pixel              ; Dibujar en la nueva posición

move_left:
    ; Mover hacia la izquierda
    cmp word ptr [xPos], 0      ; No exceder el borde izquierdo
    jle wait_key
    dec word ptr [xPos]         ; Decrementar la posición X
    jmp draw_pixel              ; Dibujar en la nueva posición

move_right:
    ; Mover hacia la derecha
    cmp word ptr [xPos], 319    ; No exceder el borde derecho
    jge wait_key
    inc word ptr [xPos]         ; Incrementar la posición X
    jmp draw_pixel              ; Dibujar en la nueva posición

mouse_click:
    ; Acciones al hacer clic con el ratón
    ; Aquí puedes agregar lo que quieras hacer cuando se detecte un clic
    ; Actualmente solo vuelve a esperar entrada
    jmp wait_key

quit:
    ; Regresar al modo texto
    mov ax, 03h
    int 10h
    ; Terminar el programa
    mov ax, 4C00h
    int 21h
END start
