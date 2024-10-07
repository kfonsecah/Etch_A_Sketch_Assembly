.MODEL small
.STACK 100h

.DATA
    mouse_x dw 0          ; Coordenada X del mouse
    mouse_y dw 0          ; Coordenada Y del mouse
    mouse_buttons db 0    ; Estado de los botones del mouse
    mensaje db 'Click detectado en: ', '$'  ; Mensaje a mostrar antes de las coordenadas
    nueva_linea db 13, 10, '$'  ; Caracteres para nueva línea

.CODE


; Inicializar el mouse
INIT_MOUSE PROC
    mov ax, 0               ; Función 0 de la interrupción 33h: inicializar el mouse
    int 33h                 ; Interrupción para interactuar con el mouse
    cmp ax, 0               ; Verificar si el mouse está presente
    je NO_MOUSE             ; Si no está, saltar a la etiqueta de error
    ret

NO_MOUSE:
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

; Mostrar las coordenadas del mouse


PRINT_STRING PROC
    mov ah, 09h              ; Función DOS para imprimir cadena
    int 21h
    ret
PRINT_STRING ENDP

; Convertir número a caracteres ASCII y mostrarlo


start:
    ; Cambiar a modo gráfico 12h (640x480, 16 colores)
    mov ax, 0012h
    int 10h

    ; Inicializar el mouse
    call INIT_MOUSE

main_loop:
    ; Obtener las coordenadas y el estado del mouse
    call GET_MOUSE_STATUS

    ; Verificar si el botón izquierdo del mouse fue presionado
    test [mouse_buttons], 1
    jz no_click


    ; Esperar hasta que se suelte el botón antes de continuar
wait_for_release:
    call GET_MOUSE_STATUS
    test [mouse_buttons], 1   ; Verificar si el botón izquierdo sigue presionado
    jnz wait_for_release

no_click:
    jmp main_loop

; Salir y restaurar el modo texto
salir:
    mov ax, 0003h
    int 10h
    mov ah, 4Ch
    int 21h
END start