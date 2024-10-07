.MODEL small
.STACK 100h

.DATA
    mouse_x dw 0          ; Coordenada X del mouse
    mouse_y dw 0          ; Coordenada Y del mouse
    mouse_buttons db 0    ; Estado de los botones del mouse
    mensaje db 'Click detectado en: $'
    coord_x_msg db 'X: $'
    coord_y_msg db 'Y: $'
    nueva_linea db 13, 10, '$'
    no_mouse_msg db 'No hay mouse presente. $'  ; Mensaje si no hay mouse
    buffer db 6, '$'       ; Buffer para mostrar las coordenadas

.CODE

; Inicializar el mouse
INIT_MOUSE PROC
    mov ax, 0               ; Función 0 de la interrupción 33h: inicializar el mouse
    int 33h                 ; Interrupción para interactuar con el mouse
    cmp ax, 0               ; Verificar si el mouse está presente
    je NO_MOUSE             ; Si no está, saltar a la etiqueta de error
    ret

NO_MOUSE:
    ; Mostrar mensaje de que no hay mouse presente
    mov dx, OFFSET no_mouse_msg
    call PRINT_MESSAGE
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

; Imprimir un mensaje en pantalla usando ah=09h (cadena terminada en '$')
PRINT_MESSAGE PROC
    mov ah, 09h               ; Función para imprimir cadena de caracteres
    int 21h
    ret
PRINT_MESSAGE ENDP

; Convertir un número en el rango 0-65535 a ASCII y mostrarlo
PRINT_NUMBER PROC
    push ax
    push bx
    push cx
    push dx

    xor cx, cx          ; Limpiar contador de dígitos

convert_loop:
    mov bx, 10
    xor dx, dx          ; Limpia dx para la división
    div bx              ; Divide ax entre 10
    add dl, '0'         ; Convierte el número a carácter ASCII
    push dx             ; Guarda el dígito en la pila
    inc cx              ; Incrementa el contador de dígitos
    test ax, ax         ; Verifica si ax es 0
    jnz convert_loop    ; Si no es 0, continuar

print_digits:
    pop dx              ; Recuperar los dígitos
    mov ah, 02h         ; Función para imprimir un solo carácter
    mov dl, al          ; El carácter a imprimir
    int 21h             ; Llamada a DOS para imprimir el carácter
    loop print_digits   ; Imprimir todos los dígitos

    pop dx
    pop cx
    pop bx
    pop ax
    ret
PRINT_NUMBER ENDP

; Mostrar las coordenadas del mouse
DISPLAY_COORDINATES PROC
    ; Mostrar mensaje de click detectado
    mov dx, OFFSET mensaje
    call PRINT_MESSAGE

    ; Mostrar coordenada X
    mov dx, OFFSET coord_x_msg
    call PRINT_MESSAGE

    mov ax, [mouse_x]       ; Cargar la coordenada X del mouse
    call PRINT_NUMBER       ; Mostrar la coordenada X

    ; Nueva línea
    mov dx, OFFSET nueva_linea
    call PRINT_MESSAGE

    ; Mostrar coordenada Y
    mov dx, OFFSET coord_y_msg
    call PRINT_MESSAGE

    mov ax, [mouse_y]       ; Cargar la coordenada Y del mouse
    call PRINT_NUMBER       ; Mostrar la coordenada Y

    ; Nueva línea
    mov dx, OFFSET nueva_linea
    call PRINT_MESSAGE

    ret
DISPLAY_COORDINATES ENDP

start:
    ; Cambiar a modo texto 03h (80x25 caracteres, 16 colores)
    mov ax, 0003h
    int 10h

    ; Inicializar el mouse
    call INIT_MOUSE

main_loop:
    ; Obtener las coordenadas y el estado del mouse
    call GET_MOUSE_STATUS

    ; Verificar si el botón izquierdo del mouse fue presionado
    test [mouse_buttons], 1   ; Verificar si el botón izquierdo está presionado
    jz no_click               ; Si no está presionado, continuar el ciclo

    ; Si hubo un clic, mostrar las coordenadas
    call DISPLAY_COORDINATES

    ; Esperar hasta que se suelte el botón antes de continuar
wait_for_release:
    call GET_MOUSE_STATUS
    test [mouse_buttons], 1   ; Verificar si el botón izquierdo sigue presionado
    jnz wait_for_release      ; Si todavía está presionado, esperar

no_click:
    ; Continuar verificando el mouse
    jmp main_loop

; Restaurar el modo de texto y salir
salir:
    mov ax, 0003h
    int 10h
    ; Terminar el programa
    mov ah, 4Ch
    int 21h

END start
