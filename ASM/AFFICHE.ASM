

ScreenPos DW 0  ; Debug Display 

;AL : Value to Write

WriteByteH Proc Near
PUSH BX
PUSH ES
PUSH DI
      MOV BX,0B800h
	  MOV ES,BX
	  MOV BX,CS:ScreenPos
	  MOV DI,BX
      MOV BH,15
      CALL WriteXY_Hex8
	  MOV CS:ScreenPos,DI
	  CMP DI,3999
	  JBE NotLoopScreen
	  XOR DI,DI
NotLoopScreen:	 
	  MOV CS:ScreenPos,DI	  
POP DI
POP ES
POP BX
      RET
WriteByteH Endp

WriteWordH Proc Near
PUSH BX
PUSH ES
PUSH DI
      MOV BX,0B800h
	  MOV ES,BX
	  MOV DI,CS:ScreenPos
      MOV BH,15
      CALL WriteXY_Hex16
	  CMP DI,3999
	  JB NotLoopScreen2
	  XOR DI,DI
NotLoopScreen2:	 
	  MOV CS:ScreenPos,DI 
POP DI
POP ES
POP BX
      RET
WriteWordH Endp

WriteCh MACRO x
Local NotLoopScreen3
PUSH AX
PUSH ES
PUSH DI
      MOV AX,0B800h
	MOV ES,AX
	MOV DI,CS:ScreenPos
      MOV AH,15
	MOV AL,x
      STOSW
	CMP DI,3999
	JB NotLoopScreen3
	XOR DI,DI
NotLoopScreen3:	 
	MOV CS:ScreenPos,DI
POP DI
POP ES
POP AX
ENDM


;������������������������������������������������������������?
;?  WriteStrXY   Write a NULL Terminated String   ?
;?    Entr�e:                                                   ?
;?           SI=offset du message (ASCIIZ)                        ?
;?           DI=adresse dans la m�moire vid�o (texte)         ?
;?           AH=attribut couleur                              ?
;?    Sortie: Rien                                          ?
;?    Change                                                ?
;������������������������������������������������������������?
WriteStrXY PROC NEAR
         LODSB
wr_Boucle_aff:
         STOSW
         LODSB
         OR AL,AL
         JNZ wr_boucle_aff
         RET
WriteStrXY ENDP


;������������������������������������������������������������?
;?WriteStrXY2     Affiche un message de 2 couleurs diff�rentes ?
;?    Entr�e:                                               ?
;?           SI=offset du message (ASCIIZ, s�parateur='^')  ?
;?           DI=adresse dans la m�moire vid�o (texte)       ?
;?           AH=attribut couleur principal                  ?
;?           BH=attribut couleur secondaire                 ?
;?    Sortie: Rien                                          ?
;?    Change                                                ?
;������������������������������������������������������������?
WriteStrXY2 PROC NEAR
         LODSB
boucle_aff_car:
         CMP AL,'^'             ; caract�re de contr�le?
         JNE affiche_car        ; non
         XCHG AH,BH             ; �change les 2 attributs
         JMP SHORT saute_controle
 affiche_car:
         STOSW
 saute_controle:
         LODSB
         OR AL,AL
         JNZ boucle_aff_car
         RET
WriteStrXY2 ENDP


;������������������������������������������������������������?
;?    Affichedb   Affiche la valeur dans AX en HEXA         ?
;?    Entr�e      AX                                        ?
;?    Sortie      Rien                                      ?
;?    Change      AX,ES,SI,DI                               ?
;?    Remarque    Utilise Afficheb                          ?
;������������������������������������������������������������?
Affichedb PROC NEAR
      PUSH AX
      MOV AL,AH
      CALL AFFICHEB
      POP AX
      CALL AFFICHEB
      RET
Affichedb ENDP


;������������������������������������������������������������?
;?    Afficheb   Affiche la valeur dans AL en HEXA          ?
;?    Entr�e     AL                                         ?
;?    Sortie     Rien                                       ?
;?    Change     AX,CX,ES,SI,DI                                ?
;������������������������������������������������������������?
Afficheb PROC NEAR
      PUSH DS
      PUSH AX             ;Valeur � afficher
	  MOV CL,4
      SHR AL,CL            ;Divise par 16
      ADD AL,90h          ;Remplace
      DAA                 ;AL
      ADC AL,40h          ;par caract�re
      DAA                 ;ASCII
      MOV AH,0Eh          ;Sortie de caract�re sous BIOS
      INT 10h
      POP AX
      AND AL,0Fh          ;Reste de la division par 2^4
      ADD AL,90h          ;Remplace
      DAA                 ;AL
      ADC AL,40h          ;par caract�re
      DAA                 ;ASCII
      MOV AH,0Eh          ;Sortie de caract�re sous BIOS
      INT 10h
      POP DS
      RET                 ;Redonne la main
Afficheb ENDP


;������������������������������������������������������������?
;?    WriteXY_Hex16 Affiche la valeur dans AX en HEXA         ?
;?    Entr�e      AX                                        ?
;?                DI:Position x,y  (2*x+160*y)              ?
;?    Sortie      Rien                                      ?
;?    Change      AX,BX,DX,ES                               ?
;?    Remarque    Utilise WriteXY_Hex8                        ?
;������������������������������������������������������������?
WriteXY_Hex16 PROC NEAR
        PUSH AX
        MOV AL,AH
        CALL WriteXY_Hex8
        POP AX
        CALL WriteXY_Hex8
        RET
WriteXY_Hex16 ENDP


;������������������������������������������������������������?
;?    WriteXY_Hex8 Affiche la valeur dans AL en HEXA        ?
;?    Entr�e   AL:valeur,    BH:attribut couleur          ?
;?               DI:Position x,y  2*(x-1)+160*(y-1)         ?
;?    Sortie     Rien                                       ?
;?    Change     AX,CX                                         ?
;������������������������������������������������������������?
WriteXY_Hex8 PROC NEAR
      PUSH AX             ;Valeur � afficher
	  MOV CL,4
      SHR AL,CL            ;Divise par 16
      ADD AL,90h          ;Remplace
      DAA                 ;AL
      ADC AL,40h          ;par caract�re
      DAA                 ;ASCII

      MOV AH,BH
      STOSW

      POP AX
      AND AL,0Fh          ;Reste de la division par 2^4
      ADD AL,90h          ;Remplace
      DAA                 ;AL
      ADC AL,40h          ;par caract�re
      DAA                 ;ASCII

      MOV AH,BH
      STOSW
      RET                 ;Redonne la main
WriteXY_Hex8 ENDP


;������������������������������������������������������������?
;? BIA8        AFFICHE UN NOMBRE 8 BITS EN DECIMAL          ?
;? Entr�es:  AL=nombre � afficher                         ?
;?             BH=0: affiche un ' ' � la place du chiffre   ?
;?                   des dizaines s'il est nul (et AL<100)  ?
;?             BH=1: affiche toujours les dizaines          ?
;?             BL=attribut couleur                          ?
;?             DI=adresse dans la m�moire vid�o (texte)     ?
;? Sortie:     Rien                                         ?
;? Change:     AX,BX,CX,DI,Flags                            ?
;?                                                          ?
;? Remarques:  - Si AL>=100, le chiffre des centaines est   ?
;?                affich� en DI-1                           ?
;������������������������������������������������������������?
Bia8      PROC NEAR
          CMP AL,100
          JB inf_cent            ;nombre<100

          MOV BH,1               ;affiche toujours les dizaines si AL>=100
          XOR AH,AH
          MOV CL,100
          DIV CL                 ;AX/100 (AL=quotient, AH=reste)
          ADD AL,'0'             ;convertit en ASCII
          PUSH AX
          MOV AH,BL              ;AH=attribut
          DEC DI
          DEC DI                 ;chiffre des centaines en retrait � gauche
          STOSW                  ;affiche centaines
          POP AX
          MOV AL,AH              ;AL=reste (dizaines?nit�s)

inf_cent:
          XOR AH,AH
          MOV CL,10
          DIV CL                 ;AX/10 (AL=quotient, AH=reste)
          ADD AX,'0'*256+'0'     ;convertit en ASCII
          PUSH AX
          CMP BH,1
          JE affiche_dizaines    ;affiche toujours les dizaines

          CMP AL,'0'
          JNE affiche_dizaines
          MOV AL,' '
affiche_dizaines:
          MOV AH,BL              ;AH=attribut
          STOSW                  ;affiche dizaines (ou ' ')
          POP AX
          MOV AL,AH              ;AL=unit�s
          MOV AH,BL              ;AH=attribut
          STOSW                  ;affiche unit�s
          RET
Bia8      ENDP


;������������������������������������������������������������?
;? BIA16       AFFICHE UN NOMBRE 16 BITS (<999) EN DECIMAL  ?
;? Entr�es:    AX=nombre � afficher (999 max)               ?
;?             BH=0: affiche un ' ' � la place du chiffre   ?
;?                   des dizaines s'il est nul (et AX<100)  ?
;?             BH=1: affiche toujours les dizaines          ?
;?             BL=attribut couleur                          ?
;?             DI=adresse dans la m�moire vid�o (texte)     ?
;? Sortie:     Rien                                         ?
;? Change:     AX,BX,CX,DI,Flags                            ?
;?                                                          ?
;? Remarques: - Utilise BIA8                                ?
;������������������������������������������������������������?
Bia16     PROC NEAR
          MOV CL,100
          DIV CL                 ;AX/100 (AL=quotient, AH=reste)
          OR AL,AL               ;centaines=0 ?
          JZ affiche_espace      ;oui
          ADD AL,'0'             ;convertit en ASCII
          MOV BH,1               ;affiche toujours les dizaines si AL>=100
          JMP SHORT affiche_centaines
affiche_espace:
          MOV AL,' '             ;espace
affiche_centaines:
          PUSH AX
          MOV AH,BL              ;AH=attribut
          STOSW                  ;affiche centaines (ou ' ')
          POP AX
          MOV AL,AH              ;AL=reste (dizaines?nit�s)
          CALL BIA8
          RET
Bia16     ENDP

;������������������������������������������������������������?
;? Decimal16   AFFICHE UN NOMBRE 16 BITS EN DECIMAL          ?
;? Entr�es:  AX=nombre � afficher                       ?
;?             BH=attribut couleur                           ?
;?             DI=adresse dans la m�moire vid�o (texte) ?
;? Sortie:     Rien                                          ?
;? Change:     AX,BX,CX,DX,DI,Flags                          ?
;?                                                           ?
;������������������������������������������������������������?
WriteXY_Dec16 Proc NEAR
          PUSH DI
          PUSH AX
		  MOV AX,Seg_Video           ;ES => Segment video (Texte couleur...)
          MOV ES,AX
          POP AX
		  
		  mov CL,4                ; 5 Digit
		  mov CH,' '              ; Fill With ' ' 
          mov SI,10

          xor DX,DX
          div SI
          mov BL,'0'
          add BL,DL              ; Add '0' to the Remain
		  MOV ES:[DI],BX
		  DEC DI
		  DEC DI
LoopDec16:
          XOR DX,DX
		  div SI                  
		  CMP DL,0
		  JNE Aff_Ch16
		  CMP AX,0
		  JNE Aff_Ch16           ; Number Not Nul -> Display Digit
		  MOV BL,CH              ; Fill the left part with ' '
		  MOV ES:[DI],BX         ; Nul and AX=NUL -> Display Space
		  DEC DI
		  DEC DI
          DEC CL
          JNZ LoopDec16	
          JMP Aff_CH16End		  
Aff_Ch16:		  
          MOV BL,'0'
		  add BL,DL              ; Add '0' to the Remain
		  MOV ES:[DI],BX
		  DEC DI
		  DEC DI          
          DEC CL
		  JNZ LoopDec16
Aff_CH16End:
          POP DI
          RET
WriteXY_Dec16 EndP		  
		  
;������������������������������������������������������������?
;? Decimal16   AFFICHE UN NOMBRE 16 BITS EN DECIMAL          ?
;? Entr�es:  AX=nombre � afficher                       ?
;?             BH=attribut couleur                           ?
;?             DI=adresse dans la m�moire vid�o (texte) ?
;? Sortie:     Rien                                          ?
;? Change:     AX,BX,CX,DX,DI,Flags                          ?
;?                                                           ?
;������������������������������������������������������������?
Decimal16 PROC NEAR
          MOV AX,Seg_Video           ;ES => Segment video (Texte couleur...)
          MOV ES,AX

          XOR DX,DX
          MOV CX,10
          DIV CX
          MOV BL,AL
          ADD BL,'0'
          MOV ES:[DI],BX
          SUB DI,4

          XOR DX,DX
          MOV CX,10
          DIV CX
          MOV BL,AL
          ADD BL,'0'
          MOV ES:[DI],BX
          SUB DI,4

          XOR DX,DX
          MOV CX,10
          DIV CX
          MOV BL,AL
          ADD BL,'0'
          MOV ES:[DI],BX
          SUB DI,4

          XOR DX,DX
          MOV CX,10
          DIV CX
          MOV BL,AL
          ADD BL,'0'
          MOV ES:[DI],BX

          RET
Decimal16 ENDP

