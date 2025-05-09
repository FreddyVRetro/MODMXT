{����������������������������������������������������������������������ͻ}
{�                      --==�� FICHIERS.PAS ��==--                      �}
{�                                                                      �}
{� Unit� pour g�rer les fichiers DOS                                    �}
{�                                                                      �}
{� AUTEUR: Fabrice Couteau                                              �}
{����������������������������������������������������������������������Ķ}
{� Compatibilit�: 8088          D�but d'�criture���������������??/12/93 �}
{�                              Derni�res modifications��������03/09/95 �}
{����������������������������������������������������������������������ͼ}

UNIT Fichiers;

{$A+,G-,Q-,R-,S-}

INTERFACE

{$I Types}

CONST {modes d'acc�s}
      lecture   = $00;
      ecriture  = $01;
      lectecrit = $02;

      {mode de cr�ation}
      teste_existe = True;

      {codes d'erreur}
      f_ok            =  0;
      f_err_fich_intr =  2;
      f_err_ch_intr   =  3;
      f_err_trop_fich =  4;
      f_err_acces_ref =  5;
      f_err_handle    =  6;
      f_err_lecteur   = 15;
      f_err_plus_fich = 18;
      f_err_existe    = 80;
      f_err_protect   =150;
      f_err_pas_pret  =152;
      f_err_CRC       =154;
      f_err_donnees   =156;
      f_err_media     =157;
      f_err_secteur   =158;


TYPE  Fichier=Object
               PROCEDURE Ouvre(mode_acces: Byte; chemin: String80);
               PROCEDURE Cree(teste_existe_: Boolean; chemin: String80);
               PROCEDURE Ferme;
               PROCEDURE PlacePointeur  (position: Longint);
               PROCEDURE DeplacePointeur(distance: Longint);
               PROCEDURE Lit  (var buffer; nombre: Word); {  Var is a Trick to pass a pointer and support many types }
               PROCEDURE Ecrit(var buffer; nombre: Word);
               PROCEDURE LitPos  (position: Longint; var buffer; nombre: Word);
               PROCEDURE LitPosL (position: Longint; buffer : Pointer; nombre: LongInt);
               PROCEDURE EcritPos(position: Longint; var buffer; nombre: Word);
               FUNCTION  Taille: Longint;
               FUNCTION  GetHandle: Word;
              Private
               handle: Word;
              End;


CONST f_erreur: Word=f_ok; {variable � tester apr�s chaque op�ration fichier
                            sauf: Ferme, (D�)PlacePointeur, Taille}

{==========================================================}

PROCEDURE EffaceFichier(chemin: String80);
PROCEDURE EcraseFichier(chemin: String80);
FUNCTION  FichierExiste(chemin: String80): Boolean;

{==========================================================}

IMPLEMENTATION

{==========================================================}

PROCEDURE Fichier.Ouvre(mode_acces: Byte; chemin: String80);
{ouvre un fichier existant en lecture, �criture ou les deux
 Remarque: le pointeur de fichier est plac� sur le premier octet}
Var handle_: Word;
    ptr_chemin: Pointer;
Begin
 ptr_chemin:=@chemin;
 ASM
  PUSH DS
  CLD
  LDS SI,ptr_chemin
  XOR AH,AH
  LODSB                  {AX=longueur chemin}
  MOV DX,SI              {DS:DX -> chemin[1]}
  ADD SI,AX              {DS:SI -> caract�re suivant le dernier}
  MOV BYTE PTR DS:[SI],0 {convertit chemin en ASCIIZ}
  MOV AH,3Dh
  MOV AL,mode_acces
  INT 21h                {ouvre le fichier}
  POP DS
  MOV f_erreur,f_ok
  JNC @fin               {pas d'erreur}
  MOV f_erreur,AX
  XOR AX,AX
 @fin:
  MOV handle_,AX
 End;
 handle:=handle_
End; {Fichier.Ouvre}

{----------------------------------------------------------}

PROCEDURE Fichier.Cree(teste_existe_: Boolean; chemin: String80);
{cree un nouveau fichier
 si teste_existe_=TRUE: provoque une erreur 80 si le fichier existe deja
                        sinon ecrase l'ancien fichier
 Remarque: le pointeur de fichier est place sur le premier octet}
Var handle_: Word;
    ptr_chemin: Pointer;
Begin
 ptr_chemin:=@chemin;
 ASM
  PUSH DS
  CLD
  LDS SI,ptr_chemin
  XOR AH,AH
  LODSB                  {AX=longueur chemin}
  MOV DX,SI              {DS:DX -> chemin[1]}
  ADD SI,AX              {DS:SI -> caractere suivant le dernier}
  MOV BYTE PTR DS:[SI],0 {convertit chemin en ASCIIZ}
  MOV AH,5Bh
  CMP teste_existe_,True
  JE @suite
  MOV AH,3Ch
 @suite:
  XOR CX,CX
  INT 21h                {cree le fichier}
  POP DS
  MOV f_erreur,f_ok
  JNC @fin               {pas d'erreur}
  MOV f_erreur,AX
  XOR AX,AX
 @fin:
  MOV handle_,AX
 End;
 handle:=handle_
End; {Fichier.Cree}

{----------------------------------------------------------}

PROCEDURE Fichier.Ferme;
{ferme un fichier prealablement ouvert}
Var handle_: Word;
Begin
 handle_:=handle;
 ASM
  MOV AH,3Eh
  MOV BX,handle_
  INT 21h
 End
End; {Fichier.Ferme}

{----------------------------------------------------------}

PROCEDURE Fichier.PlacePointeur(position: Longint);
{positionne le pointeur de fichier � l'offset voulu (0 -> premier octet)
 (position � 0)}
Var handle_: Word;
Begin
 handle_:=handle;
 ASM
  MOV AX,4200h           {position par rapport au d�but du fichier}
  MOV BX,handle_
  LES DX,position        {DX=mot faible}
  MOV CX,ES              {CX=mot fort}
  INT 21h
 End
End; {Fichier.PlacePointeur}

{----------------------------------------------------------}

PROCEDURE Fichier.DeplacePointeur(distance: Longint);
{d�place le pointeur de fichier (en amont ou en aval)}
Var handle_: Word;
Begin
 handle_:=handle;
 ASM
  MOV AX,4201h           {distance par rapport a la position courante}
  MOV BX,handle_
  LES DX,distance        {DX=mot faible}
  MOV CX,ES              {CX=mot fort}
  INT 21h
 End
End; {Fichier.DeplacePointeur}

{----------------------------------------------------------}

PROCEDURE Fichier.Lit(var buffer; nombre: Word);
{lit 'nombre' octets depuis la position courante du pointeur de fichier,
 et les place � l'adresse de 'buffer'}
Var handle_: Word;
Begin
 handle_:=handle;
 ASM
  PUSH DS
  MOV AH,3Fh
  MOV BX,handle_
  MOV CX,nombre
  LDS DX,buffer
  INT 21h
  POP DS
  MOV f_erreur,f_ok
  JNC @fin               {pas d'erreur}
  MOV f_erreur,AX
 @fin:
 End
End; {Fichier.Lit}

{----------------------------------------------------------}

PROCEDURE Fichier.Ecrit(var buffer; nombre: Word);
{ecrit 'nombre' octets de 'buffer' � la position courante du pointeur de fichier}
Var handle_: Word;
Begin
 handle_:=handle;
 ASM
  PUSH DS
  MOV AH,40h
  MOV BX,handle_
  MOV CX,nombre
  LDS DX,buffer
  INT 21h
  POP DS
  MOV f_erreur,f_ok
  JNC @fin               {pas d'erreur}
  MOV f_erreur,AX
 @fin:
 End
End; {Fichier.Ecrit}

{----------------------------------------------------------}

PROCEDURE Fichier.LitPos(position: Longint; var buffer; nombre: Word);
{lit 'nombre' octets depuis 'position' , et les place a l'adresse de 'buffer'}
Begin
 Fichier.PlacePointeur(position); Fichier.Lit(buffer,nombre)
End; {Fichier.LitPos}

{ Buffer Segment must be 0 }
PROCEDURE Fichier.LitPosL  (position: Longint; buffer: Pointer; nombre: Longint);
{lit 'nombre' octets depuis 'position' , et les place a l'adresse de 'buffer'}
Var
    LoopNb,i: Byte;
    Remain,Size  : Word;
    PtrTmp:Pointer;
Begin
 LoopNb:=(nombre SHR 15)+1;
 Remain:=(nombre AND $7FFF); { Read Block of 32Kb }
 Fichier.PlacePointeur(position);
 for i:=1 to LoopNb do
    Begin
     if i=LoopNb then Size:=Remain else Size:=$8000;
     PtrTmp:=Ptr(Seg(buffer^)+$800*(i-1),0);
     Fichier.Lit(PtrTmp^,size)
    End;
End; {Fichier.LitPos}

{----------------------------------------------------------}

PROCEDURE Fichier.EcritPos(position: Longint; var buffer; nombre: Word);
{ecrit 'nombre' octets de 'buffer' a la position indiquee du pointeur de fichier}
Begin
 Fichier.PlacePointeur(position); Fichier.Ecrit(buffer,nombre)
End; {Fichier.EcritPos}

{----------------------------------------------------------}

FUNCTION Fichier.Taille: Longint;
{renvoie la taille du fichier en octets
 IMPORTANT: d�place le pointeur de fichier sur le dernier octet!}
Var handle_,th,tb: Word;
Begin
 handle_:=handle;
 ASM
  MOV AX,4202h   {distance par rapport � la fin du fichier}
  MOV BX,handle_
  XOR CX,CX
  XOR DX,DX
  INT 21h        {Taille=[DX,AX]}
  MOV th,DX
  MOV tb,AX
 End;
 Taille:=Longint(th) SHL 16+tb
End; {Fichier.Taille}

{----------------------------------------------------------}

FUNCTION Fichier.GetHandle: Word;
{renvoie le handle du fichier}
Begin
 GetHandle:=handle
End; {Fichier.GetHandle}

{----------------------------------------------------------}

PROCEDURE EffaceFichier(chemin: String80); Assembler;
{efface un fichier sur disque - r�cup�rable avec Undelete}
ASM
 PUSH DS
 CLD
 LDS SI,chemin
 XOR AH,AH
 LODSB                  {AX=longueur chemin}
 MOV DX,SI              {DS:DX -> chemin[1]}
 ADD SI,AX              {DS:SI -> caract�re suivant le dernier}
 MOV BYTE PTR DS:[SI],0 {convertit chemin en ASCIIZ}
 MOV AH,41h
 INT 21h                {supprime le fichier}
 POP DS
 MOV f_erreur,f_ok
 JNC @fin               {pas d'erreur}
 MOV f_erreur,AX
@fin:
End; {EffaceFichier}

{----------------------------------------------------------}

PROCEDURE EcraseFichier(chemin: String80);
{efface un fichier sur disque - IRRECUPERABLE avec Undelete}
Var f: Fichier;
Begin
 With f do
  Begin
   Cree(Not(teste_existe),chemin);
   If f_erreur<>f_ok Then Exit;
   Ferme;                 {cr�e un fichier vide portant le m�me nom}
   EffaceFichier(chemin)
  End
End; {EcraseFichier}

{----------------------------------------------------------}

FUNCTION FichierExiste(chemin: String80): Boolean;
{renvoie TRUE si le fichier existe sur le disque
 Remarque: ne teste pas les erreurs d'acc�s}
Var f: Fichier;
Begin
 With f do Begin Ouvre(lecture,chemin); Ferme End;
 FichierExiste:=(f_erreur=f_ok)
End; {FichierExiste}

{==========================================================}

END.
