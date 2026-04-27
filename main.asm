org 100h

.data
    ; --- Temel Degiskenler ---
    msg_selection   db 'Oyun Alani Seciniz (4 veya 6): $'
    grid_size       db 0
    tmp_bl          db 0
    alphabet        db 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    cards           db 36 dup(0)
    card_states     db 36 dup(0)

    ; --- Modul degiskenleri ---
    sel_row         db 0
    sel_col         db 0
    char_idx        db 0
    time_left       dw 0
    last_tick       dw 0
    time_up         db 0 
    game_over       db 0 
    restart_requested db 0
    restart_prev_down db 0
    combo_streak    db 0
    rand_seed       dw 0


    ; --- Oyun Durum Degiskenleri ---
    kalan_hamle     db 15
    acik_kart_say   db 0
    toplam_cift     db 8
    hamle_sayisi    dw 1
    first_index     db 0
    second_index    db 0
    first_value     db 0
    second_value    db 0

    ; --- Mesajlar ---
    msg_title   db 'HAFIZA KARTI OYUNU$'
    btn_top     db '+---------+$'
    btn_mid     db '|  START  |$'
    btn_bot     db '+---------+$'
    btn_restart_top db '+----------+$'
    btn_restart_mid db '| RESTART  |$'
    btn_restart_bot db '+----------+$'
    msg_hamle_label db 'Kalan Hamle: $'
    msg_hamle       db '-- Hamle $'
    msg_hamle_son   db ' --',13,10,'$'
    msg_info1   db '4x4 icin: 15 hamle, 2.00 sure$'
    msg_info2   db '6x6 icin: 40 hamle, 4.00 sure$'
    
    ilk_msg         db 0Dh, 0Ah, 'Ilk karti sec (SatirSutun or:11): $'
    ikinci_msg      db 0Dh, 0Ah, 'Ikinci karti sec (SatirSutun or:11): $'
    msg_dogru       db 'Tebrikler! Dogru eslesme. $'
    msg_yanlis      db 'Maalesef yanlis. Kartlar kapaniyor... $'
    msg_already_open db 'Bu kart zaten acik. Baska bir kart secin. $'
    msg_lose        db 0Dh, 0Ah, 0Dh, 0Ah, 'HAMLE BITTI! KAYBETTINIZ. $'
    msg_win         db 0Dh, 0Ah, 0Dh, 0Ah, 'TEBRIKLER! TUM KARTLARI BULDUNUZ! $'
    msg_invalid_selection db 'Gecersiz secim. Tekrar deneyin. $'
    msg_invalid_grid db 'Lutfen gecerli bir alan sayisi giriniz. $'
    msg_restarting db 'Oyun yeniden baslatiliyor... $'
    msg_time_label  db 'Sure: $'
    msg_time_ended  db 0Dh, 0Ah, 0Dh, 0Ah, 'SURE BITTI! KAYBETTINIZ. $'
    msg_time_penalty db '-5$'
    msg_time_bonus db '+7$'

.code
main proc
    mov ax, @data
    mov ds, ax

start_screen_entry:    
    call show_start_screen

    call clear_screen

    mov ah, 02h
    mov bh, 00h
    mov dh, 7
    mov dl, 25
    int 10h
    lea dx, msg_info1
    mov ah, 09h
    int 21h
    
    mov ah, 02h
    mov bh, 00h
    mov dh, 8
    mov dl, 25
    int 10h
    lea dx, msg_info2
    mov ah, 09h
    int 21h

read_grid_size:
    mov ah, 02h
    mov bh, 00h
    mov dh, 10
    mov dl, 25
    int 10h
    lea dx, msg_selection
    mov ah, 09h
    int 21h

    mov ah, 00h
    int 16h

    cmp al, '4'
    je grid_4x4
    cmp al, '6'
    je grid_6x6

    call play_beep

    mov ah, 02h
    mov bh, 00h
    mov dh, 12
    mov dl, 22
    int 10h
    lea dx, msg_invalid_grid
    mov ah, 09h
    int 21h

    call grid_warning_delay
    call clear_grid_warning
    jmp read_grid_size

grid_4x4:
    mov dl, al
    mov ah, 02h
    int 21h
    
    mov [grid_size], 4
    call reset_game_state
    jmp devam_hazirlik

grid_6x6:
    mov dl, al
    mov ah, 02h
    int 21h
    
    mov [grid_size], 6
    call reset_game_state
    jmp devam_hazirlik

devam_hazirlik: 
    call init_random_seed
    call setup_cards

    call clear_screen 
    call print_title
    mov dh, 4
    mov dl, 0
    call draw_grid
    call draw_restart_button

    call show_all_cards
    call delay

    call clear_screen
    call print_title
    mov dh, 4
    mov dl, 0
    call draw_grid
    call draw_restart_button

    call init_timer

game_loop:
    cmp [game_over], 1
    je program_sonu
    cmp [time_up], 1
    je oyun_sure_bitti
    cmp [kalan_hamle], 0
    je oyun_kaybedildi

    call update_hamle_display
    call clear_bottom_line
    call print_turn_header
    call draw_restart_button

first_pick:
    ...
    lea dx, ilk_msg
    call get_selection
    cmp [restart_requested], 1
    je restart_game 
    cmp [time_up], 1
    je oyun_sure_bitti

    mov al, [char_idx]
    xor ah, ah
    mov si, ax
    cmp byte ptr [card_states + si], 1
    je first_already_open

    call reveal_selected_card

    mov al, [char_idx]
    mov [first_index], al
    xor ah, ah
    mov si, ax
    mov al, [cards + si]
    mov [first_value], al
    jmp second_pick

first_already_open:
    call clear_feedback_area
    lea dx, msg_already_open
    call print_feedback_line
    jmp first_pick

second_pick:
second_pick_retry:
    lea dx, ikinci_msg
    call get_selection
    cmp [restart_requested], 1
    je restart_game
    cmp [time_up], 1
    je oyun_sure_bitti

    mov al, [char_idx]
    xor ah, ah
    mov si, ax
    cmp byte ptr [card_states + si], 1
    je second_already_open

    mov al, [char_idx]
    cmp al, [first_index]
    je same_card_error_retry

    call reveal_selected_card

    mov al, [char_idx]
    mov [second_index], al
    xor ah, ah
    mov si, ax
    mov al, [cards + si]
    mov [second_value], al

    mov al, [first_value]
    cmp al, [second_value]
    je dogru_case

    call eslesme_yanlis
    mov dh, 4
    mov dl, 0
    call draw_grid
    call draw_restart_button
    jmp after_logic

second_already_open:
    call clear_feedback_area
    lea dx, msg_already_open
    call print_feedback_line
    jmp second_pick_retry

same_card_error_retry:
    call clear_feedback_area
    lea dx, msg_already_open
    call print_feedback_line
    jmp second_pick_retry

dogru_case:
    call eslesme_dogru

after_logic:
    call hamle_sonu_check
    jmp game_loop

restart_game:
    mov byte ptr [restart_requested], 0   
    mov byte ptr [restart_prev_down], 0
    
    call reset_game_state

    call clear_screen
    call print_title
    call draw_restart_button

    mov ah, 02h
    mov bh, 00h
    mov dh, 7
    mov dl, 28
    int 10h
    lea dx, msg_restarting
    mov ah, 09h
    int 21h

    call restart_pause
    call clear_screen
    jmp devam_hazirlik 
    
oyun_sure_bitti:
    call play_beep
    mov [game_over], 1
    call clear_bottom_line
    mov ah, 02h
    mov bh, 00h
    mov dh, 20
    mov dl, 0
    int 10h
    lea dx, msg_time_ended
    mov ah, 09h
    int 21h
    jmp program_sonu

oyun_kaybedildi:
    call play_beep
    call clear_bottom_line
    mov ah, 02h
    mov bh, 00h
    mov dh, 20
    mov dl, 0
    int 10h
    lea dx, msg_lose
    mov ah, 09h
    int 21h
    jmp program_sonu

oyun_kazanildi:
    call clear_bottom_line
    mov ah, 02h
    mov bh, 00h
    mov dh, 20
    mov dl, 0
    int 10h
    lea dx, msg_win
    mov ah, 09h
    int 21h
    jmp program_sonu

program_sonu:
    mov ax, 4C00h
    int 21h

main endp

; --- YARDIMCI PROSEDURLER ---

clear_screen proc
    mov ax, 0600h
    mov bh, 07h
    mov cx, 0000h
    mov dx, 184Fh
    int 10h
    mov ah, 02h
    mov bh, 00h
    mov dx, 0000h
    int 10h
    ret
clear_screen endp

clear_bottom_line proc
    mov ax, 0600h
    mov bh, 07h
    mov ch, 18
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 10h
    ret
clear_bottom_line endp

reset_game_state proc
    mov [game_over], 0
    mov [time_up], 0
    mov [restart_requested], 0
    mov [restart_prev_down], 0
    mov [combo_streak], 0
    mov [acik_kart_say], 0
    mov word ptr [hamle_sayisi], 1
    mov [first_index], 0
    mov [second_index], 0
    mov [first_value], 0
    mov [second_value], 0

    mov al, [grid_size]
    cmp al, 6
    jne set_state_4x4

    mov [kalan_hamle], 40
    mov [toplam_cift], 18
    mov [time_left], 240
    ret

set_state_4x4:
    mov [kalan_hamle], 15
    mov [toplam_cift], 8
    mov [time_left], 120
    ret
reset_game_state endp 

grid_warning_delay proc
    push ax
    push bx
    push dx

    mov ah, 00h
    int 1Ah
    mov bx, dx

wait_grid_warning:
    mov ah, 00h
    int 1Ah
    mov ax, dx
    sub ax, bx
    cmp ax, 8
    jb wait_grid_warning

    pop dx
    pop bx
    pop ax
    ret
grid_warning_delay endp

clear_grid_warning proc
    mov ax, 0600h
    mov bh, 07h
    mov ch, 12
    mov cl, 0
    mov dh, 13
    mov dl, 79
    int 10h
    ret
clear_grid_warning endp

print_title proc
    push ax
    push bx
    push dx

    mov ah, 02h
    mov bh, 00h
    mov dh, 2
    mov dl, 30
    int 10h

    lea dx, msg_title
    mov ah, 09h
    int 21h

    pop dx
    pop bx
    pop ax
    ret
print_title endp

print_turn_header proc
    push ax
    push bx
    push cx
    push dx

    mov ah, 02h
    mov bh, 00h
    mov dh, 18
    mov dl, 0
    int 10h

    lea dx, msg_hamle
    mov ah, 09h
    int 21h

    mov ax, [hamle_sayisi]
    xor dx, dx
    mov bx, 10
    div bx              ; AX = onlar/birler ayrimi deðgl, AX/BX sonuc, DX kalan

    mov cx, dx          ; birler

    cmp ax, 0
    je only_ones

    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h

only_ones:
    mov dl, cl
    add dl, '0'
    mov ah, 02h
    int 21h

    lea dx, msg_hamle_son
    mov ah, 09h
    int 21h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_turn_header endp

INCLUDE grid.asm
INCLUDE logic.asm
INCLUDE display.asm
INCLUDE input.asm
end
