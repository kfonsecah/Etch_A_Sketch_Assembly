.MODEL small
.STACK 100h

.DATA
    mouse_x dw 0          ; Coordenada X del mouse
    mouse_y dw 0          ; Coordenada Y del mouse
    mouse_buttons db 0    ; Estado de los botones del mouse
    color_pixel db 1      ; Color por defecto del píxel
    current_x dw 65535    ; Coordenada X inicial (valor fuera de la pantalla)
    current_y dw 65535    ; Coordenada Y inicial (valor fuera de la pantalla)
    square_1_color db 0Fh ; Color del primer cuadrado
    square_2_color db 04h ; Color del segundo cuadrado
    square_3_color db 0Ah ; Color del tercer cuadrado

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

; DIBUJAR_CUADRADO Macro
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

; Inicializar el mouse
INIT_MOUSE PROC
    mov ax, 0
    int 33h
    cmp ax, 0
    je NO_MOUSE
    ret

NO_MOUSE:
    mov ax, 0003h
    int 10h
    mov ah, 4Ch
    int 21h
    ret
INIT_MOUSE ENDP

; Obtener las coordenadas del mouse y el estado de los botones
GET_MOUSE_STATUS PROC
    mov ax, 03h
    int 33h
    mov [mouse_buttons], bl
    mov [mouse_x], cx
    mov [mouse_y], dx
    ret
GET_MOUSE_STATUS ENDP

; Verificar clic en los cuadrados de color
VERIFICAR_CUADRADOS PROC
    ; Cuadrado 1
    cmp [mouse_x], 500
    jb no_click
    cmp [mouse_x], 530
    ja verificar_cuadrado_2
    cmp [mouse_y], 100
    jb no_click
    cmp [mouse_y], 130
    ja verificar_cuadrado_2
    mov al, [square_1_color]  ; Cambiar el color al del cuadrado 1
    mov [color_pixel], al
    jmp continuar

verificar_cuadrado_2:
    ; Cuadrado 2
    cmp [mouse_y], 150
    jb no_click
    cmp [mouse_y], 180
    ja verificar_cuadrado_3
    mov al, [square_2_color]  ; Cambiar el color al del cuadrado 2
    mov [color_pixel], al
    jmp continuar

verificar_cuadrado_3:
    ; Cuadrado 3
    cmp [mouse_y], 200
    jb no_click
    cmp [mouse_y], 230
    ja no_click
    mov al, [square_3_color]  ; Cambiar el color al del cuadrado 3
    mov [color_pixel], al
    jmp continuar

no_click:
    ret
continuar:
    ret
VERIFICAR_CUADRADOS ENDP

; Verificar si el clic está dentro del área de dibujo (cuadro en 100, 300 de 100x100)
VERIFICAR_AREA_DIBUJO PROC
    cmp [mouse_x], 100       ; Verificar si mouse_x está a la izquierda del límite
    jb no_click_dibujo       ; Si está a la izquierda, no permitir dibujo
    cmp [mouse_x], 200       ; Verificar si mouse_x está a la derecha del límite
    ja no_click_dibujo       ; Si está a la derecha, no permitir dibujo
    cmp [mouse_y], 300       ; Verificar si mouse_y está arriba del límite
    jb no_click_dibujo       ; Si está arriba, no permitir dibujo
    cmp [mouse_y], 400       ; Verificar si mouse_y está abajo del límite
    ja no_click_dibujo       ; Si está abajo, no permitir dibujo
    mov ax, 1                ; Si está dentro, permitir dibujo
    ret                      ; Si está dentro, permitir dibujo

no_click_dibujo:
    mov ax, 0                ; Si está fuera, bloquear el dibujo
    ret
VERIFICAR_AREA_DIBUJO ENDP

; Dibujar el píxel en la nueva posición del mouse
DIBUJAR_MOUSE_PIXEL PROC
    call GET_MOUSE_STATUS
    call VERIFICAR_CUADRADOS

    ; Verificar si el botón izquierdo del mouse fue presionado
    test [mouse_buttons], 1
    jz no_click_mouse

    ; Verificar si el clic está dentro del área de dibujo
    call VERIFICAR_AREA_DIBUJO
    cmp ax, 1
    jne no_click_mouse  ; Si ax no es 1, no pintar

    ; Guardar la posición del clic como la nueva posición del píxel
    mov ax, [mouse_x]
    mov [current_x], ax
    mov ax, [mouse_y]
    mov [current_y], ax

    ; Dibujar el píxel en la nueva posición
    PINTA_PIXEL [current_x], [current_y], [color_pixel]

no_click_mouse:
    ret
DIBUJAR_MOUSE_PIXEL ENDP

; Mover el píxel con las teclas WASD, dejando un trazo
MOVER_PIXEL PROC
    mov ah, 00h
    int 16h
    cmp al, 'w'
    je mover_arriba
    cmp al, 's'
    je mover_abajo
    cmp al, 'a'
    je mover_izquierda
    cmp al, 'd'
    je mover_derecha
    cmp al, 27
    jmp salir  ; En lugar de je salir

    ret

mover_arriba:
    cmp [current_y], 1
    jle no_move
    dec word ptr [current_y]
    call dibujar_trazo
    ret

mover_abajo:
    cmp [current_y], 478
    jge no_move
    inc word ptr [current_y]
    call dibujar_trazo
    ret

mover_izquierda:
    cmp [current_x], 1
    jle no_move
    dec word ptr [current_x]
    call dibujar_trazo
    ret

mover_derecha:
    cmp [current_x], 638
    jge no_move
    inc word ptr [current_x]
    call dibujar_trazo
    ret

dibujar_trazo:
    PINTA_PIXEL [current_x], [current_y], [color_pixel]
    ret

no_move:
    ret
MOVER_PIXEL ENDP

start:
    mov ax, @data
    mov ds, ax

    ; Cambiar a modo gráfico 12h (640x480, 16 colores)
    mov ax, 0012h
    int 10h

    ; Dibujar tres cuadrados a la derecha de la pantalla
    mov al, [square_1_color]
    DIBUJAR_CUADRADO 500, 100, 30, al

    mov al, [square_2_color]
    DIBUJAR_CUADRADO 500, 150, 30, al

    mov al, [square_3_color]
    DIBUJAR_CUADRADO 500, 200, 30, al

    ; Dibuja un cuadrado para el área de dibujo (100, 300, 100x100)
    DIBUJAR_CUADRADO 100, 300, 100, 0FH

    ; Inicializar el mouse
    call INIT_MOUSE

main_loop:
    call DIBUJAR_MOUSE_PIXEL
    call MOVER_PIXEL
    jmp main_loop

salir:
    mov ax, 0003h
    int 10h
    mov ah, 4Ch
    int 21h
END start
