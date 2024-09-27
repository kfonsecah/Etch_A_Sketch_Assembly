.model small
.stack 100h
.data

.code
main:
    ; Inicializar el modo gráfico 13h (320x200, 256 colores)
    mov ax, 13h
    int 10h

    ; Establecer las coordenadas iniciales (x=50, y=50)
    mov di, 50  ; Posición Y inicial
    mov cx, 6   ; Altura del cuadrado (número de filas)

draw_row:
    push cx         ; Guardar el contador de filas

    mov cx, 50      ; Posición X inicial
    mov bx, 6       ; Anchura del cuadrado (número de columnas)

draw_column:
    ; Dibujar un píxel rojo (índice 4 en la paleta VGA)
    mov al, 4       ; Color rojo
    mov ah, 0Ch     ; Función de BIOS para escribir píxel en pantalla
    mov dx, di      ; Posición Y (di) a dx
    int 10h

    inc cx          ; Avanzar a la siguiente columna
    dec bx          ; Reducir el contador de columnas
    jnz draw_column ; Si quedan columnas, continuar

    inc di          ; Avanzar a la siguiente fila
    pop cx          ; Restaurar el contador de filas
    dec cx          ; Reducir el contador de filas
    jnz draw_row    ; Si quedan filas, continuar

    ; Esperar una tecla para salir
    mov ah, 0
    int 16h

    ; Volver al modo de texto 03h
    mov ax, 03h
    int 10h

    ; Salir del programa
    mov ax, 4C00h
    int 21h
end main
