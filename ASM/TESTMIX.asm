.MODEL small

.STACK 100h

.DATA


.CODE

Mix_8_Code:
        MOV AL,ES:[DI]
        MOV BL,[SI]
        ADD AL,ES:[BX]
        STOSB
        ADD DX,CX
        ADC SI,BP
Mix_8_CodeEnd:

Mix_8_Code2:
        MOV AX,ES:[DI]
        MOV BL,[SI]
        ADD AL,ES:[BX]
        ADD DX,CX
        ADC SI,BP
        MOV BL,[SI]
        ADD AH,ES:[BX]
        STOSW
        ADD DX,CX
        ADC SI,BP
Mix_8_Code2End:

Mix_8_Code2v2:
        MOV AX,ES:[DI]
        ADD DX,CX
        MOV BL,[SI]
        ADC SI,BP
        ADD AL,ES:[BX]
        ADD DX,CX
        MOV BL,[SI]
        ADC SI,BP
        ADD AH,ES:[BX]
        STOSW
Mix_8_Code2Endv2:

Mix_8M_Code:
        MOV BL,[SI]
        MOV AL,ES:[BX]
        STOSB
        ADD DX,CX
        ADC SI,BP
Mix_8M_CodeEnd:

Mix_8M_Code2:
        MOV BL,[SI]
        MOV AL,ES:[BX]
        ADD DX,CX
        ADC SI,BP
        MOV BL,[SI]
        MOV AH,ES:[BX]
        STOSW
        ADD DX,CX
        ADC SI,BP
Mix_8M_Code2End:

; XLAT 
    MOV AL,ES:[SI]    ; Read Sample
    ADD DX,CX
    ADC SI,BP         ; Move Sample Index
    XLATB             ; Apply the Volume (MOV AL,DS:[BX+AL]) [11]
    ADD [DI],AL       ; Add to the Buffer
    INC DI            ; Move to Next Buffer Byte  [3]
    MOV AL,ES:[SI]    ; Read Sample
    ADD DX,CX
    ADC SI,BP         ; Move Sample Index
    XLATB             ; Apply the Volume (MOV AL,DS:[BX+AL])
    ADD [DI],AL       ; Add to the Buffer
    INC DI            ; Move to Next Buffer

; XLAT and LODSB STOSW

    ADD DX,CX
    LODSB             ; Read Sample
    SEGES XLATB       ; Apply the Volume (MOV AL,DS:[BX+AL]) [11]
    ADC SI,BP         ; Move Sample Index
    ADD AL,ES:[DI]    ; Add to the Buffer
	XCHG AL,AH
    ADD DX,CX
    LODSB             ; Read Sample
    SEGES XLATB       ; Apply the Volume (MOV AL,DS:[BX+AL])
    ADC SI,BP         ; Move Sample Index
    ADD AL,ES:[DI+1]  ; Add to the Buffer
	XCHG AL,AH
    STOSW

    ADD DX,CX
    LODSB             ; Read Sample
    SEGES XLATB       ; Apply the Volume (MOV AL,DS:[BX+AL]) [11]
    ADC SI,BP         ; Move Sample Index
    ADD ES:[DI],AL    ; Add to the Buffer
    INC DI
    ADD DX,CX
    LODSB             ; Read Sample
    SEGES XLATB       ; Apply the Volume (MOV AL,DS:[BX+AL])
    ADC SI,BP         ; Move Sample Index
    ADD ES:[DI],AL    ; Add to the Buffer
    INC DI

END