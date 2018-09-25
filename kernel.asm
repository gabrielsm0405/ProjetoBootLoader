org 0x7e00
jmp 0x0000:start

start:
	xor ax, ax
	mov ds, ax
	
	call initVideo
	call initInfo

	.gameloop:
		; call board
		call ball
		call bar
		call moveBall
		call gameControl
		jmp .gameloop
; 
	; jmp done

moveBall:
	pusha
	mov cx, word[ball_PosX]
	mov dx, word[ball_PosY]
	mov bh, byte[sentido_vertical]
	mov bl, byte[sentido_horizontal]

	cmp bh, 1												;calculando o movimento da bola
	je .baixo												;
	sub dx, word[velocidade]								;
	jmp .cima												;
	.baixo:													;
	add dx, word[velocidade]								;
	.cima:													;
															;
	cmp bl, 1												;
	je .direita												;
	sub cx, word[velocidade]								;
	jmp .esquerda											;
	.direita:												;
	add cx, word[velocidade]								;
	.esquerda:												;

	cmp cx, word[limite_esquerda]							;verificando limites da tela
	jl .skip1												;
	cmp cx, word[limite_direita]							;
	jg .skip1												;
	mov word[ball_PosX], cx									;
	jmp .skip2												;
	.skip1:													;
	cmp bl, 0												;
	je .zero_horizontal										;
	mov byte[sentido_horizontal], 0							;
	jmp .um_horizontal										;
	.zero_horizontal:										;
	mov byte[sentido_horizontal], 1							;
	.um_horizontal:											;
	.skip2:													;

	cmp dx, word[limite_cima]								
	jl .skip3
	cmp dx, word[limite_baixo]
	jg .skip3
	mov word[ball_PosY], dx
	jmp .skip4
	.skip3:
	cmp bh, 0
	je .zero_vertical
	mov byte[sentido_vertical], 0
	jmp .um_vertical
	.zero_vertical:
	mov byte[sentido_vertical], 1
	.um_vertical:
	.skip4:

	popa
	ret


;raio e diâmetro ok
ball:
	mov dx, word[ball_PosY]
	sub dx, word[ball_Raio]
	sub dx, word[velocidade]

	mov al, 1

	mov bl, byte[ball_Dia]
	add bl, byte[velocidade]
	add bl, byte[velocidade]
	.innerloop:
		mov cx, word[ball_PosX]
		sub cx, word[ball_Raio]
		sub cx, word[velocidade]
		mov bh, byte[ball_Dia]
		add bh, byte[velocidade]
		add bh, byte[velocidade]
		.otherloop:
			push bx
			push ax                         ; uso o push e o pop aninhado dessa maneira para não esquecer ou trocar a ordem
                mov ax, cx
                push bx
                    push cx
                        push dx
                            sub ax, word[ball_PosX]     ; 159 é o meio da tela
                            mul ax          ; agora ax guarda o valor de um dos catetos ao quadrado
                        pop dx
                    pop cx
                pop bx
                mov bx, ax                  ; ax precisará ser usado em mul mais a frente
                mov ax, dx
                push bx
                    push cx
                        push dx
                            sub ax, word[ball_PosY]
                            mul ax          ; agora ax guarda o valor do outro cateto ao quadrado
                        pop dx
                    pop cx
                pop bx
                add bx, ax                  ; no final, bx = a^2 + b^2, ax = cor, cx e dx têm as cordenadas
            pop ax

            cmp bx, word[ball_RaioQ] 
            pop bx                   ; 1600 é o valor da hipotenusa(o tamanho do meu raio) ao quadrado (40^2 = 1600) 
            jge .skip

			push bx
			call writePixel
			pop bx                 
			jmp .skip2
            .skip:
            push ax
           	push bx
           	mov al, 0
           	call writePixel
           	pop bx
           	pop ax
           	.skip2:

			inc cx
			dec bh
			cmp bh, 0
			jge .otherloop
		inc dx
		dec bl
		cmp bl, 0
		jge .innerloop

	ret

gameControl:
	call checkKey
	mov cx, word[player_PosX]
	cmp ah, 0x20
	jne .n1
	add cx, 4
	.n1:
	cmp ah, 0x1e
	jne .n2
	sub cx, 4
	.n2:
	call validation
	ret

checkKey:
	mov ah, 1
	int 0x16
	jz .end
	mov ax, 0
	int 0x16
	ret
	.end:
	mov ax, 0
	ret

validation:
	cmp cx, 0
	jl .skip
	push ax
	mov ax, 320
	sub al, byte[player_TamX]
	cmp cx, ax
	pop ax
	jg .skip
	mov word[player_PosX], cx
	.skip:
	ret


bar:
	pusha
	mov cx, word[player_PosX]
	dec cx
	call bordas

	mov cx, word[player_PosX]
	push ax
	xor ax, ax
	add al, byte[player_TamX]
	add al, byte[player_Borda]
	add cx, ax
	pop ax
	call bordas
	popa

	xor bx, bx
	mov bl, byte[player_TamY]		
	mov dx, word[player_PosY]
	mov al, byte[player_Color]

	.innerloop:
		mov bh, byte[player_TamX]		
		mov cx, word[player_PosX]
		.otherloop:
			push bx
			call writePixel
			pop bx
			inc cx
			dec bh
			cmp bh, 0
			jge .otherloop
		inc dx
		dec bl
		cmp bl, 0
		jg .innerloop
	ret

bordas:
	mov al, 0
	mov bh, byte[player_Borda]
	.innerloop:
		mov dx, word[player_PosY]
		mov bl, byte[player_TamY]
		.otherloop:
			push bx
			call writePixel
			pop bx

			inc dx
			dec bl
			cmp bl, 0
			jg .otherloop
		dec cx
		dec bh
		cmp bh, 0
		jg .innerloop
	ret

writePixel:
    mov ah, 0ch   
    mov bh, 0      
    int 10h
    ret

initVideo:
	mov ah, 0
	mov al, 13h
	int 10h
	ret

initInfo:
	mov ax, word[ball_Raio]				;calculando o diametro
	add ax, word[ball_Raio]
	mov byte[ball_Dia], al

	mov ax, word[ball_Raio]				;calculando r^2
	mul word[ball_Raio]
	mov word[ball_RaioQ], ax

	mov ax, word[limite_esquerda]
	add ax, word[ball_Raio]
	mov word[limite_esquerda], ax

	mov ax, word[limite_cima]
	add ax, word[ball_Raio]
	mov word[limite_cima], ax

	mov ax, word[limite_direita]
	sub ax, word[ball_Raio]
	mov word[limite_direita], ax

	mov ax, word[limite_baixo]
	sub ax, word[ball_Raio]
	mov word[limite_baixo], ax
	ret

board:
	mov al, 4
	mov dx, 150
	.innerloop:
		mov cx, 100
		.otherloop:
			call writePixel
			inc cx
			cmp cx, 220
			jl .otherloop
		inc dx
		cmp dx, 200
		jl .innerloop
	ret


done:
    jmp $

limite_esquerda dw 0
limite_direita dw 319
limite_cima dw 0
limite_baixo dw 199

sentido_vertical db 0
sentido_horizontal db 0

ball_Dia db 0
ball_Raio dw 5
ball_RaioQ dw 0
ball_PosX dw 144
ball_PosY dw 182
velocidade dw 1

player_PosX dw 144
player_PosY dw 182

player_TamX db 30
player_TamY db 8	
player_Color db 1
player_Borda db 5

times (512 * 2)-($-$$) db 0		
dw 0xaa55			
