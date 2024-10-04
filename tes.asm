.model small
.stack 100h

.data
    current_x dw 320          ; Coordenada X inicial (centro de la pantalla)
    current_y dw 240          ; Coordenada Y inicial (centro de la pantalla)
    color_pixel db 02h        ; Color del píxel (verde)
    background_color db 08h   ; Color de fondo (blanco para borrar)

    ; Mensaje para depuración
    msg db 'Tecla presionada: $'   ; El símbolo $ es el terminador de cadena para int 21h función 09h

    ; Macro para pintar un píxel
    PINTAR_PIXEL macro x, y, color
        mov ah, 0Ch
        mov al, color
        mov bh, 0
        mov cx, x
        mov dx, y
        int 10h
    endm

.code

DIBUJAR_PIXEL proc near
    mov ax, [current_x]
    mov dx, [current_y]
    PINTAR_PIXEL ax, dx, color_pixel
    ret
DIBUJAR_PIXEL endp

BORRAR_PIXEL proc near
    mov ax, [current_x]
    mov dx, [current_y]
    PINTAR_PIXEL ax, dx, background_color
    ret
BORRAR_PIXEL endp

GESTIONAR_TECLADO proc near
    mov ah, 00h
    int 16h

    cmp al, 'W'
    je mover_arriba

    cmp al, 'S'
    je mover_abajo

    cmp al, 'A'
    je mover_izquierda

    cmp al, 'D'
    je mover_derecha

    cmp al, 27      ; Esc para salir
    je salir

    ret

mover_arriba:
    cmp [current_y], 0
    jle movimiento_hecho
    call BORRAR_PIXEL
    dec word ptr [current_y]
    call DIBUJAR_PIXEL
    jmp movimiento_hecho

mover_abajo:
    cmp [current_y], 479
    jge movimiento_hecho
    call BORRAR_PIXEL
    inc word ptr [current_y]
    call DIBUJAR_PIXEL
    jmp movimiento_hecho

mover_izquierda:
    cmp [current_x], 0
    jle movimiento_hecho
    call BORRAR_PIXEL
    dec word ptr [current_x]
    call DIBUJAR_PIXEL
    jmp movimiento_hecho

mover_derecha:
    cmp [current_x], 639
    jge movimiento_hecho
    call BORRAR_PIXEL
    inc word ptr [current_x]
    call DIBUJAR_PIXEL

movimiento_hecho:
    ret
GESTIONAR_TECLADO endp

IMPRIMIR_MENSAJE proc near
    lea dx, msg          ; Cargar la dirección del mensaje
    mov ah, 09h          ; Función de DOS para imprimir una cadena
    int 21h              ; Interrupción para mostrar el mensaje
    ret
IMPRIMIR_MENSAJE endp

start:
    ; Establecer el modo texto para depuración
    mov ax, 03h
    int 10h

    ; Mostrar mensaje de depuración en modo texto
    call IMPRIMIR_MENSAJE

    ; Esperar a que el usuario presione una tecla
    mov ah, 00h
    int 16h

    ; Cambiar al modo gráfico 12h (640x480, 16 colores)
    mov ax, 0012h
    int 10h

    ; Dibuja el píxel inicial en el centro de la pantalla
    call DIBUJAR_PIXEL

bucle_principal:
    call GESTIONAR_TECLADO
    jmp bucle_principal

salir:
    ; Volver al modo texto antes de salir
    mov ax, 03h
    int 10h
    mov ah, 4Ch
    int 21h
end start
