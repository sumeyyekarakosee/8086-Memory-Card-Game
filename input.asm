; --- input.asm ---

read_key_with_timer proc
wait_key:
    call update_timer
    call update_time_display
    cmp [time_up], 1
    je key_timeout

    call check_restart_input
    cmp al, 1
    je restart_hit

    mov ah, 01h
    int 16h
    jz wait_key

    mov ah, 00h
    int 16h
    ret

restart_hit:
    mov [restart_requested], 1
    xor al, al
    ret

key_timeout:
    mov [time_up], 1
    xor al, al
    ret
read_key_with_timer endp

get_selection proc
    push ax
    push bx
    push bp

    mov [restart_requested], 0
    mov bp, dx

retry_selection:
    call clear_feedback_area

    mov ah, 02h
    mov bh, 00h
    mov dh, 20
    mov dl, 0
    int 10h

    mov dx, bp
    mov ah, 09h
    int 21h

read_row:
    cmp [time_up], 1
    je selection_timeout

    call read_key_with_timer
    cmp [restart_requested], 1
    je selection_restart
    cmp [time_up], 1
    je selection_timeout
    cmp al, 0
    je selection_timeout

    cmp al, '1'
    jb invalid_selection

    mov bl, [grid_size]
    add bl, '0'
    cmp al, bl
    ja invalid_selection

    mov dl, al
    mov ah, 02h
    int 21h

    sub al, '1'
    mov [sel_row], al

read_col:
    cmp [time_up], 1
    je selection_timeout

    call read_key_with_timer
    cmp [restart_requested], 1
    je selection_restart
    cmp [time_up], 1
    je selection_timeout
    cmp al, 0
    je selection_timeout

    cmp al, '1'
    jb invalid_selection

    mov bl, [grid_size]
    add bl, '0'
    cmp al, bl
    ja invalid_selection

    mov dl, al
    mov ah, 02h
    int 21h

    sub al, '1'
    mov [sel_col], al

    mov al, [sel_row]
    mov bl, [grid_size]
    mul bl
    add al, [sel_col]
    mov [char_idx], al

    pop bp
    pop bx
    pop ax
    ret

invalid_selection:
    call play_beep
    call clear_feedback_area
    lea dx, msg_invalid_selection
    call print_feedback_line
    jmp retry_selection

selection_restart:
    pop bp
    pop bx
    pop ax
    ret

selection_timeout:
    mov [time_up], 1
    pop bp
    pop bx
    pop ax
    ret
get_selection endp

reveal_selected_card proc
    mov al, [sel_row]
    mov bl, 2
    mul bl
    add al, 4
    mov dh, al

    mov al, [sel_col]
    mov bl, 4
    mul bl
    add al, 11
    mov dl, al

    mov ah, 02h
    mov bh, 00h
    int 10h

    mov al, [char_idx]
    xor ah, ah
    lea si, cards
    add si, ax

    mov ah, 09h
    mov al, [si]
    mov bl, 0Ah
    mov cx, 1
    int 10h
    ret
reveal_selected_card endp

check_restart_input proc
    push bx
    push cx
    push dx
    push si
    push di

    mov ax, 0003h
    int 33h
    ; BX = buton, CX = X piksel, DX = Y piksel

    test bx, 1
    jz cri_released         ; sol tuþ basýlý deðil › bayraðý sýfýrla

    ; X piksel › sütun
    push dx                 ; Y pikselini koru (DIV DX'i bozar)
    mov ax, cx
    xor dx, dx
    mov di, 8
    div di
    mov si, ax              ; SI = sütun

    ; Y piksel › satýr
    pop ax                  ; Y pikselini geri al
    xor dx, dx
    mov di, 8
    div di
    mov di, ax              ; DI = satýr

    ; RESTART butonu alaný: satýr 4-6, sütun 61-72
    cmp di, 4
    jb cri_no_hit
    cmp di, 6
    ja cri_no_hit
    cmp si, 61
    jb cri_no_hit
    cmp si, 72
    ja cri_no_hit

    ; Daha önce basýlýydý mý? (tek tetikleme için)
    cmp byte ptr [restart_prev_down], 1
    je cri_no_hit

    mov byte ptr [restart_prev_down], 1
    mov byte ptr [restart_requested], 1
    mov al, 1
    jmp cri_done

cri_released:
    mov byte ptr [restart_prev_down], 0

cri_no_hit:
    xor al, al

cri_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret
check_restart_input endp