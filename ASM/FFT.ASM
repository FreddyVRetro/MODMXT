;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Routines pour le calcul de transform‚es de Fourier en entiers 16 bits  ³
;³÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷³
;³ (c) Fabrice Couteau - 20/09/1995 - DerniŠre modification le 24/03/1996 ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
.MODEL SMALL,PASCAL
.386

.DATA

;sens
FFT_directe EQU 0000h
FFT_inverse EQU 0001h

;constantes pour FFT directe
;fenˆtres
FFT_trapeze EQU 0010h
FFT_hanning EQU 0020h
;types des donn‚es en sortie (harmoniques,module,moduleý ou "module absolu")
FFT_module  EQU 0100h
FFT_module2 EQU 0200h
FFT_moduleA EQU 0400h

complexe STRUC
 re DD 0
 im DD 0
complexe ENDS

hcos_sin STRUC
 hcos DD 0
 hsin DD 0
hcos_sin ENDS

EXTRN QuartSin: WORD            ;QuartSin: Array[1..quart_per] of Integer
periode   EQU 16384
quart_per EQU periode/4
log2_ampl EQU 14
amplitude EQU 1 SHL log2_ampl   ;16384

;fenˆtres
TRAPEZE   DW     0,  238,  938, 2060, 3538, 5287, 7205, 9179,11097,12846,14324,15446,16146,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384
          DW 16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384
          DW 16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384
          DW 16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384

HANNING   DW     0,    5,   20,   44,   79,  123,  177,  241,  315,  398,  491,  593,  705,  827,  958, 1098, 1247, 1406, 1573, 1749, 1935, 2128, 2331, 2542, 2761, 2989, 3224, 3468, 3719, 3978, 4244, 4518
          DW  4799, 5087, 5381, 5682, 5990, 6304, 6624, 6950, 7282, 7619, 7961, 8308, 8661, 9018, 9379, 9745,10114,10487,10864,11245,11628,12014,12403,12794,13188,13583,13980,14378,14778,15179,15580,15982
          DW 16384,16786,17188,17589,17990,18390,18788,19185,19580,19974,20365,20754,21140,21523,21904,22281,22654,23023,23389,23750,24107,24460,24807,25149,25486,25818,26144,26464,26778,27086,27387,27681
          DW 27969,28250,28524,28790,29049,29300,29544,29779,30007,30226,30437,30640,30833,31019,31195,31362,31521,31670,31810,31941,32063,32175,32277,32370,32453,32527,32591,32645,32689,32724,32748,32763

nbr_points           DW 0
nbr_points_complexes DW 0
taille_partition     DW 0
taille_moitie        DW 0

angle_base DW 0
angle      DW 0

temp1 complexe <>
temp2 complexe <>
w     complexe <>

log2_nbr_points_max EQU 8
nbr_points_max      EQU 1 SHL (log2_nbr_points_max-1)
tampon32 complexe nbr_points_max DUP(<>)

nbr_rep EQU 4


.CODE

;entr‚e: BX=angle  (0 ó angle ó periode-1)
;sortie: EAX=amplitude*Sinus(angle)
;modifie: BX,DL
Sin MACRO
Local positif,premier_quart,fin
 XOR DL,DL
 AND BX,periode-1
 CMP BX,periode/2
 JB positif
 AND BX,(periode/2)-1
 MOV DL,1
positif:
 CMP BX,quart_per
 JB premier_quart
 NEG BX
 ADD BX,(periode/2)-1
premier_quart:
 SHL BX,1
 MOV AX,QuartSin[BX]
 OR DL,DL
 JZ fin
 NEG AX
fin:
 CWDE           ;AX->EAX
ENDM

;entr‚e: BX=angle  (0 ó angle ó periode-1)
;sortie: EAX=amplitude*Cosinus(angle)
;modifie: BX,DL
Cos MACRO
 ADD BX,quart_per
 Sin
ENDM

;entr‚e: BX=angle  (0 ó angle ó periode-1)
;sorties: EAX=amplitude*Sinus(angle), EDX=amplitude*Cosinus(angle)
;modifie: BX
SinCos MACRO
 PUSH BX
 Sin
 POP BX
 PUSH EAX
 Cos
 MOV EDX,EAX
 POP EAX
ENDM

;entr‚e: EBX=entierò0
;sortie: AX=ûentier
;modifie: EBX,EDX
IntSqrtL MACRO
Local boucle,superieur
 PUSH CX
 XOR EDX,EDX
 XOR EAX,EAX
 MOV CL,16
boucle:
 SHL EBX,1
 RCL EDX,1
 SHL EBX,1
 RCL EDX,1
 SHL EAX,2
 CMP EDX,EAX
 JG  superieur
 SHR EAX,1
 JMP SHORT fin_boucle
superieur:
 SUB EDX,EAX
 DEC EDX
 SHR EAX,1
 INC EAX
fin_boucle:
 DEC CL
 JNZ boucle
 POP CX
ENDM


PUBLIC FFT
;***** FFT directe *****
;entr‚e: mode: directe, fenˆtre, sortie harmoniques/module/moduleý/"module absolu"
       ; tampon=ARRAY[1..2^log2_nbr_points] of INTEGER
       ;        valeurs des points r‚els
       ;     log2_nbr_points  longueur  amplitude max.
       ;             6           64          4096
       ;             7          128          2048
       ;             8          256          1024
       ; log2_nbr_points: 4..log2_nbr_points_max

;sortie:[par tranches de F hertz (F=1/T, T=dur‚e r‚elle du tampon)]
       ; tampon=ARRAY[1..(2^log2_nbr_points)/2] of {hcos,hsin: INTEGER}
       ;        amplitude des composantes d'harmoniques
       ;ou
       ; tampon=ARRAY[1..(2^log2_nbr_points)/2] of WORD
       ;        module des harmoniques = û(hcosý+hsiný)
       ;ou
       ; tampon=ARRAY[1..(2^log2_nbr_points)/2] of LONGINT
       ;        moduleý des harmoniques = hcosý+hsiný
       ;ou
       ; tampon=ARRAY[1..(2^log2_nbr_points)/2] of WORD
       ;        "module absolu" des harmoniques = ³hcos³+³hsin³
          
;***** FFT inverse *****
;entr‚e: mode: inverse
       ; tampon=ARRAY[1..(2^log2_nbr_points)/2] of {cos,sin: INTEGER}
       ;        amplitude des composantes d'harmoniques

;sortie: tampon=ARRAY[1..2^log2_nbr_points] of INTEGER
       ;        valeurs des points r‚els

FFT PROC FAR mode: WORD, tampon: DWORD, log2_nbr_points: BYTE
 PUSH DS

 MOV DX,1
 MOV CL,log2_nbr_points
 SHL DX,CL
 MOV nbr_points,DX              ;nbr_points=2^log2_nbr_points
 SHR DX,1
 MOV nbr_points_complexes,DX    ;nbr_points_complexes=nbr_points/2

 SHR DX,1                       ;DX=nbr_points/4
 LDS SI,tampon
 MOV AX,@DATA
 MOV ES,AX
 XOR BX,BX
boucle_extension32:
 i=0
 REPT nbr_rep
  MOVSX EAX,WORD PTR [SI+i]
  MOV DWORD PTR ES:tampon32[BX+(2*i)],EAX
  i=i+2
 ENDM
 ADD SI,nbr_rep*2
 ADD BX,nbr_rep*(Size complexe)/2
 DEC DX
 JNZ boucle_extension32

 PUSH ES
 POP DS

 MOV AX,mode
 TEST AX,FFT_trapeze
 JZ pas_fenetre_trapeze
 MOV BX,OFFSET Trapeze
 JMP SHORT multiplie_fenetre
pas_fenetre_trapeze:
 TEST AX,FFT_hanning
 JZ pas_fenetre_Hanning
 MOV BX,OFFSET Hanning
multiplie_fenetre:
 MOV CX,nbr_points_complexes    ;CX=nbr_points/2 (car fenˆtre sym‚trique)
 XOR SI,SI
 MOV DI,CX
 SHL DI,3                       ;DI=nbr_points*(Size complexe)/2: fin tampon32
boucle_multiplie_fenetre:
 MOVZX EAX,WORD PTR [BX]
 IMUL DWORD PTR tampon32[SI]
 SAR EAX,log2_ampl
 MOV DWORD PTR tampon32[SI],EAX ;tampon[g]=tampon[g]*fenetre[g]/amplitude
 ADD SI,(Size complexe)/2
 SUB DI,(Size complexe)/2
 MOVZX EAX,WORD PTR [BX]
 IMUL DWORD PTR tampon32[DI]
 SAR EAX,log2_ampl
 MOV DWORD PTR tampon32[DI],EAX ;tampon[d]=tampon[d]*fenetre[d]/amplitude
 ADD BX,2
 DEC CX
 JNZ boucle_multiplie_fenetre

pas_fenetre_Hanning:
 MOV DX,nbr_points_complexes
 MOV taille_partition,DX        ;taille_partition=nbr_points_complexes
 MOV DX,periode*2
 MOV CL,log2_nbr_points
 SHR DX,CL
 MOV angle_base,DX              ;angle_base=periode/nbr_points_complexes
 PUSH DX

boucle_partition:
 MOV DX,taille_partition
 SHR DX,1
 MOV taille_moitie,DX           ;taille_moitie=taille_partition/2
 MOV angle,0
 XOR CX,CX                      ;offset de 0 … taille_moitie-1

 boucle_moitie:
  MOV BX,angle
  SinCos
  MOV w.re,EDX                  ;w.re=Cos(angle)
  NEG EAX
  MOV w.im,EAX                  ;w.im=-Sin(angle)

  MOV SI,CX                     ;index_bas=offset

  boucle_index:
   MOV DI,taille_moitie
   ADD DI,SI                    ;index_haut=index_bas+taille_moitie
   SHL SI,3
   SHL DI,3

   MOV EDX,tampon32[SI].re      ;dc[index_bas].re
   MOV EAX,tampon32[DI].re      ;dc[index_haut].re
   SUB EDX,EAX
   MOV temp1.re,EDX             ;temp1.re=dc[index_bas].re-dc[index_haut].re
   ADD tampon32[SI].re,EAX      ;Inc(dc[index_bas].re,dc[index_haut].re)
   MOV EDX,tampon32[SI].im      ;dc[index_bas].im
   MOV EAX,tampon32[DI].im      ;dc[index_haut].im
   SUB EDX,EAX
   MOV temp1.im,EDX             ;temp1.im=dc[index_bas].im-dc[index_haut].im
   ADD tampon32[SI].im,EAX      ;Inc(dc[index_bas].im,dc[index_haut].im)

   MOV EAX,temp1.re
   IMUL EAX,w.re                ;EAX=temp1.re*w.re
   MOV EDX,temp1.im
   IMUL EDX,w.im                ;EDX=temp1.im*w.im
   SUB EAX,EDX
   SAR EAX,log2_ampl
   MOV tampon32[DI].re,EAX      ;dc[index_haut].re=(temp1.re*w.re-temp1.im*w.im)/amplitude

   MOV EAX,temp1.re
   IMUL EAX,w.im                ;EAX=temp1.re*w.im
   MOV EDX,temp1.im
   IMUL EDX,w.re                ;EDX=temp1.im*w.re
   ADD EAX,EDX
   SAR EAX,log2_ampl
   MOV tampon32[DI].im,EAX      ;dc[index_haut].im=(temp1.re*w.im+temp1.im*w.re)/amplitude

   SHR SI,3
   ADD SI,taille_partition      ;Inc(index_bas,taille_partition)
   CMP SI,nbr_points_complexes
   JB boucle_index              ;Until index_bas>=nbr_points_complexes

  MOV DX,angle_base
  ADD angle,DX                  ;Inc(angle,angle_base)
  INC CX
  CMP CX,taille_moitie          ;offset<=taille_moitie-1?
  JNE boucle_moitie
                                                        
 SAL angle_base,1               ;angle_base=angle_base*2
 SHR taille_partition,1         ;taille_partition=taille_partition/2
 CMP taille_partition,1
 JNE boucle_partition           ;Until taille_partition=1

 MOV CH,log2_nbr_points
 DEC CH                         ;CH=log2_nbr_points-1
 XOR SI,SI                      ;index_bas de 0 … nbr_points_complexes-1

boucle_echange:
 XOR DI,DI
 PUSH SI
 MOV CL,CH                      ;CL=log2_nbr_points-1
 inverse_bits:
  SHR SI,1
  RCL DI,1
  DEC CL
  JNZ inverse_bits              ;DI=Bitreverse(SI,log2_nbr_points-1)

 POP SI
 CMP DI,SI                      ;index_haut>index_bas?
 JNA pas_echange

 SHL SI,3
 SHL DI,3
 MOV EAX,tampon32[SI].re
 XCHG tampon32[DI].re,EAX
 MOV tampon32[SI].re,EAX        ;dc[index_bas].re <-> dc[index_haut].re
 MOV EAX,tampon32[SI].im
 XCHG tampon32[DI].im,EAX
 MOV tampon32[SI].im,EAX        ;dc[index_bas].im <-> dc[index_haut].im
 SHR SI,3

pas_echange:
 INC SI
 CMP SI,nbr_points_complexes    ;index_bas<=nbr_points_complexes-1?
 JNE boucle_echange

 MOV EAX,tampon32[0].re
 MOV temp1.re,EAX
 MOV EAX,tampon32[0].im
 MOV temp1.im,EAX               ;temp1=donnees.dc[0]
 ADD EAX,temp1.re
 SAR EAX,1
 MOV tampon32[0].hcos,EAX       ;harmo[0].hcos=(temp1.re+temp1.im)/2
 MOV EAX,temp1.re
 SUB EAX,temp1.im
 SAR EAX,1
 MOV tampon32[0].hsin,EAX       ;harmo[0].hsin=(temp1.re-temp1.im)/2

 POP DX                         ;DX=periode/nbr_points_complexes
 SHR DX,1
 NEG DX
 TEST mode,FFT_inverse
 JZ init_angle_base
 JMP fin_calculs                ;FFT inverse -> calculs termin‚s
init_angle_base:
 MOV angle_base,DX              ;angle_base=-(periode/nbr_points)
 MOV angle,DX                   ;angle=angle_base
 MOV SI,1                       ;index de 1 … (nbr_points_complexes/2)

calcule_composantes:
 MOV DI,nbr_points_complexes
 SUB DI,SI                      ;index_sym=DI=nbr_points_complexes-index
 SHL SI,3
 SHL DI,3

 MOV EAX,tampon32[SI].re
 ADD EAX,tampon32[DI].re
 MOV temp1.re,EAX               ;temp1.re=dc[index].re+dc[index_sym].re
 MOV EAX,tampon32[SI].im
 SUB EAX,tampon32[DI].im
 MOV temp1.im,EAX               ;temp1.im=dc[index].im-dc[index_sym].im
 MOV EAX,tampon32[SI].re
 SUB EAX,tampon32[DI].re
 MOV temp2.re,EAX               ;temp2.re=dc[index].re-dc[index_sym].re
 MOV EAX,tampon32[SI].im
 ADD EAX,tampon32[DI].im
 MOV temp2.im,EAX               ;temp2.im=dc[index].im+dc[index_sym].im

 MOV BX,angle
 SinCos
 MOV w.re,EAX                   ;w.re=Sin(angle)
 NEG EDX
 MOV w.im,EDX                   ;w.im=-Cos(angle)

 MOV EAX,temp2.re
 IMUL EAX,w.re                  ;EAX=temp2.re*w.re
 MOV EDX,temp2.im
 IMUL EDX,w.im                  ;EDX=temp2.im*w.im
 SUB EAX,EDX
 SAR EAX,log2_ampl
 XCHG temp2.re,EAX              ;temp2.re=(temp2.re*w.re-temp2.im*w.im)/amplitude
                                ;et r‚cupŠre l'ancien temp2.re dans EAX...
 IMUL EAX,w.im                  ;EAX=temp2.re*w.im
 MOV EDX,temp2.im
 IMUL EDX,w.re                  ;EDX=temp2.im*w.re
 ADD EAX,EDX
 SAR EAX,log2_ampl
 MOV temp2.im,EAX               ;temp2.im=(temp2.re*w.im+temp2.im*w.re)/amplitude

 MOV EAX,temp1.re
 ADD EAX,temp2.re
 SAR EAX,1
 MOV tampon32[SI].hcos,EAX      ;harmo[index].hcos=(temp1.re+temp2.re)/2
 MOV EAX,temp1.im
 ADD EAX,temp2.im
 SAR EAX,1
 NEG EAX
 MOV tampon32[SI].hsin,EAX      ;harmo[index].hsin=-(temp1.im+temp2.im)/2

 MOV EAX,temp1.re
 SUB EAX,temp2.re
 SAR EAX,1
 MOV tampon32[DI].hcos,EAX      ;harmo[index_sym].hcos=(temp1.re-temp2.re)/2
 MOV EAX,temp2.im
 SUB EAX,temp1.im
 SAR EAX,1
 MOV tampon32[DI].hsin,EAX      ;harmo[index_sym].hsin=-(temp1.im-temp2.im)/2

 MOV DX,angle_base
 ADD angle,DX                   ;Inc(angle,angle_base)
 SHR SI,3
 INC SI
 MOV DX,nbr_points_complexes
 SHR DX,1
 CMP SI,DX                      ;index<=(nbr_points_complexes/2)?
 JNE calcule_composantes

 XOR SI,SI
 MOV DX,nbr_points_complexes
 SHR DX,2                       ;DX=nbr_points_complexes/4
 MOV CL,log2_nbr_points
 DEC CL                         ;CL=log2_nbr_points-1
divise:
 i=0
 REPT nbr_rep
  SAR tampon32[SI+i].hcos,CL    ;hcos=hcos/nbr_points_complexes
  SAR tampon32[SI+i].hsin,CL    ;hsin=hsin/nbr_points_complexes
  i=i+(Size complexe)
 ENDM
 ADD SI,nbr_rep*(Size complexe)
 DEC DX
 JNZ divise

 MOV DX,nbr_points_complexes
 MOV EBX,1
 MOV ECX,-1
 XOR EDI,EDI
 XOR SI,SI
cherche_abs_1:
 MOV EAX,tampon32[SI].hcos
 CMP EAX,EBX
 JE corrige_0
 CMP EAX,ECX
 JNE pas_abs_1
 corrige_0:
 MOV tampon32[SI].hcos,EDI      ;si ³hcos³=1, met 0 (corrige impr‚cision)
 pas_abs_1:
 MOV EAX,tampon32[SI].hsin
 CMP EAX,EBX
 JE corrige_0_
 CMP EAX,ECX
 JNE pas_abs_1_
 corrige_0_:
 MOV tampon32[SI].hsin,EDI      ;si ³hsin³=1, met 0 (corrige impr‚cision)
 pas_abs_1_:
 ADD SI,(Size complexe)
 DEC DX
 JNZ cherche_abs_1

fin_calculs:
 MOV DX,nbr_points_complexes
 SHR DX,1                       ;DX=nbr_points_complexes/2
 LES DI,tampon
 XOR BX,BX
recopie_tampon:
 i=0
 REPT nbr_rep
  MOV AX,WORD PTR tampon32[BX+(2*i)]
  MOV ES:[DI+i],AX
  i=i+2
 ENDM
 ADD BX,nbr_rep*(Size complexe)/2
 ADD DI,nbr_rep*2
 DEC DX
 JNZ recopie_tampon

 MOV AX,mode
 TEST AX,FFT_inverse
 JNZ fin_FFT                    ;FFT inverse -> fin
 TEST AX,FFT_module+FFT_module2+FFT_moduleA
 JZ fin_FFT                     ;sortie=harmoniques
 LDS SI,tampon
 MOV CX,nbr_points_complexes
 MOV DI,SI
 TEST AX,FFT_module+FFT_module2
 JZ calcule_module_absolu       ;sortie="module absolu"
calcule_module:
 MOV AX,[SI]
 IMUL AX
 SAL EDX,16
 OR DX,AX
 MOV EBX,EDX
 MOV AX,[SI+2]
 IMUL AX
 SAL EDX,16
 OR DX,AX
 ADD EBX,EDX                    ;EBX=hcosý+hsiný
 TEST mode,FFT_module
 JZ module2
 IntSqrtL
 MOV [DI],AX                    ;tampon[]=û(hcosý+hsiný)
 ADD DI,2
 JMP SHORT suite
 module2:
 MOV [DI],EBX                   ;tampon[]=hcosý+hsiný
 ADD DI,4
 suite:
 ADD SI,4
 DEC CX
 JNZ calcule_module
 JMP SHORT fin_FFT

calcule_module_absolu:
 MOV AX,[SI]
 OR AX,AX
 JNS hcos_positif
 NEG AX
 hcos_positif:
 MOV BX,[SI+2]
 OR BX,BX
 JNS hsin_positif
 NEG BX
 hsin_positif:
 ADD AX,BX
 MOV [DI],AX                    ;tampon[]=³hcos³+³hsin³
 ADD SI,4
 ADD DI,2
 DEC CX
 JNZ calcule_module_absolu
          
fin_FFT:
 POP DS
 RET
FFT ENDP

END
