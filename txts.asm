.MODEL small
.STACK 100h
.DATA
    ; Texto general
    mensaje1 db ' Limpiar ', 0
    mensaje2 db ' Dibujo sin nombre ', 0  
    mensaje3 db ' Guardar Bosquejo ', 0 
    mensaje4 db ' Cargar Bosquejo ', 0 
    mensaje5 db ' Campo de texto ', 0 
    mensaje6 db ' Insertar imagen ', 0 
    mensaje_apertura db 'Abriendo archivo...', 0
    mensaje_exito db 'Archivo guardado!', 0
    mensaje_error db 'Error al abrir archivo!', 0
    
    buffer db 100 dup(' ')          ; Espacio para almacenar texto '                                          '
    color_buffer db 2 dup(' ')      ; Espacio para almacenar colores
    letter_buffer db 2 dup(' ')     ; Espacio para almacenar letras
    
    buffer_length dw 0               ; Longitud actual del texto en el buffer
    capture_enabled db 0             ; 0 = No captura, 1 = Captura entrada
    movement_enabled dw 0            ; Flag para manejo de teclas direccionales

    current_x dw 334               ; Coordenada X inicial (centro del área de dibujo)
    current_y dw 240               ; Coordenada Y inicial (centro del área de dibujo)
    color_pixel db 08h 
    old_color_pixel db 0Fh

    mouse_x dw 0                     ; Coordenada X del mouse
    mouse_y dw 0                     ; Coordenada Y del mouse
    mouse_buttons db 0               ; Estado del botón del mouse

    ; Colores de cuadrados
    square_1_color db 01h 
    square_2_color db 0Eh   ; Amarillo como las miadas de zakary 
    square_3_color db 04h 
    square_4_color db 05h 
    square_5_color db 06h
    square_6_color db 07h  
    square_7_color db 08h 
    square_8_color db 09h 
    square_9_color db 0Ah 
    square_10_color db 0Bh 
    square_11_color db 0Ch
    square_12_color db 0Fh 

    ; Nombre del archivo de imagen
    image_file_name db 'image.txt', 0

    ; Gate para manejo de archivos
    file_handle dw 0                 ; Handle para el archivo
    buffer_guardado db 5 dup(0)      ; Buffer para coordenadas (x, y) y color del píxel

    ; Carácteres constantes
    coma db ',', 0                   ; Separador de coma
    salto_linea db 13, 10, 0         ; Salto de línea
    arroba db '@', 0
    porcentaje db '%', 0

    fondo_color db 0Fh               ; Color de fondo

; Macro para dibujar un píxel en la pantalla
PINTA_PIXEL macro x, y, color
    mov ah, 0Ch
    mov al, color
    mov bh, 0
    mov cx, x
    mov dx, y
    int 10h
endm

; Macro para dibujar un cuadrado
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

; Macro para dibujar un rectángulo
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

; Macro para dibujar el borde de un rectángulo
DIBUJAR_BORDE_RECTANGULO macro x_inicial, y_inicial, ancho, alto, color
    local COLUMNAS_BORDE_SUPERIOR, COLUMNAS_BORDE_INFERIOR, FILAS_BORDE_IZQUIERDO, FILAS_BORDE_DERECHO

    ; Dibujar borde superior
    mov cx, x_inicial
    mov dx, y_inicial
COLUMNAS_BORDE_SUPERIOR:
    PINTA_PIXEL cx, dx, color
    inc cx
    cmp cx, x_inicial + ancho
    jb COLUMNAS_BORDE_SUPERIOR

    ; Dibujar borde inferior
    mov cx, x_inicial
    mov dx, y_inicial + alto - 1
COLUMNAS_BORDE_INFERIOR:
    PINTA_PIXEL cx, dx, color
    inc cx
    cmp cx, x_inicial + ancho
    jb COLUMNAS_BORDE_INFERIOR

    ; Dibujar borde izquierdo
    mov cx, x_inicial
    mov dx, y_inicial
FILAS_BORDE_IZQUIERDO:
    PINTA_PIXEL cx, dx, color
    inc dx
    cmp dx, y_inicial + alto
    jb FILAS_BORDE_IZQUIERDO

    ; Dibujar borde derecho
    mov cx, x_inicial + ancho - 1
    mov dx, y_inicial
FILAS_BORDE_DERECHO:
    PINTA_PIXEL cx, dx, color
    inc dx
    cmp dx, y_inicial + alto
    jb FILAS_BORDE_DERECHO
    endm

; Macro para rellenar toda la pantalla con un color
RELLENAR_PANTALLA macro color
    mov dx, 0              ; Empieza en Y = 0
RELLENAR_FILAS:
    mov cx, 0              ; Empieza en X = 0
RELLENAR_COLUMNAS:
    PINTA_PIXEL cx, dx, color  ; Pintar con el color especificado
    inc cx
    cmp cx, 640            ; Hasta la columna 640
    jbe RELLENAR_COLUMNAS
    inc dx
    cmp dx, 480            ; Hasta la fila 480
    jbe RELLENAR_FILAS
    endm

; Macro para imprimir texto en pantalla
IMPRIMIR_TEXTO macro fila, columna, mensaje, color
    local IMPRIMIR_CADENA, FIN
    mov ah, 02h             ; Función para mover el cursor
    mov bh, 0               ; Página de la pantalla
    mov dh, fila            ; Fila del cursor
    mov dl, columna         ; Columna del cursor
    int 10h                 ; Llamar a BIOS para mover el cursor

    lea si, mensaje         ; Cargar la dirección del mensaje
IMPRIMIR_CADENA:
    lodsb                   ; Cargar el siguiente carácter en AL
    cmp al, 0               ; Verificar fin de la cadena
    je FIN
    mov ah, 0Eh             ; Función de BIOS para imprimir el carácter
    mov al, al              ; Carácter a imprimir
    mov bl, color           ; Color del texto
    int 10h                 ; Llamar a BIOS para mostrar el carácter
    jmp IMPRIMIR_CADENA
FIN:
    endm

; Macro para verificar si el clic está dentro de un cuadrado y cambiar el color
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
    mov al, color           ; Cambiar color si está dentro del cuadrado
    mov [color_pixel], al

    ; Dibujar el cuadrado de color seleccionado
    DIBUJAR_CUADRADO 355, 445, 30, [color_pixel]
FUERA_CUADRADO:
    endm

; Macro para verificar si el clic está en el botón de "Limpiar" y dibujar el cuadrado azul
VERIFICAR_LIMPIAR macro
    cmp [mouse_x], 425
    jb FUERA_LIMPIAR
    cmp [mouse_x], 535
    ja FUERA_LIMPIAR
    cmp [mouse_y], 42
    jb FUERA_LIMPIAR
    cmp [mouse_y], 72
    ja FUERA_LIMPIAR
    ; Verificar si el botón izquierdo del mouse fue presionado
    test [mouse_buttons], 1
    jz FUERA_LIMPIAR
    ; Si el clic está en el botón "Limpiar" y el botón izquierdo está presionado, limpiar el área de dibujo
    DIBUJAR_RECTANGULO 136, 90, 398, 300, 0Fh   ; Limpiar el área de dibujo con color de fondo
    mov [old_color_pixel], 0Fh
    ; Verificar si el primer carácter del buffer es un espacio
    mov al, [buffer]
    cmp al, ' '
    je FUERA_LIMPIAR
    ; Imprimir el buffer si no es un espacio
    call IMPRIMIR_BUFFER
FUERA_LIMPIAR:
    endm

VERIFICAR_GUARDAR macro
    cmp [mouse_x], 15
    jb FUERA_GUARDAR
    cmp [mouse_x], 165
    ja FUERA_GUARDAR
    cmp [mouse_y], 410
    jb FUERA_GUARDAR
    cmp [mouse_y], 440
    ja FUERA_GUARDAR
    test [mouse_buttons], 1
    jz FUERA_GUARDAR
    call GUARDAR_BOSQUEJO
FUERA_GUARDAR:
    endm

VERIFICAR_CARGAR macro
    cmp [mouse_x], 15
    jb FUERA_CARGAR
    cmp [mouse_x], 165
    ja FUERA_CARGAR
    cmp [mouse_y], 445
    jb FUERA_CARGAR
    cmp [mouse_y], 475
    ja FUERA_CARGAR
    test [mouse_buttons], 1
    jz FUERA_CARGAR
    call CARGAR_BOSQUEJO
FUERA_CARGAR:
    endm

VERIFICAR_INSERTAR macro
    cmp [mouse_x], 465
    jb FUERA_INSERTAR
    cmp [mouse_x], 610
    ja FUERA_INSERTAR
    cmp [mouse_y], 410
    jb FUERA_INSERTAR
    cmp [mouse_y], 440
    ja FUERA_INSERTAR
    test [mouse_buttons], 1
    jz FUERA_INSERTAR
    call INSERTAR_IMAGEN
FUERA_INSERTAR:
    endm

VERIFICAR_CAMPO_TEXTO macro
    cmp [mouse_x], 175
    jb FUERA_CAMPO_TEXTO
    cmp [mouse_x], 455
    ja FUERA_CAMPO_TEXTO
    cmp [mouse_y], 410
    jb FUERA_CAMPO_TEXTO
    cmp [mouse_y], 440
    ja FUERA_CAMPO_TEXTO
    test [mouse_buttons], 1
    jz FIN_VERIFICAR
    mov [capture_enabled], 1
    jmp FIN_VERIFICAR

FUERA_CAMPO_TEXTO:
    test [mouse_buttons], 1
    jz FIN_VERIFICAR
    mov [capture_enabled], 0
FIN_VERIFICAR:
    endm


    ; Macro para verificar si el clic está en el botón de "Izquierda" y mover el píxel
VERIFICAR_IZQUIERDA macro
    ; Only move if mouse is within bounds and left button is pressed
    cmp [mouse_x], 459
    jb FUERA_IZQUIERDA
    cmp [mouse_x], 489
    ja FUERA_IZQUIERDA
    cmp [mouse_y], 445
    jb FUERA_IZQUIERDA
    cmp [mouse_y], 475
    ja FUERA_IZQUIERDA
    ; Verificar si el botón izquierdo del mouse fue presionado
    test [mouse_buttons], 1
    jz FUERA_IZQUIERDA
    ; Move pixel only if flag allows it
    cmp [movement_enabled], 0
    jne FUERA_IZQUIERDA
    ; Enable movement flag
    mov [movement_enabled], 1
    ; Move pixel to the left
    call MOVER_IZQUIERDA
FUERA_IZQUIERDA:
    ; Reset the movement flag when mouse button is released
    test [mouse_buttons], 1
    jnz FIN_IZQUIERDA
    mov [movement_enabled], 0
FIN_IZQUIERDA:
    endm

; Macro para verificar si el clic está en el botón de "Derecha" y mover el píxel
VERIFICAR_DERECHA macro
    ; Only move if mouse is within bounds and left button is pressed
    cmp [mouse_x], 494
    jb FUERA_DERECHA
    cmp [mouse_x], 524
    ja FUERA_DERECHA
    cmp [mouse_y], 445
    jb FUERA_DERECHA
    cmp [mouse_y], 475
    ja FUERA_DERECHA
    ; Verificar si el botón izquierdo del mouse fue presionado
    test [mouse_buttons], 1
    jz FUERA_DERECHA
    ; Move pixel only if flag allows it
    cmp [movement_enabled], 0
    jne FUERA_DERECHA
    ; Enable movement flag
    mov [movement_enabled], 1
    ; Move pixel to the right
    call MOVER_DERECHA
FUERA_DERECHA:
    ; Reset the movement flag when mouse button is released
    test [mouse_buttons], 1
    jnz FIN_DERECHA
    mov [movement_enabled], 0
FIN_DERECHA:
    endm

; Macro para verificar si el clic está en el botón de "Arriba" y mover el píxel
VERIFICAR_ARRIBA macro
    ; Only move if mouse is within bounds and left button is pressed
    cmp [mouse_x], 529
    jb FUERA_ARRIBA
    cmp [mouse_x], 559
    ja FUERA_ARRIBA
    cmp [mouse_y], 445
    jb FUERA_ARRIBA
    cmp [mouse_y], 475
    ja FUERA_ARRIBA
    ; Verificar si el botón izquierdo del mouse fue presionado
    test [mouse_buttons], 1
    jz FUERA_ARRIBA
    ; Move pixel only if flag allows it
    cmp [movement_enabled], 0
    jne FUERA_ARRIBA
    ; Enable movement flag
    mov [movement_enabled], 1
    ; Move pixel up
    call MOVER_ARRIBA
FUERA_ARRIBA:
    ; Reset the movement flag when mouse button is released
    test [mouse_buttons], 1
    jnz FIN_ARRIBA
    mov [movement_enabled], 0
FIN_ARRIBA:
    endm

; Macro para verificar si el clic está en el botón de "Abajo" y mover el píxel
VERIFICAR_ABAJO macro
    ; Only move if mouse is within bounds and left button is pressed
    cmp [mouse_x], 564
    jb FUERA_ABAJO
    cmp [mouse_x], 594
    ja FUERA_ABAJO
    cmp [mouse_y], 445
    jb FUERA_ABAJO
    cmp [mouse_y], 475
    ja FUERA_ABAJO
    ; Verificar si el botón izquierdo del mouse fue presionado
    test [mouse_buttons], 1
    jz FUERA_ABAJO
    ; Move pixel only if flag allows it
    cmp [movement_enabled], 0
    jne FUERA_ABAJO
    ; Enable movement flag
    mov [movement_enabled], 1
    ; Move pixel down
    call MOVER_ABAJO
FUERA_ABAJO:
    ; Reset the movement flag when mouse button is released
    test [mouse_buttons], 1
    jnz FIN_ABAJO
    mov [movement_enabled], 0
FIN_ABAJO:
    endm

VERIFICAR_PINTAR_FONDO macro
    cmp [mouse_x], 400
    jb FUERA_PINTAR_FONDO
    cmp [mouse_x], 430
    ja FUERA_PINTAR_FONDO
    cmp [mouse_y], 445
    jb FUERA_PINTAR_FONDO
    cmp [mouse_y], 475
    ja FUERA_PINTAR_FONDO
    test [mouse_buttons], 1
    jz FUERA_PINTAR_FONDO

    mov al, [old_color_pixel]
    mov ah, al
    mov di, 90           ; Inicializar Y en 90
PINTAR_FILAS_FONDO:
    mov si, 136          ; Inicializar X en 136
PINTAR_COLUMNAS_FONDO:
    mov ah, 0Dh          ; Leer color de píxel
    mov bh, 0            ; Página de pantalla 0
    mov cx, si           ; Posición X
    mov dx, di           ; Posición Y
    int 10h              ; Llamada a BIOS para leer el color

    cmp al, [old_color_pixel]
    jne NO_PINTAR_PIXEL

    mov al, [color_pixel]
    PINTA_PIXEL si, di, al
NO_PINTAR_PIXEL:
    inc si
    cmp si, 534          ; Limitar hasta 398 píxeles
    jb PINTAR_COLUMNAS_FONDO
    inc di
    cmp di, 390          ; Limitar hasta 300 píxeles
    jbe PINTAR_FILAS_FONDO

    mov al, [color_pixel]
    mov [old_color_pixel], al

    DIBUJAR_CUADRADO 335, 460, 15, al
FUERA_PINTAR_FONDO:
    endm

.CODE ; ################################################################<<<<CODE SECTION>>>>############################################################
; Inicializar el mouse y mostrar el cursor
INIT_MOUSE PROC
    mov ax, 0              ; Inicializar el mouse
    int 33h
    cmp ax, 0              ; Verificar si el mouse está presente
    je NO_MOUSE            ; Si no está presente, salir
    mov ax, 1              ; Mostrar el cursor del mouse
    int 33h
    ret
NO_MOUSE:
    mov ax, 0003h
    int 10h
    mov ah, 4Ch
    int 21h
    ret
INIT_MOUSE ENDP

ESCONDER_MOUSE PROC
    mov ax, 02h            ; Esconder el cursor del mouse
    int 33h
    ret
ESCONDER_MOUSE ENDP

MOSTRAR_MOUSE PROC
    mov ax, 01h            ; Mostrar el cursor del mouse
    int 33h
    ret
MOSTRAR_MOUSE ENDP

GET_MOUSE_STATUS PROC
    mov ax, 03h            ; Obtener coordenadas y estado de botones
    int 33h
    mov [mouse_buttons], bl
    mov [mouse_x], cx
    mov [mouse_y], dx
    ret
GET_MOUSE_STATUS ENDP

VERIFICAR_AREA_DIBUJO PROC
    cmp [mouse_x], 136
    jb NO_CLICK_DIBUJO
    cmp [mouse_x], 533
    ja NO_CLICK_DIBUJO
    cmp [mouse_y], 90
    jb NO_CLICK_DIBUJO
    cmp [mouse_y], 389
    ja NO_CLICK_DIBUJO
    mov ax, 1                ; Permitir dibujo
    ret
NO_CLICK_DIBUJO:
    mov ax, 0                ; Bloquear dibujo
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
    jz NO_CLICK_MOUSE
    call VERIFICAR_AREA_DIBUJO
    cmp ax, 1
    jne NO_CLICK_MOUSE
    mov ax, [mouse_x]
    mov [current_x], ax
    mov ax, [mouse_y]
    mov [current_y], ax
    PINTA_PIXEL [current_x], [current_y], [color_pixel]
NO_CLICK_MOUSE:
    ret
DIBUJAR_MOUSE_PIXEL ENDP

MOVER_PIXEL PROC
    mov ah, 01h              ; Verificar si hay tecla presionada
    int 16h
    jz NO_KEY_PRESSED        ; Si no hay tecla presionada, no hacer nada

    mov ah, 00h
    int 16h                  ; Leer la tecla presionada
    cmp al, 'w'
    je MOVER_ARRIBA
    cmp al, 's'
    je MOVER_ABAJO
    cmp al, 'a'
    je MOVER_IZQUIERDA
    cmp al, 'd'
    je MOVER_DERECHA
    cmp al, 27
    jmp SALIR                ; Salir si se presiona Esc
    ret
MOVER_ARRIBA:
    cmp [current_y], 90
    jle NO_MOVE
    dec word ptr [current_y]
    call DIBUJAR_TRAZO
    ret
MOVER_ABAJO:
    cmp [current_y], 389
    jge NO_MOVE
    inc word ptr [current_y]
    call DIBUJAR_TRAZO
    ret
MOVER_IZQUIERDA:
    cmp [current_x], 136
    jle NO_MOVE
    dec word ptr [current_x]
    call DIBUJAR_TRAZO
    ret
MOVER_DERECHA:
    cmp [current_x], 533
    jge NO_MOVE
    inc word ptr [current_x]
    call DIBUJAR_TRAZO
    ret
DIBUJAR_TRAZO:
    PINTA_PIXEL [current_x], [current_y], [color_pixel]
    ret
NO_MOVE:
    ret
NO_KEY_PRESSED:
    ret
MOVER_PIXEL ENDP

CAPTURAR_ENTRADA PROC
    cmp [capture_enabled], 1         ; Verify if capture is enabled
    jne NO_CAPTURE_ACTIVE            ; Skip capture if disabled

    mov ah, 01h                      ; Check if a key is pressed
    int 16h
    jz NO_KEY_PRESSED2               ; Exit if no key is pressed

    mov ah, 00h
    int 16h                          ; Read the pressed key

    ; Handle Backspace first to avoid interference with buffer input
    cmp al, 8                        ; Check if Backspace (ASCII 8)
    je BORRAR_CARACTER               ; If Backspace, go to erase character

    ; Handle Enter key
    cmp al, 13                       ; Check if Enter (ASCII 13)
    je NO_KEY_PRESSED2               ; Ignore Enter, skip capturing

    cmp al, 27                       ; Check if Esc (ASCII 27)
    je NO_KEY_PRESSED2               ; Ignore Esc to avoid exiting

    ; Check if buffer is full
    cmp [buffer_length], 10          ; Buffer max length check
    jge NO_KEY_PRESSED2              ; Skip if buffer is full

    ; Store the character in buffer
    mov si, [buffer_length]
    mov [buffer + si], al
    inc word ptr [buffer_length]     ; Increment buffer length

    ; Add null terminator at the end of buffer
    mov byte ptr [buffer + si + 1], 0
    ; Display updated text
    call IMPRIMIR_BUFFER

    ; Short delay to debounce key press for adding
    mov cx, 5000
DEBOUNCE_INC_DELAY:
    loop DEBOUNCE_INC_DELAY
    jmp NO_KEY_PRESSED2

BORRAR_CARACTER:
    cmp [buffer_length], 0           ; Check if buffer is empty
    je NO_KEY_PRESSED2               ; Exit if buffer is empty
    ; Reduce buffer length
    dec word ptr [buffer_length]
    mov si, [buffer_length]
    ; Replace the last character with a null terminator
    mov byte ptr [buffer + si], 0
    ; Redraw input field
    DIBUJAR_RECTANGULO 175, 410, 280, 30, 00h ; Text field box
    call IMPRIMIR_BUFFER
    ; Short delay to debounce key press for deleting
    mov cx, 5000
DEBOUNCE_DEC_DELAY:
    loop DEBOUNCE_DEC_DELAY
    jmp NO_KEY_PRESSED2

NO_CAPTURE_ACTIVE:
NO_KEY_PRESSED2:
    ret
CAPTURAR_ENTRADA ENDP

; Imprime el contenido del buffer en la posición del cursor
IMPRIMIR_BUFFER PROC
    DIBUJAR_RECTANGULO 175, 410, 280, 30, 00h ; Campo de texto
    mov ah, 02h
    mov bh, 0
    mov dh, 26        ; Fila 26, donde está el campo de texto
    mov dl, 32        ; Columna 32
    int 10h           ; Llamada a BIOS para mover el cursor

    mov cx, 15        ; Longitud máxima del campo de texto
    mov al, ' '       ; Carácter de espacio
BORRAR_TEXTO:
    mov ah, 0Eh       ; Función de BIOS para imprimir el carácter
    int 10h
    loop BORRAR_TEXTO

    mov ah, 02h
    mov bh, 0
    mov dh, 26
    mov dl, 32
    int 10h           ; Mover el cursor

    mov si, offset buffer
    mov cx, [buffer_length]  ; Imprimir solo el texto capturado
IMPRIMIR_CARACTER:
    lodsb              ; Cargar el siguiente carácter en AL
    cmp al, 0          ; Verificar fin del texto
    je fin_impresion
    mov ah, 0Eh        ; Función de BIOS para imprimir el carácter
    mov bl, 0Ch        ; Cambiar el color del texto a blanco
    int 10h
    loop IMPRIMIR_CARACTER
fin_impresion:
    ret
IMPRIMIR_BUFFER ENDP

; Mostrar un mensaje en la fila 25, columna 2
MOSTRAR_MENSAJE PROC
    local mensaje
    lea si, mensaje
    mov dh, 25         ; Fila 25
    mov dl, 2          ; Columna 2
    mov ah, 02h
    int 10h            ; Mover el cursor

    mov ah, 09h        ; Función DOS para imprimir el mensaje
    lea dx, mensaje
    int 21h
    ret
MOSTRAR_MENSAJE ENDP

; Guarda el bosquejo (HEX.TXT) (TEMPORAL)
GUARDAR_BOSQUEJO PROC
    mov al, [buffer]
    cmp al, ' '
    je SIN_BUFFER_GUARDAR
    jmp SKIP_SIN_BUFFER_GUARDAR
SIN_BUFFER_GUARDAR:
    ret
SKIP_SIN_BUFFER_GUARDAR:
    lea si, buffer
    mov cx, [buffer_length]
    add si, cx
    sub si, 4
    cmp cx, 4
    jb ADD_EXTENSION_SAVE
    ; Comparar los últimos 4 caracteres con ".txt"
    mov al, [si]
    cmp al, '.'
    jne ADD_EXTENSION_SAVE
    inc si
    mov al, [si]
    cmp al, 't'
    jne ADD_EXTENSION_SAVE
    inc si
    mov al, [si]
    cmp al, 'x'
    jne ADD_EXTENSION_SAVE
    inc si
    mov al, [si]
    cmp al, 't'
    jne ADD_EXTENSION_SAVE
    jmp CREATE_FILE
ADD_EXTENSION_SAVE:
    ; Añadir la extensión .txt al buffer
    lea si, buffer
    mov cx, [buffer_length]
    add si, cx
    mov byte ptr [si], '.'
    inc si
    mov byte ptr [si], 't'
    inc si
    mov byte ptr [si], 'x'
    inc si
    mov byte ptr [si], 't'
    inc si
    mov byte ptr [si], 0
    add word ptr [buffer_length], 4
CREATE_FILE:
    DIBUJAR_RECTANGULO 60, 42, 360, 30, 00h ; Limpiar lo que tenía el cuadro
    IMPRIMIR_TEXTO 3, 20, buffer, 2Fh      ; Imprimir el texto contenido dentro del buffer
    call IMPRIMIR_BUFFER

    lea dx, buffer         ; Usar el nombre del archivo almacenado en el buffer
    mov ah, 3Ch            ; Función DOS: Crear archivo
    xor cx, cx             ; Atributos del archivo (ninguno)
    int 21h
    jc ERROR_GUARDAR       ; Si hay error, saltar a manejo de error
    mov [file_handle], ax  ; Guardar el handle del archivo

    mov di, 90             ; Inicializar Y en 90 (coordenada inicial)
GUARDAR_FILAS:
    mov si, 136            ; Inicializar X en 136 (coordenada inicial)
GUARDAR_COLUMNAS:
    mov ah, 0Dh            ; Función BIOS: Leer color de píxel
    mov bh, 0              ; Página de pantalla 0
    mov cx, si             ; Posición X
    mov dx, di             ; Posición Y
    int 10h                ; Llamada a BIOS para leer el color

    call CONVERTIR_COLOR_A_HEX
    call ESCRIBIR_COLOR_EN_ARCHIVO

    inc si
    cmp si, 136 + 398      ; Limitar hasta el ancho de 398 píxeles
    jb GUARDAR_COLUMNAS

    mov dx, offset arroba  ; Cargar '@' en DX
    mov ah, 40h
    mov bx, [file_handle]
    mov cx, 1
    int 21h

    lea dx, salto_linea
    mov ah, 40h
    mov bx, [file_handle]
    mov cx, 2
    int 21h

    inc di
    cmp di, 390            ; Limitar hasta la altura de 300 píxeles
    jb GUARDAR_FILAS

    mov dx, offset porcentaje ; Cargar '%' en DX
    mov ah, 40h
    mov bx, [file_handle]
    mov cx, 1
    int 21h

    mov ah, 3Eh          ; Función DOS: Cerrar archivo
    mov bx, [file_handle]
    int 21h
ERROR_GUARDAR:
    ret
GUARDAR_BOSQUEJO ENDP

; Convertir el valor en AL (color del píxel) a dos dígitos hexadecimales y guardarlo en el buffer
CONVERTIR_COLOR_A_HEX PROC
    mov ah, al             ; Duplicar el valor en AH para trabajar con los dos dígitos
    shr al, 4              ; Obtener el primer dígito (4 bits altos)
    call IMPRIMIR_HEX_DIGITO ; Convertir y guardar en el buffer
    mov al, ah             ; Obtener el segundo dígito (4 bits bajos)
    and al, 0Fh            ; Enmascarar los bits bajos
    call IMPRIMIR_HEX_DIGITO ; Convertir y guardar en el buffer
    ret
CONVERTIR_COLOR_A_HEX ENDP

IMPRIMIR_HEX_DIGITO PROC
    cmp al, 9
    jbe ES_DIGITO
    add al, 7              ; Ajustar para A-F
ES_DIGITO:
    add al, '0'            ; Convertir a ASCII
    mov [color_buffer], al ; Guardar el valor en el buffer
    ret
IMPRIMIR_HEX_DIGITO ENDP

; Escribir el color en el archivo
ESCRIBIR_COLOR_EN_ARCHIVO PROC
    lea dx, color_buffer
    mov ah, 40h
    mov bx, [file_handle]
    mov cx, 1              ; Longitud de 2 bytes (cada valor hexadecimal es de 2 dígitos)
    int 21h
    ret
ESCRIBIR_COLOR_EN_ARCHIVO ENDP

INSERTAR_IMAGEN PROC
    ; Verificar si el buffer está vacío
    mov al, [buffer]
    cmp al, ' '
    je SIN_BUFFER_INSERTAR
    jmp SKIP_SIN_BUFFER_INSERTAR

SIN_BUFFER_INSERTAR:
    ret

SKIP_SIN_BUFFER_INSERTAR:
    lea si, buffer
    mov cx, [buffer_length]
    add si, cx
    sub si, 4
    cmp cx, 4
    jb ADD_EXTENSION_INSERTAR

    mov al, [si]
    cmp al, '.'
    jne ADD_EXTENSION_INSERTAR
    inc si
    mov al, [si]
    cmp al, 't'
    jne ADD_EXTENSION_INSERTAR
    inc si
    mov al, [si]
    cmp al, 'x'
    jne ADD_EXTENSION_INSERTAR
    inc si
    mov al, [si]
    cmp al, 't'
    jne ADD_EXTENSION_INSERTAR

    jmp OPEN_FILE_INSERTAR

ADD_EXTENSION_INSERTAR:
    lea si, buffer
    mov cx, [buffer_length]
    add si, cx
    mov byte ptr [si], '.'
    inc si
    mov byte ptr [si], 't'
    inc si
    mov byte ptr [si], 'x'
    inc si
    mov byte ptr [si], 't'
    inc si
    mov byte ptr [si], 0
    add word ptr [buffer_length], 4

OPEN_FILE_INSERTAR:
    mov ah, 3Dh           ; Abrir archivo en modo de lectura
    lea dx, buffer
    mov al, 0
    int 21h
    jc ERROR_CARGAR1
    mov [file_handle], ax

    mov di, [current_y]         ; Posición Y inicial
CARGAR_FILAS1:
    mov si, [current_x]         ; Posición X inicial para cada línea
    mov cx, 534                 ; Límite máximo de X en pantalla

CARGAR_COLUMNAS1:
    mov ah, 3Fh
    lea dx, letter_buffer
    mov bx, [file_handle]
    mov cx, 1
    int 21h
    cmp ax, 1
    jne FIN_LECTURA1

    mov al, [letter_buffer]
    
    cmp al, '@'
    je CAMBIAR_FILA1

    cmp al, 10
    je CARGAR_COLUMNAS1
    cmp al, 13
    je CARGAR_COLUMNAS1
    cmp al, ' '
    je CARGAR_COLUMNAS1

    call CONVERTIR_HEX_A_COLOR
    cmp si, 534               ; Si estamos dentro del límite de X, pintar
    jb PAINT_PIXEL

    jmp CARGAR_COLUMNAS1

PAINT_PIXEL:
    PINTA_PIXEL si, di, al
    inc si                    ; Moverse a la siguiente posición X
    jmp CARGAR_COLUMNAS1      ; Continuar leyendo el archivo

CAMBIAR_FILA1:
    inc di
    cmp di, 389               ; Verificar si estamos dentro del límite de Y
    jbe CARGAR_FILAS1         ; Continuar si estamos dentro de los límites

FIN_LECTURA1:
    mov ah, 3Eh
    mov bx, [file_handle]
    int 21h
    ret

ERROR_CARGAR1:
    ret
INSERTAR_IMAGEN ENDP



; Cargar un bosquejo (HEX.TXT)
CARGAR_BOSQUEJO PROC
    mov al, [buffer]
    cmp al, ' '
    je SIN_BUFFER_CARGAR
    jmp SKIP_SIN_BUFFER_CARGAR

SIN_BUFFER_CARGAR:
    ret

SKIP_SIN_BUFFER_CARGAR:
    ; Limpiar el bosquejo anterior
    DIBUJAR_RECTANGULO 136, 90, 398, 300, 0Fh ; Dibujar cuadrado azul
    DIBUJAR_RECTANGULO 60, 42, 360, 30, 00h   ; Limpiar el cuadro
    ; Verificar si el buffer ya contiene la extensión .txt
    lea si, buffer
    mov cx, [buffer_length]
    add si, cx
    sub si, 4
    cmp cx, 4
    jb ADD_EXTENSION_LOAD

    ; Comparar los últimos 4 caracteres con ".txt"
    mov al, [si]
    cmp al, '.'
    jne ADD_EXTENSION_LOAD
    inc si
    mov al, [si]
    cmp al, 't'
    jne ADD_EXTENSION_LOAD
    inc si
    mov al, [si]
    cmp al, 'x'
    jne ADD_EXTENSION_LOAD
    inc si
    mov al, [si]
    cmp al, 't'
    jne ADD_EXTENSION_LOAD

    jmp OPEN_FILE

ADD_EXTENSION_LOAD:
    ; Añadir la extensión .txt al buffer
    lea si, buffer
    mov cx, [buffer_length]
    add si, cx
    mov byte ptr [si], '.'
    inc si
    mov byte ptr [si], 't'
    inc si
    mov byte ptr [si], 'x'
    inc si
    mov byte ptr [si], 't'
    inc si
    mov byte ptr [si], 0
    add word ptr [buffer_length], 4

OPEN_FILE:
    ; Repintar el cuadro con nombre
    DIBUJAR_RECTANGULO 60, 42, 360, 30, 00h ; Limpiar el cuadro
    IMPRIMIR_TEXTO 3, 20, buffer, 2Fh       ; Imprimir el texto del buffer
    call IMPRIMIR_BUFFER

    ; Abrir el archivo en modo de lectura
    mov ah, 3Dh           ; Función DOS: Abrir archivo
    lea dx, buffer        ; Nombre del archivo
    mov al, 0             ; Modo de lectura
    int 21h
    jc ERROR_CARGAR       ; Manejo de error si falla
    mov [file_handle], ax ; Guardar el handle del archivo

    ; Recorrer el área del rectángulo (136, 90, 398, 300)
    mov di, 90            ; Inicializar Y en 90
CARGAR_FILAS:
    mov si, 136           ; Inicializar X en 136
CARGAR_COLUMNAS:
    ; Leer el color del archivo (1 dígito hexadecimal o '@')
    mov ah, 3Fh           ; Función DOS: Leer archivo
    lea dx, letter_buffer        ; Leer en el buffer
    mov bx, [file_handle]
    mov cx, 1             ; Leer 1 byte
    int 21h
    cmp ax, 1             ; Verificar si se leyó 1 byte
    jne FIN_LECTURA       ; Salir del loop si no se leyó

    ; Verificar si el byte leído es '@' (fin de línea)
    mov al, [letter_buFfer]
    cmp al, '@'
    je CAMBIAR_FILA

    ; Ignorar saltos de línea y espacios
    cmp al, 10            ; Verificar si es '\n'
    je CARGAR_COLUMNAS   
    cmp al, 13            ; Verificar si es '\r'
    je CARGAR_COLUMNAS   
    cmp al, ' '
    je CARGAR_COLUMNAS   

    ; Convertir el valor leído de hexadecimal a un byte de color
    call CONVERTIR_HEX_A_COLOR

    ; Dibujar el píxel en la posición (si, di)
    PINTA_PIXEL si, di, al ; 'al' contiene el valor del color

    ; Incrementar X y continuar
    inc si
    cmp si, 534           ; Limitar hasta el ancho de 398 píxeles
    jb CARGAR_COLUMNAS
    jmp CARGAR_FILAS

CAMBIAR_FILA:
    ; Cambiar a la siguiente fila
    inc di
    cmp di, 390           ; Limitar hasta la altura de 300 píxeles
    jbe CARGAR_FILAS

FIN_LECTURA:
    ; Cerrar el archivo
    mov ah, 3Eh           ; Función DOS: Cerrar archivo
    mov bx, [file_handle]
    int 21h
    ret

ERROR_CARGAR:
    ret
CARGAR_BOSQUEJO ENDP

; Convierte de hex a un color para AL
CONVERTIR_HEX_A_COLOR PROC
    mov al, [letter_buffer]     ; Cargar el dígito hexadecimal
    call HEX_DIGITO_A_BYTE ; Convertir a un valor numérico
    ret
CONVERTIR_HEX_A_COLOR ENDP

HEX_DIGITO_A_BYTE PROC
    ; Convierte un carácter hexadecimal (AL) a su valor numérico
    cmp al, '9'
    jbe ES_UN_DIGITO     ; Si es 0-9, saltar a ES_UN_DIGITO
    sub al, 7            ; Ajustar para A-F

ES_UN_DIGITO:
    sub al, '0'          ; Convertir de ASCII a valor numérico
    ret
HEX_DIGITO_A_BYTE ENDP

; Dibuja símbolos de flecha dentro de los cuadros
DRAW_ARROWS PROC
    ; Dibuja flecha izquierda (<) en (459, 445)
    PINTA_PIXEL 469, 460, 00h
    PINTA_PIXEL 470, 459, 00h
    PINTA_PIXEL 470, 461, 00h
    PINTA_PIXEL 471, 458, 00h
    PINTA_PIXEL 471, 462, 00h
    PINTA_PIXEL 472, 457, 00h
    PINTA_PIXEL 472, 463, 00h
    PINTA_PIXEL 473, 456, 00h
    PINTA_PIXEL 473, 464, 00h
    PINTA_PIXEL 474, 455, 00h
    PINTA_PIXEL 474, 465, 00h

    ; Dibuja flecha derecha (>) en (494, 445)
    PINTA_PIXEL 507, 460, 00h
    PINTA_PIXEL 506, 459, 00h
    PINTA_PIXEL 506, 461, 00h
    PINTA_PIXEL 505, 458, 00h
    PINTA_PIXEL 505, 462, 00h
    PINTA_PIXEL 504, 457, 00h
    PINTA_PIXEL 504, 463, 00h
    PINTA_PIXEL 503, 456, 00h
    PINTA_PIXEL 503, 464, 00h
    PINTA_PIXEL 502, 455, 00h
    PINTA_PIXEL 502, 465, 00h

    ; Dibuja flecha arriba (^) en (529, 445)
    PINTA_PIXEL 544, 455, 00h
    PINTA_PIXEL 543, 456, 00h
    PINTA_PIXEL 545, 456, 00h
    PINTA_PIXEL 542, 457, 00h
    PINTA_PIXEL 546, 457, 00h
    PINTA_PIXEL 541, 458, 00h
    PINTA_PIXEL 547, 458, 00h
    PINTA_PIXEL 540, 459, 00h
    PINTA_PIXEL 548, 459, 00h
    PINTA_PIXEL 539, 460, 00h
    PINTA_PIXEL 549, 460, 00h

    ; Dibuja flecha abajo (v) en (564, 445)
    PINTA_PIXEL 579, 465, 00h
    PINTA_PIXEL 578, 464, 00h
    PINTA_PIXEL 580, 464, 00h
    PINTA_PIXEL 577, 463, 00h
    PINTA_PIXEL 581, 463, 00h
    PINTA_PIXEL 576, 462, 00h
    PINTA_PIXEL 582, 462, 00h
    PINTA_PIXEL 575, 461, 00h
    PINTA_PIXEL 583, 461, 00h
    PINTA_PIXEL 574, 460, 00h
    PINTA_PIXEL 584, 460, 00h

    ret
DRAW_ARROWS ENDP


start: ; ################################################################<<<<START>>>>################################################################
    ; Inicializar segmentos de datos
mov ax, @DATA
mov ds, ax

; Cambiar a modo gráfico 12h (640x480, 16 colores)
mov ax, 0012h
int 10h

; Rellenar la pantalla con el color 08h
RELLENAR_PANTALLA 08h 

; Para líneas horizontales o renglones en papel
mov dx, 0
DRAW_LINES:
    mov cx, 0
DRAW_HORIZONTAL_LINE:
    PINTA_PIXEL cx, dx, 00h  
    inc cx
    cmp cx, 640
    jb DRAW_HORIZONTAL_LINE
    add dx, 40               
    cmp dx, 480
    jb DRAW_LINES

; Dibujar los rectángulos y cuadrados
DIBUJAR_RECTANGULO 60, 42, 360, 30, 00h ; Nombre Dibujo
DIBUJAR_RECTANGULO 425, 42, 110, 30, 00h ; Limpiar btn
DIBUJAR_RECTANGULO 550, 90, 60, 300, 00h  
DIBUJAR_RECTANGULO 136, 90, 398, 300, 0Fh ; Cuadro de dibujo
DIBUJAR_RECTANGULO 60, 90, 60, 300, 00h

; Dibujar cuadrados de colores
DIBUJAR_CUADRADO 564, 350, 30, 01h ; Primer cuadrado rojo
DIBUJAR_CUADRADO 564, 300, 30, 0Eh ; Segundo cuadrado
DIBUJAR_CUADRADO 564, 250, 30, 04h ; Tercer cuadrado
DIBUJAR_CUADRADO 564, 200, 30, 05h ; Cuarto cuadrado
DIBUJAR_CUADRADO 564, 150, 30, 06h ; Quinto cuadrado
DIBUJAR_CUADRADO 564, 100, 30, 07h ; Sexto cuadrado

DIBUJAR_CUADRADO 75, 350, 30, 08h ; Primer cuadrado rojo
DIBUJAR_CUADRADO 75, 300, 30, 09h ; Segundo cuadrado
DIBUJAR_CUADRADO 75, 250, 30, 0Ah ; Tercer cuadrado
DIBUJAR_CUADRADO 75, 200, 30, 0Bh ; Cuarto cuadrado
DIBUJAR_CUADRADO 75, 150, 30, 0Ch ; Quinto cuadrado
DIBUJAR_CUADRADO 75, 100, 30, 0Fh ; Sexto cuadrado

; Dibuja flechas de dirección
DIBUJAR_CUADRADO 564, 445, 30, 0Fh ; ABAJO
DIBUJAR_CUADRADO 529, 445, 30, 0Fh ; ARRIBA
DIBUJAR_CUADRADO 494, 445, 30, 0Fh ; DERECHA
DIBUJAR_CUADRADO 459, 445, 30, 0Fh ; IZQUIERDA
call DRAW_ARROWS ; Para dibujar flechas

DIBUJAR_CUADRADO 390, 445, 30, 0Fh ; PINTAR FONDO
DIBUJAR_CUADRADO 355, 445, 30, [color_pixel] ; CUADRADO DE COLOR
DIBUJAR_CUADRADO 335, 460, 15, [old_color_pixel] ; CUADRADO DE COLOR DE FONDO PASADO

; Dibujar esquinas
; Top-left corner
PINTA_PIXEL 395, 450, 00h
PINTA_PIXEL 396, 450, 00h
PINTA_PIXEL 397, 450, 00h
PINTA_PIXEL 395, 451, 00h
PINTA_PIXEL 395, 452, 00h
PINTA_PIXEL 395, 453, 00h
; Top-right corner
PINTA_PIXEL 414, 450, 00h
PINTA_PIXEL 413, 450, 00h
PINTA_PIXEL 412, 450, 00h
PINTA_PIXEL 414, 451, 00h
PINTA_PIXEL 414, 452, 00h
PINTA_PIXEL 414, 453, 00h
; Bottom-left corner
PINTA_PIXEL 395, 468, 00h
PINTA_PIXEL 396, 468, 00h
PINTA_PIXEL 397, 468, 00h
PINTA_PIXEL 395, 466, 00h
PINTA_PIXEL 395, 467, 00h
; Bottom-right corner
PINTA_PIXEL 414, 468, 00h
PINTA_PIXEL 413, 468, 00h
PINTA_PIXEL 412, 468, 00h
PINTA_PIXEL 414, 466, 00h
PINTA_PIXEL 414, 467, 00h

; Botones y campos de texto
DIBUJAR_RECTANGULO 15, 410, 150, 30, 00h  ; Guardar Bosquejo btn
DIBUJAR_RECTANGULO 15, 445, 150, 30, 00h  
DIBUJAR_RECTANGULO 175, 410, 280, 30, 00h ; Campo de texto
DIBUJAR_RECTANGULO 465, 410, 145, 30, 00h ; Insertar imagen

; Imprimir textos
IMPRIMIR_TEXTO  3, 55, mensaje1, 1Fh  ; Limpiar
IMPRIMIR_TEXTO 3, 20, mensaje2, 2Fh   ; Dibujo sin nombre
IMPRIMIR_TEXTO  26, 2, mensaje3, 1Fh  ; Guardar Bosquejo
IMPRIMIR_TEXTO 28, 2, mensaje4, 2Fh   ; Cargar Bosquejo
IMPRIMIR_TEXTO 26, 32, mensaje5, 2Fh  ; Campo de texto
IMPRIMIR_TEXTO 26, 59, mensaje6, 2Fh  ; Campo de texto

; Dibujar bordes alrededor de elementos de UI
DIBUJAR_BORDE_RECTANGULO 59, 41, 362, 32, 0Fh ; Borde "Nombre Dibujo"
DIBUJAR_BORDE_RECTANGULO 424, 41, 112, 32, 0Fh ; Borde "Limpiar btn"
DIBUJAR_BORDE_RECTANGULO 549, 89, 62, 302, 0Fh ; Borde "Cuadro de dibujo"
DIBUJAR_BORDE_RECTANGULO 59, 89, 62, 302, 0Fh ; Borde "Cuadro de dibujo izquierdo"
DIBUJAR_BORDE_RECTANGULO 528, 444, 32, 32, 00h ; Borde "ARRIBA"
DIBUJAR_BORDE_RECTANGULO 493, 444, 32, 32, 00h ; Borde "DERECHA"
DIBUJAR_BORDE_RECTANGULO 458, 444, 32, 32, 00h ; Borde "IZQUIERDA"
DIBUJAR_BORDE_RECTANGULO 563, 444, 32, 32, 00h ; Borde "ABAJO"
DIBUJAR_BORDE_RECTANGULO 389, 444, 32, 32, 00h ; Borde "PINTAR FONDO"
DIBUJAR_BORDE_RECTANGULO 14, 409, 152, 32, 0Fh ; Borde "Guardar Bosquejo btn"
DIBUJAR_BORDE_RECTANGULO 14, 444, 152, 32, 0Fh ; Borde "Cargar Bosquejo btn"
DIBUJAR_BORDE_RECTANGULO 174, 409, 282, 32, 0Fh ; Borde "Campo de texto"
DIBUJAR_BORDE_RECTANGULO 464, 409, 147, 32, 0Fh ; Borde "Insertar imagen"
DIBUJAR_BORDE_RECTANGULO 354, 444, 32, 32, 00h ; Borde en el cuadrado de color
DIBUJAR_BORDE_RECTANGULO 334, 459, 17, 17, 00h ; Borde alrededor del cuadrado de color de fondo pasado

call INIT_MOUSE

MAIN_LOOP:; ################################################################<<<<MAIN LOOP>>>>################################################################
    ; Detectar clic del mouse y pintar
    call DIBUJAR_MOUSE_PIXEL
    ; Verificaciones de input
    VERIFICAR_CAMPO_TEXTO
    VERIFICAR_LIMPIAR
    VERIFICAR_GUARDAR
    VERIFICAR_CARGAR
    VERIFICAR_INSERTAR
    VERIFICAR_ABAJO
    VERIFICAR_DERECHA
    VERIFICAR_IZQUIERDA
    VERIFICAR_ARRIBA
    VERIFICAR_PINTAR_FONDO
    ; Capturar entrada de texto
    call CAPTURAR_ENTRADA
    ; Control de teclas (WASD)
    call MOVER_PIXEL
    jmp MAIN_LOOP
SALIR:
; Terminar el programa
    mov ah, 4Ch
    int 21h
END start