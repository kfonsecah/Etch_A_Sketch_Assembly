.MODEL small
.STACK 100h

.DATA ;################################################################<<<<DATA SECTION>>>>############################################################
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
    

    buffer db 100 dup(' ')  ; Espacio para almacenar hasta 32 caracteres de texto
    buffer_length dw 0      ; Longitud actual del texto en el buffer
    capture_enabled db 0    ; 0 = No capturar, 1 = Capturar entrada

    current_x dw 65535    ; Coordenada X inicial (valor fuera de la pantalla)
    current_y dw 65535    ; Coordenada Y inicial (centro de la pantalla)
    color_pixel db 00h 

    mouse_x dw 0          ; Coordenada X del mouse
    mouse_y dw 0          ; Coordenada Y del mouse

    mouse_buttons db 0    ; Estado del botón del mouse

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
    square_12_color db 0Fh 

    ; Nombre del archivo de imagen
    image_file_name db 'image.txt', 0
    nombre_archivo db '.txt', 0

    file_handle dw 0       ; Handle para el archivo
    buffer_guardado db 5 dup(0)  ; Buffer para almacenar coordenadas (x, y) y color del píxel

    ; Carácteres constantes
    coma db ',', 0            ; Coma como separador
    salto_linea db 13, 10, 0  ; Salto de línea (retorno de carro + línea nueva)
    arroba db '@', 0
    porcentaje db '%', 0

    fondo_color db 0Fh

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

; MACRO para verificar si el clic está dentro de un cuadrado y cambiar el color
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
    mov al, color          ; Cambiar el color si está dentro del cuadrado
    mov [color_pixel], al
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

    ; Si el clic está dentro del área del botón "Limpiar" y el botón izquierdo está presionado, dibujar el rectángulo azul
    DIBUJAR_RECTANGULO 136, 90, 398, 300, 0Fh ; Dibujar cuadrado azul (01h es azul)

    ; Limpiar el buffer que contiene el nombre del archivo
    lea di, buffer
    mov cx, 100            ; Tamaño del buffer
    xor al, al             ; Valor 0    
    ; rep depende de cx, y stosb hace lo usual con al, entonces se rellena el bloque con 0's
    ; Es esto o nada para reestablecer memoria sin que explote
    rep stosb              ; Llenar el buffer con 0
    mov word ptr [buffer_length], 0 ; Resetear la longitud del buffer

    ; Restablecer el nombre del bosquejo en el área de texto
    IMPRIMIR_TEXTO 3, 20, mensaje2, 2Fh 

FUERA_LIMPIAR:
    endm

VERIFICAR_GUARDAR macro
    cmp [mouse_x], 15       ; Verificar si el mouse está dentro del área x del botón
    jb FUERA_GUARDAR
    cmp [mouse_x], 165      ; Limitar en la coordenada x del botón
    ja FUERA_GUARDAR
    cmp [mouse_y], 410      ; Verificar si el mouse está dentro del área y del botón
    jb FUERA_GUARDAR
    cmp [mouse_y], 440      ; Limitar en la coordenada y del botón
    ja FUERA_GUARDAR

    ; Verificar si el botón izquierdo del mouse fue presionado
    test [mouse_buttons], 1
    jz FUERA_GUARDAR

    ; Si el clic está dentro del área del botón "Guardar", llamar a GUARDAR_BOSQUEJO
    call GUARDAR_BOSQUEJO
FUERA_GUARDAR:
    endm

; Macro para verificar si el click está dentro del botón cargar
VERIFICAR_CARGAR macro
    cmp [mouse_x], 15       ; Verificar si el mouse está dentro del área x del botón
    jb FUERA_CARGAR
    cmp [mouse_x], 165      ; Limitar en la coordenada x del botón
    ja FUERA_CARGAR
    cmp [mouse_y], 445      ; Verificar si el mouse está dentro del área y del botón
    jb FUERA_CARGAR
    cmp [mouse_y], 475      ; Limitar en la coordenada y del botón
    ja FUERA_CARGAR

    ; Verificar si el botón izquierdo del mouse fue presionado
    test [mouse_buttons], 1
    jz FUERA_CARGAR

    ; Si el clic está dentro del área del botón "Cargar", llamar a CARGAR_BOSQUEJO
    call CARGAR_BOSQUEJO
FUERA_CARGAR:
    endm

; Macro para verificar si el click está dentro del botón insertar
VERIFICAR_INSERTAR macro
    cmp [mouse_x], 465       ; Verificar si el mouse está dentro del área x del botón
    jb FUERA_INSERTAR
    cmp [mouse_x], 610       ; Limitar en la coordenada x del botón
    ja FUERA_INSERTAR
    cmp [mouse_y], 410       ; Verificar si el mouse está dentro del área y del botón
    jb FUERA_INSERTAR
    cmp [mouse_y], 440       ; Limitar en la coordenada y del botón
    ja FUERA_INSERTAR

    ; Verificar si el botón izquierdo del mouse fue presionado
    test [mouse_buttons], 1
    jz FUERA_INSERTAR

    ; Si el clic está dentro del área del botón "Insertar imagen", llamar a INSERTAR_IMAGEN
    call INSERTAR_IMAGEN
FUERA_INSERTAR:
    endm

; Macro para verificar si el clic está en el campo de texto
VERIFICAR_CAMPO_TEXTO macro
    cmp [mouse_x], 175
    jb FUERA_CAMPO_TEXTO
    cmp [mouse_x], 455     ; Limite derecho del área del campo de texto
    ja FUERA_CAMPO_TEXTO
    cmp [mouse_y], 410
    jb FUERA_CAMPO_TEXTO
    cmp [mouse_y], 440     ; Limite inferior del área del campo de texto
    ja FUERA_CAMPO_TEXTO

    ; Verificar si el botón izquierdo del mouse fue presionado (solo una vez)
    test [mouse_buttons], 1
    jz fin_verificar ; Si el botón no está presionado, no hacer nada

    ; Activar la captura de texto
    mov [capture_enabled], 1
    jmp FIN_VERIFICAR

FUERA_CAMPO_TEXTO:
    ; Verificar si se hizo clic fuera del campo de texto para desactivar la captura
    test [mouse_buttons], 1
    jz FIN_VERIFICAR
    mov [capture_enabled], 0  ; Desactivar la captura de texto

FIN_VERIFICAR:
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


; Esconder el cursor del mouse
ESCONDER_MOUSE PROC
    mov ax, 02h            ; Llamada a la función para esconder el cursor
    int 33h
    ret
ESCONDER_MOUSE ENDP

; Mostrar el cursor del mouse
MOSTRAR_MOUSE PROC
    mov ax, 01h            ; Llamada a la función para mostrar el cursor
    int 33h
    ret
MOSTRAR_MOUSE ENDP

; Obtener las coordenadas del mouse y el estado de los botones
GET_MOUSE_STATUS PROC
    mov ax, 03h            ; Obtener las coordenadas del mouse
    int 33h
    mov [mouse_buttons], bl
    mov [mouse_x], cx
    mov [mouse_y], dx

    ; Dibujar un píxel en la posición del mouse para representarlo
      ; Dibuja el cursor como un píxel blanco
    ret
GET_MOUSE_STATUS ENDP

; Verificar si el clic está dentro del área de dibujo (cuadro en 100, 300 de 100x100)
VERIFICAR_AREA_DIBUJO PROC
    cmp [mouse_x], 136       ; Verificar si mouse_x está a la izquierda del límite del cuadro de dibujo
    jb NO_CLICK_DIBUJO       ; Si está a la izquierda, no permitir dibujo
    cmp [mouse_x], 533       ; Verificar si mouse_x está a la derecha del límite del cuadro de dibujo
    ja NO_CLICK_DIBUJO       ; Si está a la derecha, no permitir dibujo
    cmp [mouse_y], 90       ; Verificar si mouse_y está arriba del límite del cuadro de dibujo
    jb NO_CLICK_DIBUJO       ; Si está arriba, no permitir dibujo
    cmp [mouse_y], 389     ; Verificar si mouse_y está abajo del límite del cuadro de dibujo
    ja NO_CLICK_DIBUJO       ; Si está abajo, no permitir dibujo
    mov ax, 1                ; Si está dentro, permitir dibujo
    ret                      ; Si está dentro, permitir dibujo

NO_CLICK_DIBUJO:
    mov ax, 0                ; Si está fuera, bloquear el dibujo
    ret
VERIFICAR_AREA_DIBUJO ENDP

; Dibujar el píxel en la nueva posición del mouse
DIBUJAR_MOUSE_PIXEL PROC
    call GET_MOUSE_STATUS

    ; Verificar los cuadrados de colores usando la macro VERIFICAR_CUADRADO
    VERIFICAR_CUADRADO 564, 594, 350, 380, [square_1_color];AZUL
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

    ; Verificar si el botón izquierdo del mouse fue presionado
    test [mouse_buttons], 1
    jz NO_CLICK_MOUSE

    ; Verificar si el clic está dentro del área de dibujo
    call VERIFICAR_AREA_DIBUJO
    cmp ax, 1
    jne NO_CLICK_MOUSE  ; Si ax no es 1, no pintar

    ; Guardar la posición del clic como la nueva posición del píxel
    mov ax, [mouse_x]
    mov [current_x], ax
    mov ax, [mouse_y]
    mov [current_y], ax

    ; Dibujar el píxel en la nueva posición
    PINTA_PIXEL [current_x], [current_y], [color_pixel]

NO_CLICK_MOUSE:
    ret
DIBUJAR_MOUSE_PIXEL ENDP

; Mover el píxel con las teclas WASD, dejando un trazo
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

; Para capturar la entrada en modo consola mid-video 
CAPTURAR_ENTRADA PROC
    cmp [capture_enabled], 1  ; Verificar si la captura está habilitada
    jne NO_CAPTURE_ACTIVE     ; Si no está habilitada, continuar sin capturar

    mov ah, 01h               ; Verificar si hay una tecla presionada
    int 16h
    jz NO_KEY_PRESSED2        ; Si no hay tecla presionada, salir

    mov ah, 00h
    int 16h                   ; Leer la tecla presionada
    cmp al, 13                ; Verificar si se presionó Enter (código ASCII 13)
    je NO_KEY_PRESSED2        ; Si es Enter, no hacer nada

    cmp al, 8                 ; Verificar si se presionó Backspace (código ASCII 8)
    je BORRAR_CARACTER        ; Si es Backspace, ir a borrar carácter

    cmp al, 27                ; Verificar si se presionó Esc (código ASCII 27)
    je NO_KEY_PRESSED2        ; Ignorar Esc para evitar salir

    ; Verificar si el buffer está lleno
    cmp [buffer_length], 10   ; Verificar si el buffer está lleno (máximo 15 caracteres)
    jge NO_KEY_PRESSED2       ; Si está lleno, no hacer nada y seguir en el loop

    ; Guardar el carácter en el buffer
    mov si, [buffer_length]
    mov [buffer + si], al
    inc word ptr [buffer_length]

    ; Imprimir el texto actualizado
    call IMPRIMIR_BUFFER
    jmp NO_KEY_PRESSED2

BORRAR_CARACTER:
    cmp [buffer_length], 0    ; Verificar si el buffer está vacío
    je NO_KEY_PRESSED2        ; Si está vacío, no hacer nada

    ; Reducir la longitud del buffer
    dec word ptr [buffer_length]
    mov si, [buffer_length]
    
    ; Reemplazar el último carácter con un espacio en blanco
    mov byte ptr [buffer + si], ' '

    ; Imprimir el texto actualizado
    call IMPRIMIR_BUFFER
    jmp NO_KEY_PRESSED2

NO_CAPTURE_ACTIVE:
    ; No hay captura activa, continuar con el programa normalmente
    ret

NO_KEY_PRESSED2:
    ret
CAPTURAR_ENTRADA ENDP

; Saca un buffered-output al cursor
IMPRIMIR_BUFFER PROC
    ; Mueve el cursor a la posición del campo de texto (fila 26, columna 32)
    mov ah, 02h
    mov bh, 0
    mov dh, 26              ; Fila 26, donde está el campo de texto
    mov dl, 32              ; Columna 32
    int 10h                 ; Llamada a BIOS para mover el cursor

    ; Borrar la línea completa del campo de texto
    mov cx, 15              ; Longitud máxima del campo de texto
    mov al, ' '             ; Carácter de espacio
BORRAR_TEXTO:
    mov ah, 0Eh             ; Función de BIOS para imprimir el carácter
    int 10h
    loop BORRAR_TEXTO

    ; Mueve el cursor a la posición inicial del campo de texto de nuevo
    mov ah, 02h
    mov bh, 0
    mov dh, 26
    mov dl, 32
    int 10h

    ; Imprimir el contenido actual del buffer
    mov si, offset buffer
    mov cx, [buffer_length]  ; Imprimir solo el texto capturado
IMPRIMIR_CARACTER:
    lodsb                   ; Cargar el siguiente carácter en AL
    cmp al, 0               ; Verificar fin del texto
    je fin_impresion
    mov ah, 0Eh             ; Función de BIOS para imprimir el carácter
    mov al, al              ; El carácter que se va a imprimir
    mov bl, 0Ch             ; Cambiar el color del texto a blanco (o el color que prefieras)
    int 10h
    loop IMPRIMIR_CARACTER

fin_impresion:
    ret
IMPRIMIR_BUFFER ENDP

    ; Mostrar un mensaje en la fila 25, columna 2
MOSTRAR_MENSAJE PROC
    local mensaje
    lea si, mensaje
    mov dh, 25           ; Fila 25
    mov dl, 2            ; Columna 2
    mov ah, 02h
    int 10h              ; Mover el cursor

    mov ah, 09h          ; Función DOS para imprimir el mensaje
    lea dx, mensaje
    int 21h
    ret
MOSTRAR_MENSAJE ENDP

    ; Guarda el bosquejo (HEX.TXT) (TEMPRAL OVERWRITE)
GUARDAR_BOSQUEJO PROC
    ; Definir el nombre del archivo directamente (TEMPORAL)
    mov dx, offset nombre_archivo ; Usar el nombre del archivo 'HEX.TXT'
    mov ah, 3Ch            ; Función DOS: Crear archivo
    xor cx, cx             ; Atributos del archivo (ninguno)
    int 21h
    jc ERROR_GUARDAR       ; Si hay error, saltar a manejo de error
    mov [file_handle], ax  ; Guardar el handle del archivo

    ; Recorrer el área del rectángulo (136, 90, 398, 300)
    mov di, 90           ; Inicializar Y en 90 (coordenada inicial)
GUARDAR_FILAS:
    mov si, 136          ; Inicializar X en 136 (coordenada inicial)
GUARDAR_COLUMNAS:
    ; Leer el color del píxel en (si, di)
    mov ah, 0Dh          ; Función BIOS: Leer color de píxel
    mov bh, 0            ; Página de pantalla 0
    mov cx, si           ; Posición X
    mov dx, di           ; Posición Y
    int 10h              ; Llamada a BIOS para leer el color
    ; El color del píxel se guarda en AL

    ; Convertir el color del píxel a formato hexadecimal y guardarlo
    call CONVERTIR_COLOR_A_HEX
    call ESCRIBIR_COLOR_EN_ARCHIVO

    ; Incrementar X y continuar
    inc si
    cmp si, 136 + 398    ; Limitar hasta el ancho de 398 píxeles
    jb GUARDAR_COLUMNAS

    ; Al final de la fila, añadir un '@'
    mov dx, offset arroba ; Cargar '@' en DX
    mov ah, 40h
    mov bx, [file_handle]
    mov cx, 1
    int 21h

    ; Guardar un salto de línea después de cada fila
    lea dx, salto_linea
    mov ah, 40h
    mov bx, [file_handle]
    mov cx, 2
    int 21h

    ; Incrementar Y y continuar
    inc di
    cmp di, 90 + 300     ; Limitar hasta la altura de 300 píxeles
    jb GUARDAR_FILAS

    ; Al final de todas las columnas, añadir un '%'
    mov dx, offset porcentaje ; Cargar '%' en DX
    mov ah, 40h
    mov bx, [file_handle]
    mov cx, 1
    int 21h

    ; Cerrar el archivo
    mov ah, 3Eh          ; Función DOS: Cerrar archivo
    mov bx, [file_handle]
    int 21h
    ret
ERROR_GUARDAR:
    ret
GUARDAR_BOSQUEJO ENDP

; Convertir el valor en AL (color del píxel) a dos dígitos hexadecimales y guardarlo en el buffer
CONVERTIR_COLOR_A_HEX PROC
    ; Convertir el valor en AL (color del píxel) a hexadecimal y guardarlo
    mov ah, al             ; Duplicar el valor en AH para trabajar con los dos dígitos
    shr al, 4              ; Obtener el primer dígito (4 bits altos)
    call IMPRIMIR_HEX_DIGITO ; Convertir y guardar en el buffer
    mov al, ah             ; Ahora obtener el segundo dígito (4 bits bajos)
    and al, 0Fh            ; Enmascarar los bits bajos
    call IMPRIMIR_HEX_DIGITO ; Convertir y guardar en el buffer
    ret
CONVERTIR_COLOR_A_HEX ENDP

IMPRIMIR_HEX_DIGITO PROC
    ; Convertir el valor de AL a un dígito hexadecimal ASCII
    cmp al, 9
    jbe ES_DIGITO
    add al, 7          ; Ajustar para A-F
ES_DIGITO:
    add al, '0'        ; Convertir a ASCII
    mov [buffer], al   ; Guardar el valor en el buffer
    ret
IMPRIMIR_HEX_DIGITO ENDP

; Escribir el color en el archivo
ESCRIBIR_COLOR_EN_ARCHIVO PROC
    ; Escribir el contenido del buffer (color) en el archivo
    lea dx, buffer
    mov ah, 40h
    mov bx, [file_handle]
    mov cx, 1               ; Longitud de 2 bytes (cada valor hexadecimal es de 2 dígitos)
    int 21h
    ret
ESCRIBIR_COLOR_EN_ARCHIVO ENDP

INSERTAR_IMAGEN PROC

    ; Abrir el archivo en modo de lectura
    mov ah, 3Dh           ; Función DOS: Abrir archivo
    lea dx, image_file_name ; Nombre del archivo
    mov al, 0             ; Modo de lectura
    int 21h
    jc ERROR_CARGAR1        ; Si hay error, saltar a manejo de error
    mov [file_handle], ax  ; Guardar el handle del archivo

    ; Recorrer el área del rectángulo (136, 90, 398, 300) x = 262 / y = 210
    mov di, [current_y]          
CARGAR_FILAS1:
    mov si, [current_x]         ; PEDING ROW OVERRUN WHEN @
CARGAR_COLUMNAS1:
    ; Leer el color del archivo (1 dígito hexadecimal o '@')
    mov ah, 3Fh          ; Función DOS: Leer archivo
    lea dx, buffer       ; Leer en el buffer
    mov bx, [file_handle]
    mov cx, 1            ; Leer 1 byte (un carácter)
    int 21h
    cmp ax, 1            ; Verificar si se leyó 1 byte
    jne FIN_LECTURA1      ; Si no se leyó 1 byte, salir del loop

    ; Verificar si el byte leído es '@' (fin de línea)
    mov al, [buffer]
    cmp al, '@'
    je CAMBIAR_FILA1

    ; Verificar si el byte leído es un salto de línea (LF o CR)
    cmp al, 10           ; Verificar si es '\n'
    je CARGAR_COLUMNAS1   ; Ignorar y leer el siguiente byte
    cmp al, 13           ; Verificar si es '\r'
    je CARGAR_COLUMNAS   ; Ignorar y leer el siguiente byte

    ; Verificar si el byte leído es un espacio (omitirlo)
    cmp al, ' '
    je CARGAR_COLUMNAS1   ; Saltar si es un espacio

    ; Convertir el valor leído de hexadecimal a un byte de color
    call CONVERTIR_HEX_A_COLOR

    ; Dibujar el píxel en la posición (si, di)
    PINTA_PIXEL si, di, al ; 'al' contiene el valor del color

    ; Incrementar X y continuar
    inc si
    cmp si, 534    ; Limitar hasta el ancho de 398 píxeles
    jb CARGAR_COLUMNAS1

    jmp CARGAR_FILAS1

CAMBIAR_FILA1:
    ; Cambiar a la siguiente fila
    inc di
    cmp di, 390     ; Limitar hasta la altura de 300 píxeles
    jbe CARGAR_FILAS1
FIN_LECTURA1:
    ; Cerrar el archivo
    mov ah, 3Eh          ; Función DOS: Cerrar archivo
    mov bx, [file_handle]
    int 21h
    ret

ERROR_CARGAR1:
    ret

INSERTAR_IMAGEN ENDP

; Carga un bosquejo (HEX.TXT)
CARGAR_BOSQUEJO PROC
    ; Limpiar el bosquejo anterior
    DIBUJAR_RECTANGULO 136, 90, 398, 300, 0Fh ; Dibujar cuadrado azul (01h es azul)
    ; Abrir el archivo en modo de lectura
    mov ah, 3Dh           ; Función DOS: Abrir archivo
    lea dx, nombre_archivo ; Nombre del archivo
    mov al, 0             ; Modo de lectura
    int 21h
    jc ERROR_CARGAR        ; Si hay error, saltar a manejo de error
    mov [file_handle], ax  ; Guardar el handle del archivo

    ; Recorrer el área del rectángulo (136, 90, 398, 300) x = 262 / y = 210
    mov di, 90           ; Inicializar Y en 90 (coordenada inicial de la fila)
CARGAR_FILAS:
    mov si, 136          ; Inicializar X en 136 (coordenada inicial de la columna)
CARGAR_COLUMNAS:
    ; Leer el color del archivo (1 dígito hexadecimal o '@')
    mov ah, 3Fh          ; Función DOS: Leer archivo
    lea dx, buffer       ; Leer en el buffer
    mov bx, [file_handle]
    mov cx, 1            ; Leer 1 byte (un carácter)
    int 21h
    cmp ax, 1            ; Verificar si se leyó 1 byte
    jne FIN_LECTURA      ; Si no se leyó 1 byte, salir del loop

    ; Verificar si el byte leído es '@' (fin de línea)
    mov al, [buffer]
    cmp al, '@'
    je CAMBIAR_FILA

    ; Verificar si el byte leído es un salto de línea (LF o CR)
    cmp al, 10           ; Verificar si es '\n'
    je CARGAR_COLUMNAS   ; Ignorar y leer el siguiente byte
    cmp al, 13           ; Verificar si es '\r'
    je CARGAR_COLUMNAS   ; Ignorar y leer el siguiente byte

    ; Verificar si el byte leído es un espacio (omitirlo)
    cmp al, ' '
    je CARGAR_COLUMNAS   ; Saltar si es un espacio

    ; Convertir el valor leído de hexadecimal a un byte de color
    call CONVERTIR_HEX_A_COLOR

    ; Dibujar el píxel en la posición (si, di)
    PINTA_PIXEL si, di, al ; 'al' contiene el valor del color

    ; Incrementar X y continuar
    inc si
    cmp si, 534    ; Limitar hasta el ancho de 398 píxeles
    jb CARGAR_COLUMNAS

    jmp CARGAR_FILAS

CAMBIAR_FILA:
    ; Cambiar a la siguiente fila
    inc di
    cmp di, 390     ; Limitar hasta la altura de 300 píxeles
    jbe CARGAR_FILAS
FIN_LECTURA:
    ; Cerrar el archivo
    mov ah, 3Eh          ; Función DOS: Cerrar archivo
    mov bx, [file_handle]
    int 21h
    ret

ERROR_CARGAR:
    ret
CARGAR_BOSQUEJO ENDP

; Convierte de hex a un color para al
CONVERTIR_HEX_A_COLOR PROC
    ; Convertir el dígito hexadecimal (buffer[0]) a un byte de color
    mov al, [buffer]     ; Cargar el dígito
    call HEX_DIGITO_A_BYTE ; Convertir a un valor numérico
    ret
CONVERTIR_HEX_A_COLOR ENDP

HEX_DIGITO_A_BYTE PROC
    ; Convierte un carácter hexadecimal (AL) a su valor numérico
    cmp al, '9'
    jbe ES_UN_DIGITO
    sub al, 7            ; Ajustar para A-F
ES_UN_DIGITO:
    sub al, '0'          ; Convertir de ASCII a valor numérico
    ret
HEX_DIGITO_A_BYTE ENDP

start: ;################################################################<<<<START>>>>################################################################
    ; Inicializar segmentos de datos
    mov ax, @DATA
    mov ds, ax

    ; Cambiar a modo gráfico 12h (640x480, 16 colores)
    mov ax, 0012h
    int 10h

    RELLENAR_PANTALLA 08h 

    ; Dibujar el primer píxel en la posición inicial
   
    DIBUJAR_RECTANGULO 60, 42, 360, 30, 00h;Nombre Dibujo
    DIBUJAR_RECTANGULO 425, 42, 110, 30, 00h;Limpiar btn
  
    DIBUJAR_RECTANGULO 550, 90, 60, 300, 00h  
	DIBUJAR_RECTANGULO 136, 90, 398, 300, 0Fh ;Cuadro de dibujo
    DIBUJAR_RECTANGULO 60, 90, 60, 300, 00h

 
    DIBUJAR_CUADRADO 564, 350, 30, 01h ; Primer cuadrado rojo
    DIBUJAR_CUADRADO 564, 300, 30, 02h ; Segundo cuadrado
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

   
    DIBUJAR_CUADRADO 564, 445, 30, 0Fh ;tecla ABAJO
    DIBUJAR_CUADRADO 529, 445, 30, 0Fh ;tecla IZQ
    DIBUJAR_CUADRADO 600, 445, 30, 0Fh ;tecla DER


    DIBUJAR_RECTANGULO 15, 410, 150, 30, 00h ;Guardar Bosquejo btn
    DIBUJAR_RECTANGULO 15, 445, 150, 30, 00h
    DIBUJAR_RECTANGULO 175, 410, 280, 30, 00h; CAMPO TEXTO
    DIBUJAR_RECTANGULO 465, 410, 145, 30, 00h; Insertar imagen

    IMPRIMIR_TEXTO  3, 55, mensaje1, 1Fh  ;Limpiar
    IMPRIMIR_TEXTO 3, 20, mensaje2, 2Fh   ;Dibujo sin nombre
    IMPRIMIR_TEXTO  26, 2, mensaje3, 1Fh  ;Guardar Bosquejo
    IMPRIMIR_TEXTO 28, 2, mensaje4, 2Fh  ;Cargar Bosquejo
    IMPRIMIR_TEXTO 26, 32, mensaje5, 2Fh  ;Campo de texto
    IMPRIMIR_TEXTO 26, 59, mensaje6, 2Fh  ;Campo de texto
    
call INIT_MOUSE


MAIN_LOOP: ; ################################################################<<<<MAIN LOOP>>>>################################################################
    ; Detectar clic del mouse y pintar
    call DIBUJAR_MOUSE_PIXEL

    VERIFICAR_CAMPO_TEXTO
    VERIFICAR_LIMPIAR
    VERIFICAR_GUARDAR
    VERIFICAR_CARGAR
    VERIFICAR_INSERTAR

    ; Capturar entrada de texto
    call CAPTURAR_ENTRADA
    
    ; Control de teclas (WASD)
    call MOVER_PIXEL

    jmp MAIN_LOOP
SALIR:
    ; Restaurar el modo de texto 03h

    ; Terminar el programa
    mov ah, 4Ch
    int 21h

END start