; --- OYUN MANTIGI VE VERI MODULU (logic.asm) ---

hamle_sonu_check proc
    inc [hamle_sayisi]

    mov al, [acik_kart_say]
    cmp al, [toplam_cift]
    jne hs_exit

    call oyun_kazanildi

hs_exit:
    ret
hamle_sonu_check endp

eslesme_dogru proc
    push ax
    push bx
    push si
    push dx

    call clear_feedback_area
    lea dx, msg_dogru
    call print_feedback_line

    mov al, [first_index]
    xor ah, ah
    mov si, ax
    mov byte ptr [card_states + si], 1

    mov al, [second_index]
    xor ah, ah
    mov si, ax
    mov byte ptr [card_states + si], 1

    inc [acik_kart_say]
    dec [kalan_hamle]

    inc [combo_streak]
    cmp [combo_streak], 2
    jb no_combo_bonus

    add word ptr [time_left], 7
    call clear_feedback_area
    call show_time_bonus
    call update_time_display
    call bonus_delay
    call clear_feedback_area
    call update_time_display
    jmp done_dogru

no_combo_bonus:
    call update_time_display

done_dogru:
    pop dx
    pop si
    pop bx
    pop ax
    ret
eslesme_dogru endp 

bonus_delay proc
    push ax
    push bx
    push dx

    mov ah, 00h
    int 1Ah
    mov bx, dx

wait_bonus:
    mov ah, 00h
    int 1Ah
    mov ax, dx
    sub ax, bx
    cmp ax, 18
    jb wait_bonus

    pop dx
    pop bx
    pop ax
    ret
bonus_delay endp

eslesme_yanlis proc
    push ax
    push bx
    push si
    push dx

    call clear_feedback_area
    lea dx, msg_yanlis
    call print_feedback_line
    call play_beep
    
    mov al, [first_index]
    xor ah, ah
    mov si, ax
    mov byte ptr [card_states + si], 0

    mov al, [second_index]
    xor ah, ah
    mov si, ax
    mov byte ptr [card_states + si], 0

    dec [kalan_hamle]
    mov [combo_streak], 0 
    
    cmp word ptr [time_left], 5
    jae do_penalty
    mov word ptr [time_left], 0
    mov [time_up], 1
    jmp time_ok
    
do_penalty:
    sub word ptr [time_left], 5
    
time_ok:
    call show_time_penalty
    call penalty_delay
    call clear_time_penalty
    call update_time_display


    pop dx
    pop si
    pop bx
    pop ax
    ret
eslesme_yanlis endp

setup_cards proc
    mov [combo_streak], 0
    ; oyun sayaçlarini sifirla
    mov [acik_kart_say], 0
    mov word ptr [hamle_sayisi], 1
    mov [first_index], 0
    mov [second_index], 0
    mov [first_value], 0
    mov [second_value], 0

    ; cards dizisini temizle
    lea di, cards
    mov cx, 36
    xor al, al
clear_cards_loop:
    mov [di], al
    inc di
    loop clear_cards_loop

    ; card_states dizisini temizle
    lea di, card_states
    mov cx, 36
    xor al, al
clear_states_loop:
    mov [di], al
    inc di
    loop clear_states_loop

    call shuffle_alphabet

    mov al, [grid_size]
    mul al
    mov cx, ax
    shr cx, 1

    lea si, alphabet
    lea di, cards

fill_loop:
    mov al, [si]
    mov [di], al
    inc di
    mov [di], al
    inc di
    inc si
    loop fill_loop

    call shuffle_cards
    ret
setup_cards endp

shuffle_alphabet proc
    push bp
    mov cx, 26
shuffle_alpha_loop:
    push cx
    mov bp, cx
    call get_random_num

    mov ax, dx
    xor dx, dx
    mov bx, 26
    div bx

    lea si, alphabet
    mov cx, bp
    dec cx
    add si, cx

    lea di, alphabet
    add di, dx

    mov al, [si]
    mov ah, [di]
    mov [si], ah
    mov [di], al

    pop cx
    loop shuffle_alpha_loop
    pop bp
    ret
shuffle_alphabet endp

shuffle_cards proc
    mov al, [grid_size]
    mul al
    mov si, ax
    dec si                      ; i = total_cards - 1

shuffle_cards_loop:
    push si
    call get_random_num

    mov ax, dx
    xor dx, dx
    mov bx, si
    inc bx                      ; range = i + 1
    div bx                      ; DX = j, 0..i

    lea di, cards
    add di, si                  ; cards[i]

    lea bx, cards
    add bx, dx                  ; cards[j]

    mov al, [di]
    mov ah, [bx]
    mov [di], ah
    mov [bx], al

    pop si
    dec si
    jnz shuffle_cards_loop
    ret
shuffle_cards endp

init_random_seed proc
    push ax
    mov ah, 00h
    int 1Ah
    xor ax, dx
    mov [rand_seed], ax
    pop ax
    ret
init_random_seed endp

get_random_num proc
    push bx
    mov ax, [rand_seed]
    mov bx, 25173
    mul bx
    add ax, 13849
    mov [rand_seed], ax
    mov dx, ax
    pop bx
    ret
get_random_num endp
