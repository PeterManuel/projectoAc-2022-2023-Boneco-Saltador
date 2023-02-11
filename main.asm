;INTEGRANTES
;Maria Francisco Joaquim
;Gonídia Maugissa Gonçalo
;Antônia Alfredo
;Feliciano Antônio

;fazendo endereçamento dos dispositivos

MATRIX_PIXEL EQU 8000H  ;constante que contem o valor do endereço do ecram
TECLADO_IN EQU 0C000H   ;constante que contem o valor do endereço da entrada do teclado
display_contador Equ 0A000H ;constante que contem o valor do endereço do dysplay hexadecimal
TECLADO_OUT EQU 0E000H  ;constante que contem o valor do endereço da saida do teclado
testador_de_linha_do_taclado	EQU	1 ;constante usada para iniciar  a testar apartir da linha 1 do teclado
filtro_3_0	EQU	000FH ; máscara para isolar os 4 bits de menor peso	

PLACE		1000H ; definiu-se convencionalmente o espaço 
                  ;reservado para pilha apartir do endereço 1000H

pilha:		TABLE 100H	;reservando um tamanho de 256 bytes para pilha

FIM_PILHA:	; fazendo com que a etiqueta FIM_PILHA aponte para o topo da pilha

PLACE 2000H ; definiu-se convencionalmente o espaço 
            ;reservado para variaveis  apartir do endereço 2000H
altura:STRING 5

memoria_armazenamento_tecla:WORD -1 ;espaço reservado de 2 bytes (16 bits) para armazernar qualquer tecla
              ; que for premida


buffer_mortos:string 0 ;espaço reservado de 1 byte (8 bits) para o numero de iobejctos acertados
                       ;pelos plataformas
;------------------------valores de linha do teclado-----------------------------------

linha1:STRING -1,0,1,-1,2,-1,-1,-1,3  ;(contem valor 0,1,2,3)
linha2:STRING -1,4,5,-1,6,-1,-1,-1,7  ;(contem valor 4,5,5,7)
linha3:STRING -1,8,9,-1,0ah,-1,-1,-1,0ch  ;(contem valor 8,9,a,b)
linha4:STRING -1,0ch,0dh,-1,0eh,-1,-1,-1,0fh  ;(contem valor c,d,e,f)


;----valores usados para ativar pixel apartir de uma coordenada(linha,coluna) dada

valor_activo:STRING 80H,40H,20H,10H,08H,04H,02H,01H

;----valores usados para desativar pixel apartir de uma coordenada dada

valor_inativo:STRING 7FH,0BFH,0DFH,0EFH,0F7H,0FBH,0FDH,0FEH


;--------seccão na qual definimos os espaços em memoria que são usadas para
;--------armazenar cada objecto do jogo (bonecos, balas e plataformas)

bonecoC :STRING 7
bonecoL :STRING 24
boneco_estado :STRING 01h

plataforma1C :STRING 11
plataforma1L :STRING 19
plataforma1_estado :STRING 01h

plataforma2C :STRING 20
plataforma2L :STRING 8
plataforma2_estado :STRING 01h


objecto1C :STRING 15
objecto1L :STRING 16
objecto1_estado :STRING 1


objecto2C :STRING 23
objecto2L :STRING 5
objecto2_estado :STRING 1


int0: STRING 0 ;espaço na qual é armazenada valor(0,1) para sinalizar a ocorrência de interrupcão 0
int1: STRING 0 ;espaço na qual é armazenada valor(0,1) para sinalizar o ocorrência de interrupcão 1



; tabela de palavra na qual é armazenada as direcções do boneco
vector_de_movimentacao_do_boneco: 
    WORD mover_boneco_esquerda   ;tecla 0
    WORD mover_boneco_direita ;tecla 1
    WORD saltar; tecla 2
    WORD mover_boneco_baixo;tecla 3
    WORD mover_boneco_superior_direito ;tecla 4
    WORD mover_boneco_superior_esquerdo;tecla 5
    WORD mover_boneco_inferior_direito;tecla 6
    WORD mover_boneco_inferior_esquerdo;tecla 7

;TABELAS PARA INTERRUPÇÕES
place 3000h
interrupcoes: WORD movimentacao_boneco
 WORD movimentacao_objecto


PLACE 0


main:
    mov	SP, FIM_PILHA
    MOV BTE,interrupcoes
    call desenha_chao
    call acender_boneco
    call acender_plataforma1
    call acender_plataforma2
    call acender_objecto1
    call acender_objecto2
   
    EI ;habilitar todas interrupcoes
    JMP jogo

    jogo:
        EI0 ;habilita interrupcão 0
        EI1 ;habilita interrupcão 1

        CALL pressionar_tecla ; chama o processo do teclado
        CALL movimenta_boneco
        CALL saltar_boneco_cima
        CALL mover_boneco_baixo
        CALL mover_plataformas ;chama o processo para movimentar plataformas 
        CALL detecta_colisao_objecto1
        CALL detecta_colisao_objecto2
        CALL contador_objectos_comidos
                            


    jmp jogo ;faz o loop infinito  do jogo

fim_programa: JMP fim_programa


printf:
    push R0
    push R1
    push R2
    push R3
    push R4
;parametro linha coluna r0,r1

    mov R4,MATRIX_PIXEL ; faz com que R4 aponte para a endereço 8000h isto é na qual localizado
                        ;o PIXEL SCREEN

   ;faz o calculo do endereços  
    SHL R1,2  ;(R1<-r1*4)
    ADD R1,R4 ;(R1<-R1+R4)

    MOV R0,8 ;(R0<-8)
    MOV R4,R2 ;(R4<-R2)
    DIV R4,R0 ;(R4<-R4/R0)

    ;formula endereço=8000h + 4*linha(0..31) + byte(0..3)

    ESCREVA:
    ADD R1,R4 ; (R4«1<-R4)
    MOV R4,8 ; (R4<-8)
    MOD R2,R4 ;(R2<-R2%R4)

;compara o que se quer fazer(acender ou apagar pixel)

    CMP R3,1 ;se colocarmos valor 1 em R3 então é para desativar o pixel
    JZ APAGA ;(se R3==1 salta par APAGA)

    ;significa que se estiver um valor qualquer diferente de 1 em R3
    ;então supõe-se activar(acender um pixel)

;quando se quer acender
    ACENDE:
        MOV R4,valor_activo ;referencia o valor_activo cujos os valores servem para activar pixeis
        ADD R4,R2 ;acessa a posição do valor necessário para activar um determidado pixel

        MOVB R0,[R4] ;faz a leitura do valor  que se deseja escrever
        MOVB R2,[R1] ;faz a leitura do valor que já está presente na memória que se deseja escrever

        OR R0,R2 ; operação or de modo a manter a integridade da posição de memória na qual se deseja alterar
        JMP PIXEL

;quando se quer apagar
    APAGA:
        MOV R4,valor_inativo ;referencia o valor_inactivo cujos os valores servem para desactivar pixeis
        ADD R4,R2 ;acessa a posição do valor necessário para desactivar um determidado pixel

        MOVB R0,[R4]  ;faz a leitura do valor  que se deseja escrever
        MOVB R2,[R1]  ;faz a leitura do valor que já está presente na memória que se deseja escrever

        AND R0,R2 ; operação or de modo a manter a integridade da posição de memória na qual se deseja alterar
        JMP PIXEL

;passa o valor na matrix de pixel
    PIXEL:
    MOVB [R1], R0 ;escreve o valor independentemente do que se quer fazer (apagar ou acender)  que 
        ;deve ser escrito para memória alvo

    pop R4
    pop R3
    pop R2
    pop R1
    pop R0

ret

desenha_tudo:
    call desenha_chao
    call acender_boneco
    call acender_plataforma1
    call acender_plataforma2
    call acender_objecto1
    call acender_objecto2


ret


;terminou matrix pixel

pressionar_tecla:
PUSH  R1
PUSH R5
PUSH R6
PUSH R7
PUSH R9

MOV	R5, TECLADO_IN ;referencia a saida do teclado
MOV	R6, TECLADO_OUT ;referencia a entrada do teclado
MOV R9,memoria_armazenamento_tecla ;referencia o endereço de memória na qual será armazenada a tecla que for pressionada

MOV	R1, testador_de_linha_do_taclado ;passa o valor 0001 em R1( valor para testar a 1ª linha do teclado)
                                
testa_linha:                        
CMP R1,7 ;(verifica se já testou todas as linhar)
          
JGT nenhuma_tecla_primida ;caso R1 tenha valor maior que 7 então todas as linhas foram testadas
                            ; e nenhuma tecla foi premida

MOVB [R5], R1	;activar a linha a ser testada
	MOVB 	R7, [R6]	; ler a saida do teclado
	MOV R10,filtro_3_0
	AND R7,R10 ;sendo que para o teclado somente entra ou sai 4bits então deve filtrar de modo a evitar
               ;interferência
	AND R7, R7	;fazendo a operação and de modo a saber se o valor diferente de zero	
	JNZ guardar		; caso for diferente de zero então alguma tecla foi premida e deve guardar na memoria
	
	SHL R1,1 ; faz o deslocamento de bit de modo a testar outra linha
JMP testa_linha ;repete o pocesso de teste de linha do teclado

nenhuma_tecla_primida: ;seccão em todas linhas foram testada isto é até a 4ª e nenhuma
                        ; foi premida sendo assim deve armazernar -1
	MOV R7,-1
	MOV [R9],R7
	JMP fim_tecla
	guardar:
	CALL descodifica_tecla_primida ;se alguma tecla foi premida então deve
                                    ; chamar a função de modo a decofificar a tecla premida

	fim_tecla:

POP R9
POP R7
POP R6
POP R5
POP R1
RET	

;;;;;;;; fim tratamento do teclado ;;;;;;;;;;;;

;;;;;;;; Descodificando a tecla primida ;;;;;;;;;
descodifica_tecla_primida:
PUSH R1
PUSH R7
PUSH R9
; faz a verificão para saber que linha cuja tecla foi activa
   cmp r1,1 
    jz linha_teclado1

    cmp r1,2
    jz linha_teclado2

    cmp r1,4
    jz linha_teclado3

    jz linha_teclado4
	
; fim da verificão para saber que linha cuja tecla foi activa

    linha_teclado1:

    mov r1,linha1
    add r1,r7 ; acessa o indice da tecla premida
    jmp salvar_tecla

    linha_teclado2:

    mov r1,linha2
    add r1,r7 ; acessa o indice da tecla premida
    jmp salvar_tecla

    linha_teclado3:

    mov r1,linha3
    add r1,r7 ; acessa o indice da tecla premida
    jmp salvar_tecla

        linha_teclado4:

    mov r1,linha4
    add r1,r7 ; acessa o indice da tecla premida

salvar_tecla:
MOVB R7,[R1] ; acessa o valor da lecla em uma da linha que foi activa
MOV [R9],R7 ; armazena o valor da tecla que é premida
POP R9
POP R7
POP R1
RET
;;;;;;;;;;;; fim descodificar tecla comprimida ;;;;;;;;


desenha_chao:
    push r0
    push r1
    push r2

    mov r0,MATRIX_PIXEL
    mov r2,74H
    mov r1,0FFFFH

    add r0,r2
    mov [r0],r1

    add r0,2H
    mov [r0],r1

    pop r2
    pop r1
    pop r0
ret


desenha_boneco:

    PUSH R1
    PUSH R2

    PUSH R4

    MOV R4,bonecoL

    MOVB R1,[R4]

    MOV R4,bonecoC
    MOVB R2,[R4]

    call printf

    sub R2,2

    add R1,1

    mov r4,5

    braco_boneco:
    CMP r4,0
    jz fim_braco

    call printf
    add r2,1
    sub r4,1
    JMP braco_boneco

    fim_braco:

    sub r2,3
    add r1,1

    call printf

    sub r2,1
    add r1,1
    call printf

    add r2,2
    call printf

    add r1,1
    call printf

    sub r2,3
    call printf

    POP R4
    POP R2
    POP R1

ret


acender_boneco:
    PUSH R3
    MOV R3,0
    CALL desenha_boneco
    POP R3
ret

apagar_boneco:
    PUSH R3
    MOV R3,1
    CALL desenha_boneco
    POP R3
ret




desenha_plataforma1:

    PUSH R1
    PUSH R2
    PUSH R4

    MOV R4,plataforma1L

    MOVB R1,[R4]

    MOV R4,plataforma1C
    MOVB R2,[R4]

    mov r4,8

    topo_plataforma1:
    CMP r4,0
    jz fim_topo1

    call printf
    add r2,1
    sub r4,1
    JMP topo_plataforma1

    fim_topo1:


    mov r4,8
    add r1,1
    sub r2,r4

    base_plataforma1:
    CMP r4,0
    jz fim_topo2

    call printf
    add r2,1
    sub r4,1
    JMP base_plataforma1

    fim_topo2:


    POP R4
    POP R2
    POP R1

ret


acender_plataforma1:

    PUSH R3
    MOV R3,0
    CALL desenha_plataforma1
    POP R3
ret

apagar_plataforma1:

    PUSH R3
    MOV R3,1
    CALL desenha_plataforma1
    POP R3
ret





desenha_plataforma2:

    PUSH R1
    PUSH R2
    PUSH R4

    MOV R4,plataforma2L

    MOVB R1,[R4]

    MOV R4,plataforma2C
    MOVB R2,[R4]

    mov r4,8

    topo_plataforma2:
    CMP r4,0
    jz fim2_topo1

    call printf
    add r2,1
    sub r4,1
    JMP topo_plataforma2

    fim2_topo1:


    mov r4,8
    add r1,1
    sub r2,r4

    base_plataforma2:
    CMP r4,0
    jz fim2_topo2

    call printf
    add r2,1
    sub r4,1
    JMP base_plataforma2

    fim2_topo2:


    POP R4
    POP R2
    POP R1

ret



acender_plataforma2:

    PUSH R3
    MOV R3,0
    CALL desenha_plataforma2
    POP R3
ret


apagar_plataforma2:

    PUSH R3
    MOV R3,1
    CALL desenha_plataforma2
    POP R3
ret



desenha_objecto1:

    PUSH R1
    PUSH R2
    PUSH R4

    MOV R4,objecto1L

    MOVB R1,[R4]

    MOV R4,objecto1C
    MOVB R2,[R4]

    call printf
    add r1,1
    call printf
    add r1,1
    call printf

    sub r1,1
    sub r2,1

    call printf

    add r2,2
    call printf


    POP R4
    POP R2
    POP R1

ret



acender_objecto1:

    PUSH R3
    MOV R3,0
    CALL desenha_objecto1
    POP R3
ret

apagar_objecto1:

    PUSH R3
    MOV R3,1
    CALL desenha_objecto1
    POP R3
ret




desenha_objecto2:

    PUSH R1
    PUSH R2
    PUSH R4

    MOV R4,objecto2L

    MOVB R1,[R4]

    MOV R4,objecto2C
    MOVB R2,[R4]

    call printf
    add r2,2
    call printf

    add r1,1
    sub r2,1
    call printf

    add r1,1
    sub r2,1
    call printf

    add r2,2
    call printf

    POP R4
    POP R2
    POP R1

ret



acender_objecto2:

    PUSH R3
    MOV R3,0
    CALL desenha_objecto2
    POP R3
ret

apagar_objecto2:

    PUSH R3
    MOV R3,1
    CALL desenha_objecto2
    POP R3
ret

movimenta_boneco:
PUSH R0
PUSH R1
PUSH R2
PUSH R3

MOV R0,memoria_armazenamento_tecla 
MOV R1,boneco_estado
MOVB R3,[R1]

CMP R3,2
JZ boneco_estado2

boneco_estado1:
    MOV R1,[R0]
    CMP R1,-1
    JZ fim_movimento_boneco
    CMP R1,7
    JGT fim_movimento_boneco    ; se for > 7 fim, movimentamos apenas com 7 teclas

    MOV R2,vector_de_movimentacao_do_boneco
    SHL R1,1
    ADD R2,R1
    MOV R1,[R2]
    CALL R1
    MOV R1,2
    MOV R3,boneco_estado
    MOVB [R3],R1
    JMP fim_movimento_boneco

boneco_estado2:
    MOV R1,[R0]
    CMP R1,-1
    JNZ fim_movimento_boneco
    MOV R1,1
    MOV R3,boneco_estado
    MOVB [R3],R1

fim_movimento_boneco:

POP R3
POP R2
POP R1
POP R0
RET


;;;;;;;;;;;;;;;;;; INICIO BAIXAR boneco ;;;;;;;;;;;;;;;;;;
; resume-se em apagar o boneco na posição actual  
; para acendê-lo na posição mais a baixo

mover_boneco_baixo:

PUSH R4
PUSH R5
PUSH R6

MOV R4,altura       
MOVB R5,[R4]  
MOV R4,5
CMP R5,R4
JNZ fim_mover_baixo

MOV R4,bonecoL        
MOVB R5,[R4]  
MOV R4,24
CMP R5,R4
JZ fim_mover_baixo

;verificar se chocou com uma das plataformas1

MOV R4,plataforma1L       
MOVB R5,[R4]  

MOV R4,bonecoL

MOVB R6,[R4]

ADD R6,5

CMP R6,R5
JNZ ignore_baixo1

;obtem a coluna
MOV R4,plataforma1C
MOVB R5,[R4]

MOV R4,bonecoC
MOVB R6,[R4]

ADD R6,2

CMP R6,R5
JZ fim_mover_baixo

;ADD R5,6
JN ignore_baixo1

MOV R4,11
ADD R5,R4
CMP R6,R5
JP ignore_baixo1
JMP fim_mover_baixo

ignore_baixo1:
;verificar se chocou com uma das plataformas

MOV R4,plataforma2L       
MOVB R5,[R4]  

MOV R4,bonecoL

MOVB R6,[R4]

ADD R6,5

CMP R6,R5
JNZ ignore_baixo2

;obtem a coluna
MOV R4,plataforma2C
MOVB R5,[R4]

MOV R4,bonecoC
MOVB R6,[R4]

ADD R6,2

CMP R6,R5
JZ fim_mover_baixo

;ADD R5,6
JN ignore_baixo2

MOV R4,11
ADD R5,R4
CMP R6,R5
JP ignore_baixo2
JMP fim_mover_baixo


ignore_baixo2:

call apagar_boneco 
                    
MOV R4,bonecoL        
MOVB R5,[R4]        

ADD R5,1            
MOVB [R4],R5        

CALL acender_boneco

fim_mover_baixo:
POP R6
POP R5
POP R4

RET
;;;;;;;;;;;;;;;;;;;; fim baixar boneco ;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;; INICIO SUBIR boneco ;;;;;;;;;;;;;;;;;;
; resume-se em apagar o boneco na posição actual  
; para acendê-lo na posição mais acima

mover_boneco_cima:

PUSH R4
PUSH R5

; restringir o movimento de cima para o boneco
MOV R4,bonecoL        
MOVB R5,[R4]  
MOV R4,0
CMP R5,R4
JZ fim_mover_cima
; fim restringir o movimento de cima para o boneco


call apagar_boneco

MOV R4,bonecoL
MOVB R5,[R4]

SUB R5,2

MOVB [R4],R5

CALL acender_boneco
fim_mover_cima: 

POP R5
POP R4

RET
;;;;;;;;;;;;;;;; fim subir boneco ;;;;;;;;;;;;;;;;;;;;




;;;;;;;;;;; INICIO MOVER boneco A DIREITA ;;;;;;;;;;;;
; resume-se em apagar o boneco na posição actual  
; para acendê-lo na posição mais a direita

mover_boneco_direita:

PUSH R4
PUSH R5

MOV R4,bonecoC        
MOVB R5,[R4]  
MOV R4,28
CMP R5,R4
JZ fim_mover_direita

call apagar_boneco

MOV R4,bonecoC
MOVB R5,[R4]

ADD R5,1

MOVB [R4],R5

CALL acender_boneco

fim_mover_direita:


POP R5
POP R4

RET
;;;;;;;;;;;;;;;; fim mover boneco direita ;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;; INICIO MOVER boneco A ESQUERDA ;;;;;;;;;;;;;;
; resume-se em apagar o boneco na posição actual  
; para acendê-lo na posição mais a direita

mover_boneco_esquerda:

PUSH R4
PUSH R5
MOV R4,bonecoC        
MOVB R5,[R4]  
MOV R4,2
CMP R5,R4
JZ fim_mover_esquerda
call apagar_boneco

MOV R4,bonecoC
MOVB R5,[R4]

SUB R5,1

MOVB [R4],R5

CALL acender_boneco

fim_mover_esquerda:

POP R5
POP R4

RET
;;;;;;;;;;;;;;;; fim mover boneco a esquerda ;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;; INICIO MOVER boneco AO CANTO SUPERIOR DIREITO ;;;;;;;;;;
; resume-se em apagar o boneco na posição actual  
; para acendê-lo no seu correspondente canto superior direito

mover_boneco_superior_direito:


PUSH R4
PUSH R5

MOV R4,bonecoC        
MOVB R5,[R4]  
MOV R4,28
CMP R5,R4
JZ fim_canto_superior_directo

MOV R4,bonecoL        
MOVB R5,[R4]  
MOV R4,0
CMP R5,R4
JZ fim_canto_superior_directo

call apagar_boneco

;coluna
MOV R4,bonecoC
MOVB R5,[R4] ;faz a leitura da coluna do boneco

ADD R5,1

MOVB [R4],R5

;linha

MOV R4,bonecoL
MOVB R5,[R4] ;faz a leitura lnha do boneco

SUB R5,1

MOVB [R4],R5

CALL acender_boneco

fim_canto_superior_directo:

POP R5
POP R4

RET
;;;;;;;;;;;;; fim mover boneco ao canto superior direito ;;;;;;;;


;;;;;;;;;;;;;; INICIO MOVER boneco AO CANTO SUPERIOR ESQUERDO ;;;;;;;;;;
; resume-se em apagar o boneco na posição actual  
; para acendê-lo no seu correspondente canto superior esquerdo

mover_boneco_superior_esquerdo:

PUSH R4
PUSH R5

MOV R4,bonecoC        
MOVB R5,[R4]  
MOV R4,2
CMP R5,R4
JZ fim_canto_superior_esquerdo

MOV R4,bonecoL        
MOVB R5,[R4]  
MOV R4,0
CMP R5,R4
JZ fim_canto_superior_esquerdo


call apagar_boneco

;coluna
MOV R4,bonecoC
MOVB R5,[R4] ;faz a leitura da coluna do boneco

SUB R5,1

MOVB [R4],R5

;linha

MOV R4,bonecoL
MOVB R5,[R4] ;faz a leitura lnha do boneco

SUB R5,1

MOVB [R4],R5

CALL acender_boneco
fim_canto_superior_esquerdo:

POP R5
POP R4

RET
;;;;;;;;;;;; fim mover boneco ao canto superior esquerdo ;;;;;;;;

;;;;;;;;;;;;;; INICIO MOVER boneco AO CANTO INFERIOR DIREITO ;;;;;;;;;;
; resume-se em apagar o boneco na posição actual  
; para acendê-lo no seu correspondente canto inferior direito

mover_boneco_inferior_direito:

PUSH R4
PUSH R5

MOV R4,bonecoC        
MOVB R5,[R4]  
MOV R4,28
CMP R5,R4
JZ fim_canto_inferior_direito

MOV R4,bonecoL        
MOVB R5,[R4]  
MOV R4,29
CMP R5,R4
JZ fim_canto_inferior_direito


call apagar_boneco


;coluna
MOV R4,bonecoC
MOVB R5,[R4] ;faz a leitura da coluna do boneco

ADD R5,1

MOVB [R4],R5

;linha

MOV R4,bonecoL
MOVB R5,[R4] ;faz a leitura lnha do boneco

ADD R5,1

MOVB [R4],R5

CALL acender_boneco
fim_canto_inferior_direito:


POP R5
POP R4

RET
;;;;;;;;;;;; fim mover boneco ao canto inferior direito ;;;;;;;;

;;;;;;;;;;;;;; INICIO MOVER boneco AO CANTO INFERIOR DIREITO ;;;;;;;;;;
; resume-se em apagar o boneco na posição actual  
; para acendê-lo no seu correspondente canto inferior esquerdo

mover_boneco_inferior_esquerdo:

PUSH R4
PUSH R5

MOV R4,bonecoC        
MOVB R5,[R4]  
MOV R4,2
CMP R5,R4
JZ fim_canto_inferior_esquerdo

MOV R4,bonecoL        
MOVB R5,[R4]  
MOV R4,29
CMP R5,R4
JZ fim_canto_inferior_esquerdo


call apagar_boneco

;coluna
MOV R4,bonecoC
MOVB R5,[R4] ;faz a leitura da coluna do boneco

SUB R5,1

MOVB [R4],R5

;linha
MOV R4,bonecoL
MOVB R5,[R4] ;faz a leitura lnha do boneco

ADD R5,1

MOVB [R4],R5

CALL acender_boneco
fim_canto_inferior_esquerdo:

POP R5
POP R4

RET


; Rotina que é chamada quando ocorre interrupcão 0 (movimentacao dos plataformas inimigos)
movimentacao_boneco:
PUSH R1
PUSH R4

MOV R1,int0
MOV R4,1
MOVB [R1],R4

POP R4
POP R1
RFE


; Rotina que é chamada quando ocorre interrupcão 1 (movimentacao da bala e boneco)
movimentacao_objecto:

PUSH R1
PUSH R4

MOV R1,int1
MOV R4,1
MOVB [R1],R4

POP R4
POP R1
RFE


;;;;;;;;;;;;;;;inicio saltar;;;;;;;;;;;;;;;;;;;;;;;;;

saltar_boneco_cima:

    PUSH R1
    PUSH R4
    MOV R1,altura
    MOVB R4,[R1]
    CMP R4,5
    JZ fim_pular

    DI0
    MOV R1,int0
    MOVB R4,[R1]
    CMP R4,1
    JNZ fim_pular

    call mover_boneco_cima
    MOV R1,altura
    MOVB R4,[R1]
    ADD R4,1
    MOVB [R1],R4

    MOV R1,int0
    MOV R4,0
    MOVB [R1],R4

    fim_pular:

    POP R4
    POP R1

RET

saltar:
    PUSH R1
    PUSH R4

    MOV R1,altura
    MOV R4,0
    MOVB [R1],R4

    POP R4
    POP R1
ret



;;;;;;;;;;;;;;fim saltar;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;  INICIO MOVER plataforma INIMIGO 1;;;;;;;;;;;;;;;;;;;;;
mover_plataforma1_baixo:

PUSH R1
PUSH R2
PUSH R4

call apagar_plataforma1

MOV R2,32

MOV R4,plataforma1C
MOVB R1,[R4]

continua1:
ADD R1,1
MOVB [R4],R1

CMP R1,R2
JNZ keep
CALL inicializa_plataforma1_posicao


keep:
CALL acender_plataforma1

POP R4
POP R2
POP R1
RET
;;;;;;;;;;;; fim mover plataforma inimigo1 ;;;;;;;;

;;;;;;;;;;;  INICIO MOVER plataforma INIMIGO 2;;;;;;;;;;;;;;;;;;;;;
mover_plataforma2_baixo:

PUSH R1
PUSH R2
PUSH R4

call apagar_plataforma2

MOV R2,32

MOV R4,plataforma2C
MOVB R1,[R4]

continua2:
ADD R1,1
MOVB [R4],R1

CMP R1,R2
JNZ keep2
CALL inicializa_plataforma2_posicao


keep2:
CALL acender_plataforma2

POP R4
POP R2
POP R1
RET



inicializa_plataforma1_posicao:

PUSH R1
PUSH R2
PUSH R4



MOV R4,plataforma1C
MOV R1,0
MOVB [R4],R1


;MOV R4,plataforma1C
;MOV R1,3
;MOVB [R4],R1


POP R4
POP R2
POP R1
RET


inicializa_plataforma2_posicao:

PUSH R1
PUSH R2
PUSH R4



MOV R4,plataforma2C
MOV R1,0
MOVB [R4],R1


;MOV R4,plataforma2C
;MOVB R1,[R4]

;MOV R4,plataforma2C

;SUB R1,2

;MOVB [R4],R1


POP R4
POP R2
POP R1
RET

mover_plataformas:

PUSH R1
PUSH R4

DI0

MOV R1,int1
MOVB R4,[R1]
CMP R4,1
JNZ fim_mover_plataformas

CALL mover_plataforma1_baixo
CALL mover_plataforma2_baixo

CALL mover_objecto1_baixo
CALL mover_objecto2_baixo

MOV R1,int1
MOV R4,0
MOVB [R1],R4


fim_mover_plataformas:



POP R4
POP R1
RET




;;---------------------------objectoss--------------------------------------------

;;;;;;;;;;;  INICIO MOVER plataforma INIMIGO 1;;;;;;;;;;;;;;;;;;;;;
mover_objecto1_baixo:

PUSH R1
PUSH R2
PUSH R4

call apagar_objecto1

MOV R2,32

MOV R4,objecto1C
MOVB R1,[R4]

continua1o:
ADD R1,1
MOVB [R4],R1

CMP R1,R2
JNZ keepo
CALL inicializa_objecto1_posicao


keepo:
CALL acender_objecto1

POP R4
POP R2
POP R1
RET
;;;;;;;;;;;; fim mover plataforma inimigo1 ;;;;;;;;

;;;;;;;;;;;  INICIO MOVER plataforma INIMIGO 2;;;;;;;;;;;;;;;;;;;;;
mover_objecto2_baixo:

PUSH R1
PUSH R2
PUSH R4

call apagar_objecto2

MOV R2,32

MOV R4,objecto2C
MOVB R1,[R4]

continuao2:
ADD R1,1
MOVB [R4],R1

CMP R1,R2
JNZ keepo2
CALL inicializa_objecto2_posicao


keepo2:
CALL acender_objecto2

POP R4
POP R2
POP R1
RET



inicializa_objecto1_posicao:

PUSH R1
PUSH R2
PUSH R4



MOV R4,objecto1C
MOV R1,0
MOVB [R4],R1


;MOV R4,objecto1C
;MOV R1,3
;MOVB [R4],R1


POP R4
POP R2
POP R1
RET


inicializa_objecto2_posicao:

PUSH R1
PUSH R2
PUSH R4



MOV R4,objecto2C
MOV R1,0
MOVB [R4],R1


;MOV R4,objecto2C
;MOVB R1,[R4]

;MOV R4,objecto2C

;SUB R1,2

;MOVB [R4],R1


POP R4
POP R2
POP R1
RET


contador_objectos_comidos:
push r0
push r1
push r2
push r3

mov r1,buffer_mortos ;faz a referência do endereço na qual é armazedo 
                     ; a quantidade de bonecos acertado pelo torpedo
movb r2,[r1] ;faz atribução do valor contido nessa referência
mov r0,10       ;atribui o valor 10 ao r0 será usado para fazer a dezena
mov r1,r2       ;atribui o valor actual do dysplay em r1 de modo não perder-lo
mov r3,r2       ;atribui o valor actual do dysplay em r1 de modo não perder-lo
div r1,r0       ;divide de modo a obter o valor da dezena
mod r3,r0       ;divide de modo a obter o valor da unidade
mov r0,display_contador
shl r1,4
or r1,r3
movB [r0],r1

pop r3
pop r2
pop r1
pop r0
ret



detecta_colisao_objecto1:
push r0
push r1
push r2
push r3
push r4
push r5

MOV R0,objecto1L
MOV R1,objecto1C

MOVB R2,[R0]
MOVB R3,[R1]

SUB R3,1
SUB R2,2

MOV R0,bonecoL
MOV R1,bonecoC

MOVB R4,[R0]
MOVB R5,[R1]
CMP R4,R2
JNZ fim_colisao_boneco1_jogador
CMP R5,R3
JLT fim_colisao_boneco1_jogador
CMP R5,R3
ADD R3,2
CMP R5,R3
JLE colidiu_com_boneco1_jogador
jmp fim_colisao_boneco1_jogador

colidiu_com_boneco1_jogador:
MOV R0,buffer_mortos
MOVB R1,[R0]
ADD R1,1
MOVB [R0],R1


MOV R0,objecto1L
MOV R1,objecto1C

MOV R5,50
MOVB [R0],R5
MOVB [R1],R5


fim_colisao_boneco1_jogador:
pop r5
pop r4
pop r3
pop r2
pop r2
pop r0
ret


;objecto2 colisao

detecta_colisao_objecto2:
push r0
push r1
push r2
push r3
push r4
push r5

MOV R0,objecto2L
MOV R1,objecto2C

MOVB R2,[R0]
MOVB R3,[R1]


SUB R2,2

MOV R0,bonecoL
MOV R1,bonecoC

MOVB R4,[R0]
MOVB R5,[R1]
CMP R4,R2
JNZ fim_colisao_boneco2_jogador
CMP R5,R3
JLT fim_colisao_boneco2_jogador
CMP R5,R3
ADD R3,2
CMP R5,R3
JLE colidiu_com_boneco2_jogador
jmp fim_colisao_boneco2_jogador

colidiu_com_boneco2_jogador:
call fim_jogo


MOV R0,objecto2L
MOV R1,objecto2C

MOV R5,50
MOVB [R0],R5
MOVB [R1],R5


fim_colisao_boneco2_jogador:
pop r5
pop r4
pop r3
pop r2
pop r2
pop r0
ret

; fim fim_jogo

fim_jogo:
push r0
push r1
push r2
DI
CALL apagar_boneco
CALL apagar_objecto1
CALL apagar_objecto2
CALL apagar_plataforma1
CALL apagar_plataforma2

call inicializa_objectos
call acender_mensagem_de_fim

game_over:

call pressionar_tecla
mov r0,memoria_armazenamento_tecla
mov r1,[r0]
mov r2,12
cmp r1,r2;quando nenhuma tecla é premida a variavel que armazenda a tecla primida contem o valor -1
jz reinicia_jogo
jmp game_over 

reinicia_jogo:
call apgar_mesagem_de_fim
call desenha_tudo

pop r2
pop r1
pop r0
ret

inicializa_objectos:
PUSH R1

PUSH R4

MOV R4,bonecoL
MOV R1,7
MOVB [R4],R1

MOV R4,bonecoC
MOV R1,24
MOVB [R4],R1

MOV R4,plataforma1L
MOV R1,11
MOVB [R4],R1

MOV R4,plataforma1C
MOV R1,19
MOVB [R4],R1

MOV R4,plataforma2L
MOV R1,20
MOVB [R4],R1

MOV R4,plataforma2C
MOV R1,8
MOVB [R4],R1

MOV R2,15
MOV R4,objecto1L
MOVB [R4],R2
MOV R2,16
MOV R4,objecto1C
MOVB [R4],R2

MOV R2,23
MOV R4,objecto2L
MOVB [R4],R2
MOV R2,5
MOV R4,objecto2C
MOVB [R4],R2


POP R4
POP R1
ret

;---escrever msg fim
escreva_mensagem_de_fim:
push r1
push r2
push r4

mov r1,8
mov r2,6
mov r4,7
DI
CALL apagar_boneco
CALL apagar_objecto1
CALL apagar_objecto2
CALL apagar_plataforma1
CALL apagar_plataforma2


call escreva_barra

braco_f1:           
                
                add r2,1
                call printf
                add r2,1
                call printf

                add r1,3
                call printf
                sub r2,1
                call printf           

i:      
                add r2,3
                mov r4,5
                call escreva_barra
                sub r1,2
                call printf

                mov r4,7
                add r2,2
                call escreva_barra
                add r1,2
                add r2,1
                call printf
                add r1,1
                call printf

                sub r1,3
                add r2,1
                call escreva_barra

pop r4
pop r2
pop r1

ret


;------------------------------

escreva_barra:
push r1
push r2
push r4

call printf

imprimindo:
                cmp r4,0
                jz fim_imprimir_barra
                call printf
                add r1,1
                sub r4,1
                JMP imprimindo

fim_imprimir_barra: 


pop r4
pop r2
pop r1

ret

acender_mensagem_de_fim:
PUSH R3
MOV R3,0
CALL escreva_mensagem_de_fim

POP R3
RET

apgar_mesagem_de_fim:
PUSH R3
MOV R3,1
CALL escreva_mensagem_de_fim

POP R3
RET
