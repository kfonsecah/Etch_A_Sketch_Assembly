.MODEL small
.STACK 100h

.DATA
    current_x dw 65535    
    current_y dw 65535    
    color_pixel db 00h  
    mensaje1 db ' Limpiar ', 0
    mensaje2 db ' Dibujo sin nombre ', 0  
    mensaje3 db ' Guardar Bosquejo ', 0 
    mensaje4 db ' Cargar Bosquejo ', 0 
    mensaje5 db ' Campo de texto ', 0 
    mensaje6 db ' Insertar imagen ', 0 
    
    mouse_x dw 0          
    mouse_y dw 0          
    mouse_buttons db 0    
    square_1_color db 01h 
    square_2_color db 02h 
    square_3_color db 04h 
    square_4_color db 05h 
    square_5_color db 06h
    square_6_color db 07h  
    square_7_color db 08h 
    square_8_color db 09h 
    square_9_color db 0Ah 
    square_10_color db 0Bh 
    square_11_color db 0Ch
    square_12_color db 0Dh 

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
    MOV DX, 0
RELLENAR_FILAS:
    MOV CX, 0
RELLENAR_COLUMNAS:
    PINTA_PIXEL CX, DX, color
    INC CX
    CMP CX, 640
    JBE RELLENAR_COLUMNAS
    INC DX
    CMP DX, 480
    JBE RELLENAR_FILAS
endm

IMPRIMIR_TEXTO macro fila, columna, mensaje, color
    local IMPRIMIR_CADENA, FIN
    mov ah, 02h
    mov bh, 0
    mov dh, fila
    mov dl, columna
    int 10h
    lea si, mensaje
IMPRIMIR_CADENA:
    lodsb
    cmp al, 0
    je FIN
    mov ah, 0Eh
    mov al, al
    mov bl, color
    int 10h
    jmp IMPRIMIR_CADENA
FIN:
endm

VERIFICAR_CUADRADO macro x_min, x_max, y_min, y_max, color
    local FUERA_CUADRADO, DENTRO_CUADRADO
    cmp [mouse_x], x_min
    jb FUERA_CUADRADO
    cmp [mouse_x], x_max
    ja FUERA_CUADRADO
    cmp [mouse_y], y_min
    jb FUERA_CUADRADO
    cmp [mouse_y], y_max
    ja FUERA_CUADRADO
    mov al, color
    mov [color_pixel], al
FUERA_CUADRADO:
endm

.CODE

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

GET_MOUSE_STATUS PROC
    mov ax, 03h
    int 33h
    mov [mouse_buttons], bl
    mov [mouse_x], cx
    mov [mouse_y], dx
    ret
GET_MOUSE_STATUS ENDP

VERIFICAR_AREA_DIBUJO PROC
    cmp [mouse_x], 136
    jb no_click_dibujo
    cmp [mouse_x], 533
    ja no_click_dibujo
    cmp [mouse_y], 90
    jb no_click_dibujo
    cmp [mouse_y], 389
    ja no_click_dibujo
    mov ax, 1
    ret
no_click_dibujo:
    mov ax, 0
    ret
VERIFICAR_AREA_DIBUJO ENDP

DIBUJAR_MOUSE_PIXEL PROC
    call GET_MOUSE_STATUS
    VERIFICAR_CUADRADO 564, 594, 350, 380, [square_1_color]
    VERIFICAR_CUADRADO 564, 594, 300, 330, [square_2_color]
    VERIFICAR_CUADRADO 564, 594, 250, 280, [square_3_color]
    VERIFICAR_CUADRADO 564, 594, 200, 230, [square_4_color]
    VERIFICAR_CUADRADO 564, 594, 150, 180, [square_5_color]
    VERIFICAR_CUADRADO 564, 594, 100, 130, [square_6_color]
    VERIFICAR_CUADRADO 75, 105, 350, 380, [square_7_color]
    VERIFICAR_CUADRADO 75, 105, 300, 330, [square_8_color]
    VERIFICAR_CUADRADO 75, 105, 250, 280, [square_9_color]
    VERIFICAR_CUADRADO 75, 105, 200, 230, [square_10_color]
    VERIFICAR_CUADRADO 75, 105, 150, 180, [square_11_color]
    VERIFICAR_CUADRADO 75, 105, 100, 130, [square_12_color]
    test [mouse_buttons], 1
    jz no_click_mouse
    call VERIFICAR_AREA_DIBUJO
    cmp ax, 1
    jne no_click_mouse
    mov ax, [mouse_x]
    mov [current_x], ax
    mov ax, [mouse_y]
    mov [current_y], ax
    PINTA_PIXEL [current_x], [current_y], [color_pixel]
no_click_mouse:
    ret
DIBUJAR_MOUSE_PIXEL ENDP

MOVER_PIXEL PROC
    mov ah, 01h
    int 16h
    jz no_key_pressed
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
    jmp salir
    ret
mover_arriba:
    cmp [current_y], 90
    jle no_move
    dec word ptr [current_y]
    call dibujar_trazo
    ret
mover_abajo:
    cmp [current_y], 389
    jge no_move
    inc word ptr [current_y]
    call dibujar_trazo
    ret
mover_izquierda:
    cmp [current_x], 136
    jle no_move
    dec word ptr [current_x]
    call dibujar_trazo
    ret
mover_derecha:
    cmp [current_x], 533
    jge no_move
    inc word ptr [current_x]
    call dibujar_trazo
    ret
dibujar_trazo:
    PINTA_PIXEL [current_x], [current_y], [color_pixel]
    ret
no_move:
    ret
no_key_pressed:
    ret
MOVER_PIXEL ENDP

start:
    mov ax, @data
    mov ds, ax
    mov ax, 0012h
    int 10h
    RELLENAR_PANTALLA 08h
    DIBUJAR_RECTANGULO 60, 50, 360, 30, 0Fh
    DIBUJAR_RECTANGULO 425, 50, 110, 30, 0Fh
    DIBUJAR_RECTANGULO 550, 90, 60, 300, 0Fh
    DIBUJAR_RECTANGULO 136, 90, 398, 300, 0Fh
    DIBUJAR_RECTANGULO 60, 90, 60, 300, 0Fh
    DIBUJAR_CUADRADO 564, 350, 30, 01h
    DIBUJAR_CUADRADO 564, 300, 30, 02h
    DIBUJAR_CUADRADO 564, 250, 30, 04h
    DIBUJAR_CUADRADO 564, 200, 30, 05h
    DIBUJAR_CUADRADO 564, 150, 30, 06h
    DIBUJAR_CUADRADO 564, 100, 30, 07h
    DIBUJAR_CUADRADO 75, 350, 30, 08h
    DIBUJAR_CUADRADO 75, 300, 30, 09h
    DIBUJAR_CUADRADO 75, 250, 30, 0Ah
    DIBUJAR_CUADRADO 75, 200, 30, 0Bh
    DIBUJAR_CUADRADO 75, 150, 30, 0Ch
    DIBUJAR_CUADRADO 75, 100, 30, 0Dh
    DIBUJAR_CUADRADO 564, 410, 30, 0Fh
    DIBUJAR_CUADRADO 564, 445, 30, 0Fh
    DIBUJAR_CUADRADO 529, 445, 30, 0Fh
    DIBUJAR_CUADRADO 600, 445, 30, 0Fh
    DIBUJAR_RECTANGULO 60, 400, 100, 30, 0Fh
    DIBUJAR_RECTANGULO 60, 435, 100, 30, 0Fh
    DIBUJAR_RECTANGULO 167, 400, 255, 30, 0Fh
    DIBUJAR_RECTANGULO 430, 400, 105, 30, 0Fh
    IMPRIMIR_TEXTO  4, 54, mensaje1, 1Fh
    IMPRIMIR_TEXTO 4, 20, mensaje2, 2Fh
    IMPRIMIR_TEXTO  26, 7, mensaje3, 1Fh
    IMPRIMIR_TEXTO 28, 7, mensaje4, 2Fh
    IMPRIMIR_TEXTO 26, 28, mensaje5, 2Fh
    IMPRIMIR_TEXTO 26, 54, mensaje6, 2Fh
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