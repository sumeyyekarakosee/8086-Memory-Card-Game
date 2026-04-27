; --- AKILLI GRID MODULU (grid.asm) ---

draw_grid proc
    mov al, [grid_size]
    mov [tmp_bl], al

    lea si, card_states

draw_row:
    mov dl, 10
    mov al, [grid_size]
    mov cl, al
    mov ch, 0

draw_column:
    push cx

    ; Sol kenar [
    mov ah, 02h
    mov bh, 00h
    int 10h

    mov ah, 09h
    mov al, '['
    mov bl, 0Bh
    mov cx, 1
    int 10h

    ; Orta kisim
    inc dl
    mov ah, 02h
    int 10h

    cmp byte ptr [si], 1
    je show_open_card

    ; Kapali kart
    mov ah, 09h
    mov al, 177
    mov bl, 07h
    mov cx, 1
    int 10h
    jmp next_step

show_open_card:
    push si
    mov ax, si
    sub ax, offset card_states
    lea di, cards
    add di, ax

    mov ah, 09h
    mov al, [di]
    mov bl, 0Ah
    mov cx, 1
    int 10h
    pop si

next_step:
    ; Sag kenar ]
    inc dl
    mov ah, 02h
    int 10h

    mov ah, 09h
    mov al, ']'
    mov bl, 0Bh
    mov cx, 1
    int 10h

    inc si
    add dl, 2
    pop cx
    loop draw_column

    add dh, 2
    dec [tmp_bl]
    jnz draw_row
    ret
draw_grid endp
