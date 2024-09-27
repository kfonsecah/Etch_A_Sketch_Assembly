JUMPS
code segment
assume cs: code, ds: data
    mov ax, data
    mov ds, ax

    ; Сохранение и установка прерываний
    Interrupts_new:
        ; Сохранить старый обработчик 03h
        push es
        mov ax, 3503h
        int 21h
        mov word ptr int_03h_vect, bx
        mov word ptr int_03h_vect+2, es
        pop es

        ; Новый обработчик прерывания 03h
        push ds
        mov dx, offset int_03h_proc
        mov ax, seg int_03h_proc
        mov ds, ax
        mov ax, 2503h
        int 21h
        pop ds

        ; Сохранить старый обработчик 09h
        push es
        mov ax, 3509h
        int 21h
        mov word ptr int_09h_vect, bx
        mov word ptr int_09h_vect+2, es
        pop es

        ; Новый обработчик прерывания 09h
        push ds
        mov dx, offset int_09h_proc
        mov ax, seg int_09h_proc
        mov ds, ax
        mov ax, 2509h
        int 21h
        pop ds

        ; Сохранить старый обработчик 1ch
        push es
        mov ax, 351ch
        int 21h
        mov word ptr int_1ch_vect, bx
        mov word ptr int_1ch_vect+2, es
        pop es

        ; Новый обработчик прерывания 1ch
        push ds
        mov dx, offset int_1ch_proc
        mov ax, seg int_1ch_proc
        mov ds, ax
        mov ax, 251ch
        int 21h
        pop ds

    ; Установка видеорежима
    mov ax, 0013h
    int 10h
    mov ax, 0A000h
    mov es, ax

    mov ax, offset s_none
    mov cr_note, ax
    ; Бесконечный цикл (до выхода)
    inf_loop:
        cmp state, 0
        jne inf_loop
    
    ; Восстановление прерываний
    Interrupts_old:
        ; Возврат обработчика прерывания 03h
        push ds
        mov dx, word ptr int_03h_vect
        mov ax, word ptr int_03h_vect+2
        mov ds, ax
        mov ax, 2503h
        int 21h
        pop ds

        ; Возврат обработчика прерывания 09h
        push ds
        mov dx, word ptr int_09h_vect
        mov ax, word ptr int_09h_vect+2
        mov ds, ax
        mov ax, 2509h
        int 21h
        pop ds

        ; Возврат обработчика прерывания 1ch
        push ds
        mov dx, word ptr int_1ch_vect
        mov ax, word ptr int_1ch_vect+2
        mov ds, ax
        mov ax, 251ch
        int 21h
        pop ds

    ; Возврат видеорежима
    mov ax, 3h
    int 10h

    ; Выход из программы
	mov ah, 4Ch
	int 21h

    ; Рисование прямоугольника
    rect proc
        push ax
        push bx
        push cx
        push dx
        push di

        mov ax,320
        mul y

        add ax,x
        mov di, ax
        mov cx, h
        wid:
            push cx
            mov cx, w
            hei:
                mov bl, color
                mov es:[di], bl
                inc di
            loop hei
            pop cx
            add di,320
            sub di,w
        loop wid
   
        pop di
        pop dx
        pop cx
        pop bx
        pop ax

        ret
    rect endp

    ; Очистка экрана
    clear proc
        push x
        push y
        push w
        push h
        push ax
        mov al, color
        push ax

        mov x, 0
        mov y, 0
        mov w, 320
        mov h, 280
        mov color, 0
        call rect

        pop ax
        mov color, al
        pop ax
        pop h
        pop w
        pop y
        pop x
        ret
    clear endp

    ; Включить спикер
    ; freq - обратная частота
    sound_st proc
        push ax
        in al, 61h
        or al, 3
        out 61h, al
        mov al, 10110110b ; http://ru.osdev.wikia.com/wiki/Программируемый_интервальный_таймер
        out 43h, al
        mov ax, freq
        out 42h, al
        mov al, ah
        out 42h, al ; Потому что так нужно
        pop ax
        ret
    sound_st endp

    ; Выключить спикер
    sound_en proc
        push ax
        in al, 61h
        and al, 11111100b
        out 61h, al
        pop ax
        mov cr_note, offset s_none
        ret
    sound_en endp

    ; Защита от отладки
    int_03h_proc proc far
        mov ah, 4Ch
        int 21h
        iret
    int_03h_proc endp

    ; Клавиатура
    int_09h_proc proc far
        push ax
        in ax, 60h
        mov key, al
        cmp al, 01h
        je swstate
        cmp state, 1
        jne nxcmp
        cmp al, 10h
        je sw_game

        

        nxcmp:
        cmp state, 1
        je endq
        cmp al, 80h
        jnc stop_s
        start_s:
            call set_freq
            call sound_st
            jmp endq
        stop_s:
            call sound_en
            jmp endq
        swstate:
            mov state, 0
            jmp stop_s
            jmp endq
        sw_game:
            mov state, 2
            call clear
            jmp stop_s
            jmp endq
        endq:
            mov al, 20h ; Так нужно
            out 20h, al
            pop ax
        iret
    int_09h_proc endp

    ; Таймер
    int_1ch_proc proc far
        push ax
        call main_loop
        call menu_music
        inc counter
        cmp counter, 18
        jne next
        mov counter, 0
        next:
        inc muse_tempo_cnt
        mov al, muse_tempo
        cmp muse_tempo_cnt, al
        jne ex
        mov muse_tempo_cnt, 0
        ex:
        pop ax
        iret
    int_1ch_proc endp

    ; Установить частоту
    set_freq proc
        ; Малая октава
        q_st:
        cmp key, 10h
            jne q_q
            mov freq, 9097
            mov cr_note, offset s_q
            jmp n_end
        q_q:
        cmp key, 1eh
            jne q_a
            mov freq, 8586
            mov cr_note, offset s_a
            jmp n_end
        q_a:
        cmp key, 2ch
            jne q_z
            mov freq, 8105
            mov cr_note, offset s_z
            jmp n_end
        q_z:
        cmp key, 11h
            jne q_w
            mov freq, 7650
            mov cr_note, offset s_w
            jmp n_end
        q_w:
        cmp key, 1fh
            jne q_s
            mov freq, 7220
            mov cr_note, offset s_s
            jmp n_end
        q_s:
        cmp key, 2dh
            jne q_x
            mov freq, 6815
            mov cr_note, offset s_x
            jmp n_end
        q_x:
        cmp key, 12h
            jne q_e
            mov freq, 6432
            mov cr_note, offset s_e
            jmp n_end
        q_e:
        cmp key, 20h
            jne q_d
            mov freq, 6071
            mov cr_note, offset s_d
            jmp n_end
        q_d:
        cmp key, 2eh
            jne q_c
            mov freq, 5731
            mov cr_note, offset s_c
            jmp n_end
        q_c:
        cmp key, 13h
            jne q_r
            mov freq, 5409
            mov cr_note, offset s_r
            jmp n_end
        q_r:
        cmp key, 21h
            jne q_f
            mov freq, 5106
            mov cr_note, offset s_f
            jmp n_end
        q_f:
        cmp key, 2fh
            jne q_v
            mov freq, 4819
            mov cr_note, offset s_v
            jmp n_end
        q_v:
        ; Первая октава
        cmp key, 14h
            jne q_t
            mov freq, 4548
            mov cr_note, offset s_t
            jmp n_end
        q_t:
        cmp key, 22h
            jne q_g
            mov freq, 4293
            mov cr_note, offset s_g
            jmp n_end
        q_g:
        cmp key, 30h
            jne q_b
            mov freq, 4052
            mov cr_note, offset s_b
            jmp n_end
        q_b:
        cmp key, 15h
            jne q_y
            mov freq, 3825
            mov cr_note, offset s_y
            jmp n_end
        q_y:
        cmp key, 23h
            jne q_h
            mov freq, 3610
            mov cr_note, offset s_h
            jmp n_end
        q_h:
        cmp key, 31h
            jne q_n
            mov freq, 3407
            mov cr_note, offset s_n
            jmp n_end
        q_n:
        cmp key, 16h
            jne q_u
            mov freq, 3216
            mov cr_note, offset s_u
            jmp n_end
        q_u:
        cmp key, 24h
            jne q_j
            mov freq, 3036
            mov cr_note, offset s_j
            jmp n_end
        q_j:
        cmp key, 32h
            jne q_m
            mov freq, 2865
            mov cr_note, offset s_m
            jmp n_end
        q_m:
        cmp key, 17h
            jne q_i
            mov freq, 2705
            mov cr_note, offset s_i
            jmp n_end
        q_i:
        cmp key, 25h
            jne q_k
            mov freq, 2553
            mov cr_note, offset s_k
            jmp n_end
        q_k:
        cmp key, 33h
            jne q_1
            mov freq, 2409
            mov cr_note, offset s_p
            jmp n_end
        q_1:
        cmp key, 18h ; "до" второй октавы
            jne n_end
            mov freq, 2274
            mov cr_note, offset s_o
            jmp n_end

        n_end:
        ret
    set_freq endp

    ; Главный цикл
    main_loop proc
        push ax

        cmp state, 1
        je menu
        cmp state, 2
        je game_state
        jmp m_ret

        ; Главное меню
        menu:
            mov string, offset str_title
            mov string_len, 26
            mov string_x, 2
            mov string_y, 2
            mov string_color, 15
            call print_string

            mov string, offset str_start
            mov string_len, 15
            mov string_x, 4
            mov string_y, 4
            mov string_color, 15
            call print_string

            mov string, offset str_exit
            mov string_len, 15
            mov string_x, 4
            mov string_y, 5
            mov string_color, 15
            call print_string

            jmp m_ret

        ; Game state
        game_state:
            mov ax, cr_note
            mov string, ax
            mov string_len, 7
            mov string_x, 2
            mov string_y, 2
            mov string_color, 15
            call print_string
            mov ax, offset str_game1
            mov string, ax
            mov string_len, 24
            mov string_x, 5
            mov string_y, 5
            mov string_color, 15
            call print_string
            jmp m_ret

        m_ret:
        pop ax
        ret
    main_loop endp

    ; Музыка в меню
    menu_music proc
        cmp state, 1
        jne next_mus
        cmp muse_tempo_cnt, 0
        jne next_mus
        call sound_en
        mov al, muse_cur
        mov bl, 2
        mul bl
        mov si, ax
        mov dx, btdt_notes[si]
        mov freq, dx
        cmp freq, 0
        je no_sound
        
        call sound_st
        no_sound:
        inc muse_cur
        cmp muse_cur, 32 ; for btdt
        jne next_mus
        mov muse_cur, 0
        next_mus:
        ret
    menu_music endp

    ; Напечатать строку
    print_string proc
        push ax
        push bx
        push cx
        push dx
        push es
        
        mov ax, ds
        mov es, ax
        mov bp, string
        mov ah, 13h
        mov al, 01h
        mov bh, 0
        mov bl, string_color
        mov cx, string_len
        mov dl, string_x
        mov dh, string_y
        int 10h

        pop es
        pop dx
        pop cx
        pop bx
        pop ax
        ret
    print_string endp
code ends

data segment
    ; Рисование
        x dw 10
        y dw 10
        w dw 50
        h dw 10
        color db 15

    ; Игра
        counter db 0 ; Счётчик для прерывания (сбрасывается раз в секунду)
        state db 1 ; Состояние (1 - меню, 2 - игра)
        key db 0 ; Нажатая клавиша
        int_03h_vect dd ? ; Адрес исходного прерывания 03h
        int_09h_vect dd ? ; Адрес исходного прерывания 09h
        int_1ch_vect dd ? ; Адрес исходного прерывания 1ch

    ; Вывод строк
        string dw 0 ; Адрес строки
        string_len dw 4 ; Длина строки
        string_x db 0
        string_y db 0
        string_color db 15

    ; Строки
        str_title       db  'Button accordion simulator'        ; 26
        str_start       db  'Start -> Q (do)'                   ; 15
        str_exit        db  ' Exit -> Esc   '                   ; 15
        str_game1       db  'Did you read README.pdf?'          ; 24

    ; Музыка
        freq dw 50000       ; freq = 1190000/v, где v - частота
        muse_tempo db 5     ; Темп
        muse_tempo_cnt db 0 ; Счётчик для темпа
        muse_cur db 0       ; Текущая нота

    ; Beat the devil's tattoo, 32 notes
        ;                E     G     A     B        B        B     D     B     A     G        E        E     D     B     G     A        A     G     A     B     A     G     E        E
        btdt_notes dw 0, 7220, 6071, 5409, 4819, 0, 4819, 0, 4819, 4052, 4819, 5409, 6071, 0, 7220, 0, 3610, 4052, 4819, 6071, 5409, 0, 5409, 6071, 5409, 4819, 5409, 6071, 7220, 0, 7220, 0 ; Ноты (частота)
    
    ; Названия нот
        s_q db "Q (do) "
        s_a db "A (do#)"
        s_z db "Z (re) "
        s_w db "W (re#)"
        s_s db "S (mi) "
        s_x db "X (fa) "
        s_e db "E (fa#)"
        s_d db "D (sol)"
        s_c db "C (lab)"
        s_r db "R (la) "
        s_f db "R (la#)"
        s_v db "V (si) "
        s_t db "T (do) "
        s_g db "G (do#)"
        s_b db "B (re) "
        s_y db "Y (re#)"
        s_h db "H (mi) "
        s_n db "N (fa) "
        s_u db "U (fa#)"
        s_j db "J (sol)"
        s_m db "M (lab)"
        s_i db "I (la) "
        s_k db "K (la#)"
        s_p db "< (si) "
        s_o db "O (do) "
        s_none db "No snd "
        cr_note dw 0
data ends
end