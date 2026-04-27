; --- GORUNTULEME VE PEEK MODULU (display.asm) ---

show_start_screen proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    call clear_screen

    mov ax, 0000h
    int 33h            ; mouse reset
    mov ax, 0001h
    int 33h            ; mouse show

    ; baslik
    mov ah, 02h
    mov bh, 00h
    mov dh, 7
    mov dl, 28
    int 10h
    lea dx, msg_title
    mov ah, 09h
    int 21h

    ; buton top
    mov ah, 02h
    mov bh, 00h
    mov dh, 8
    mov dl, 34
    int 10h
    lea dx, btn_top
    mov ah, 09h
    int 21h

    ; buton orta
    mov ah, 02h
    mov bh, 00h
    mov dh, 9
    mov dl, 34
    int 10h
    lea dx, btn_mid
    mov ah, 09h
    int 21h

    ; buton alt
    mov ah, 02h
    mov bh, 00h
    mov dh, 10
    mov dl, 34
    int 10h
    lea dx, btn_bot
    mov ah, 09h
    int 21h

wait_click:
    mov ax, 0003h
    int 33h
    test bx, 1
    jz wait_click

    ; --- DOGRU KOORDÝNAT DONUSUMU ---
    ; Fare piksellerini (0-639, 0-199) karakter hücresine (0-79, 0-24) çeviriyoruz
    shr cx, 3        ; CX = CX / 8 (Sütun)
    shr dx, 3        ; DX = DX / 8 (Satýr)
    
    mov si, cx       ; si = karakter sütunu
    mov di, dx       ; di = karakter satýrý

    ; --- START BUTON ALANI KONTROLU ---
    ; Buton orta: dh=9, dl=34 (btn_mid'in koordinatlarý)
    ; Buton geniþliði: " | START | " yaklaþýk 11 karakter
    
    cmp di, 8        ; btn_top satýrý
    jb wait_click
    cmp di, 10       ; btn_bot satýrý
    ja wait_click

    cmp si, 34       ; btn_mid baþlangýç sütunu
    jb wait_click
    cmp si, 45       ; btn_mid bitiþ sütunu (34 + 11)
    ja wait_click

    ; Eðer buraya geldiyse butona týklandý demektir
    mov ax, 0002h
    int 33h          ; Mouse gizle ve devam et
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
show_start_screen endp

draw_restart_button proc
    push ax
    push bx
    push dx

    mov ah, 02h
    mov bh, 00h
    mov dh, 4
    mov dl, 61
    int 10h
    lea dx, btn_restart_top
    mov ah, 09h
    int 21h

    mov ah, 02h
    mov bh, 00h
    mov dh, 5
    mov dl, 61
    int 10h
    lea dx, btn_restart_mid
    mov ah, 09h
    int 21h

    mov ah, 02h
    mov bh, 00h
    mov dh, 6
    mov dl, 61
    int 10h
    lea dx, btn_restart_bot
    mov ah, 09h
    int 21h

    pop dx
    pop bx
    pop ax
    ret
draw_restart_button endp

init_timer proc
    push ax
    mov ah, 00h
    int 1Ah
    mov [last_tick], dx
    mov [time_up], 0
    pop ax
    ret
init_timer endp

update_timer proc
    push ax
    push bx
    push dx

    cmp [time_up], 1
    je timer_exit

    cmp [time_left], 0
    je timer_done

    mov ah, 00h
    int 1Ah

    mov ax, dx
    sub ax, [last_tick]
    cmp ax, 18
    jb timer_exit

timer_loop:
    cmp [time_left], 0
    je timer_done

    dec [time_left]
    add word ptr [last_tick], 18

    mov ax, dx
    sub ax, [last_tick]
    cmp ax, 18
    jae timer_loop
    jmp timer_exit

timer_done:
    mov [time_left], 0
    mov [time_up], 1

timer_exit:
    pop dx
    pop bx
    pop ax
    ret
update_timer endp

update_time_display proc
    push ax
    push bx
    push cx
    push dx

    ; mevcut cursor konumunu sakla
    mov ah, 03h
    mov bh, 00h
    int 10h
    push dx

    ; sabit yere yaz
    mov ah, 02h
    mov bh, 00h
    mov dh, 1
    mov dl, 60
    int 10h

    lea dx, msg_time_label
    mov ah, 09h
    int 21h

    mov ax, [time_left]
    xor dx, dx
    mov bx, 60
    div bx                  ; AX = dakika, DX = saniye

    mov cl, dl              ; saniyeyi sakla

    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h

    mov dl, '.'
    mov ah, 02h
    int 21h

    mov al, cl
    call print_two_digits

    ; eski cursor konumuna geri don
    pop dx
    mov ah, 02h
    mov bh, 00h
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
update_time_display endp 

show_time_penalty proc
    push ax
    push bx
    push dx

    mov ah, 02h
    mov bh, 00h
    mov dh, 2
    mov dl, 60
    int 10h

    lea dx, msg_time_penalty
    mov ah, 09h
    int 21h

    pop dx
    pop bx
    pop ax
    ret
show_time_penalty endp   

show_time_bonus proc
    push ax
    push bx
    push dx

    mov ah, 02h
    mov bh, 00h
    mov dh, 2
    mov dl, 60
    int 10h

    lea dx, msg_time_bonus
    mov ah, 09h
    int 21h

    pop dx
    pop bx
    pop ax
    ret
show_time_bonus endp

clear_time_bonus proc
    push ax
    push bx
    push cx
    push dx

    mov ah, 02h
    mov bh, 00h
    mov dh, 2
    mov dl, 60
    int 10h

    mov ah, 09h
    mov al, ' '
    mov bh, 00h
    mov bl, 07h
    mov cx, 2
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
clear_time_bonus endp

clear_time_penalty proc
    push ax
    push bx
    push cx
    push dx

    mov ah, 02h
    mov bh, 00h
    mov dh, 2
    mov dl, 60
    int 10h

    mov ah, 09h
    mov al, ' '
    mov bh, 00h
    mov bl, 07h
    mov cx, 2
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
clear_time_penalty endp  

penalty_delay proc
    push ax
    push bx
    push dx

    mov ah, 00h
    int 1Ah
    mov bx, dx

wait_penalty:
    mov ah, 00h
    int 1Ah
    mov ax, dx
    sub ax, bx
    cmp ax, 18
    jb wait_penalty

    pop dx
    pop bx
    pop ax
    ret
penalty_delay endp

print_two_digits proc
    push ax
    push bx
    push dx

    xor ah, ah
    mov bl, 10
    div bl                  ; AL = onlar, AH = birler

    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h

    mov dl, ah
    add dl, '0'
    mov ah, 02h
    int 21h

    pop dx
    pop bx
    pop ax
    ret
print_two_digits endp   

show_all_cards proc
    mov dh, 4
    lea si, cards
    mov al, [grid_size]
    mov [tmp_bl], al

s_row:
    mov dl, 11
    mov al, [grid_size]
    mov cl, al
    mov ch, 0

s_col:
    push cx

    mov ah, 02h
    mov bh, 00h
    int 10h

    mov ah, 09h
    mov al, [si]
    mov bl, 0Eh
    mov cx, 1
    int 10h

    inc si
    add dl, 4
    pop cx
    loop s_col

    add dh, 2
    dec [tmp_bl]
    jnz s_row
    ret
show_all_cards endp

delay proc
    push ax
    push bx
    push dx

    mov ah, 00h
    int 1Ah
    mov bx, dx

wait_delay:
    mov ah, 00h
    int 1Ah
    mov ax, dx
    sub ax, bx
    cmp ax, 60          ; yaklasik 3-4 saniye
    jb wait_delay

    pop dx
    pop bx
    pop ax
    ret
delay endp

update_hamle_display proc
    push ax
    push bx
    push cx
    push dx

    mov ah, 02h
    mov bh, 00h
    mov dh, 0
    mov dl, 60
    int 10h

    lea dx, msg_hamle_label
    mov ah, 09h
    int 21h

    mov al, [kalan_hamle]
    xor ah, ah
    mov bl, 10
    div bl              ; AL = onlar, AH = birler

    mov cl, ah          ; birler

    cmp al, 0
    je print_space_tens

    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h
    jmp print_ones

print_space_tens:
    mov dl, ' '
    mov ah, 02h
    int 21h

print_ones:
    mov dl, cl
    add dl, '0'
    mov ah, 02h
    int 21h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
update_hamle_display endp

clear_feedback_area proc
    mov ax, 0600h
    mov bh, 07h
    mov ch, 19
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 10h
    ret
clear_feedback_area endp

print_feedback_line proc
    push ax
    push bx
    push dx

    mov ah, 02h
    mov bh, 00h
    mov dh, 19
    mov dl, 0
    int 10h

    pop dx
    mov ah, 09h
    int 21h

    pop bx
    pop ax
    ret
print_feedback_line endp

play_beep proc
    push ax
    push dx

    mov ah, 02h
    mov dl, 07h
    int 21h

    pop dx
    pop ax
    ret
play_beep endp

restart_pause proc
    push ax
    push bx
    push dx

    mov ah, 00h
    int 1Ah
    mov bx, dx

wait_restart:
    mov ah, 00h
    int 1Ah
    mov ax, dx
    sub ax, bx
    cmp ax, 6       ; yaklasik 1/3 saniye civari
    jb wait_restart

    pop dx
    pop bx
    pop ax
    ret
restart_pause endp
