{ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»}
{º                      --==ðð FICH_GRP.PAS ðð==--                      º}
{º                                                                      º}
{º Unit‚ pour g‚rer les fichiers group‚s en un seul avec GROUPF         º}
{º                                                                      º}
{º   IMPORTANT: - un seul fichier "groupe" peut ˆtre ouvert … la fois ! º}
{º              - accŠs aux fichiers en LECTURE seule !                 º}
{º                                                                      º}
{º Syntaxe compatible avec l'unit‚ Fichiers; ajouter dans le programme: º}
{º                                                                      º}
{º      DefinitFichierGroupe(chemin);                                   º}
{º      ...                                                             º}
{º      FermeFichierGroupe;                                             º}
{º                                                                      º}
{º AUTEUR: Fabrice Couteau                                              º}
{ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶}
{º Compatibilit‚: 8088          D‚but d'‚critureúúúúúúúúúúúúúúú??/01/95 º}
{º                              DerniŠres modificationsúúúúúúúú03/09/95 º}
{ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼}

UNIT Fich_Grp;

{$A+,G-,Q-,R-,S-}

INTERFACE

{$I Types}

CONST {mode d'accŠs unique}
      lecture=$90;

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


TYPE Fichier=Object
              Taille: Longint;
              PROCEDURE Ouvre(mode: Byte; nom_fichier: String12);
              PROCEDURE Ferme;
              PROCEDURE PlacePointeur  (position: Longint);
              PROCEDURE DeplacePointeur(distance: Longint);
              PROCEDURE Lit   (Var buffer; nombre: Word);
              PROCEDURE LitPos(position: Longint; Var buffer; nombre: Word);
             Private
              offset: Longint;
             End;


CONST f_erreur: Word=f_ok; {variable … tester aprŠs chaque op‚ration fichier
                            sauf: Ferme, (D‚)PlacePointeur, Taille}

{==========================================================}

PROCEDURE DefinitFichierGroupe(chemin: String80);
PROCEDURE FermeFichierGroupe;

{==========================================================}

IMPLEMENTATION

USES Util;

VAR handle_groupe: Word;
    nom_fichier_groupe: String80;

{==========================================================}

PROCEDURE DefinitFichierGroupe(chemin: String80);
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
  ADD SI,AX              {DS:SI -> caractŠre suivant le dernier}
  MOV BYTE PTR DS:[SI],0 {convertit chemin en ASCIIZ}
  MOV AH,3Dh
  MOV AL,lecture
  INT 21h                {ouvre le fichier}
  POP DS
  MOV f_erreur,f_ok
  JNC @fin               {pas d'erreur}
  MOV f_erreur,AX
  XOR AX,AX
 @fin:
  MOV handle_,AX
 End;
 handle_groupe:=handle_;
 If f_erreur=f_ok Then nom_fichier_groupe:=chemin
End; {DefinitFichierGroupe}

{----------------------------------------------------------}

PROCEDURE FermeFichierGroupe; Assembler;
ASM
 MOV AH,3Eh
 MOV BX,handle_groupe
 INT 21h
End; {FermeFichierGroupe}

{----------------------------------------------------------}

PROCEDURE Fichier.Ouvre(mode: Byte; nom_fichier: String12);

Type T_entete=Record
               Nom: String12;
               offset, longueur: Longint
              End;

Var i,nbr_fichiers_groupes: Word;
    elem_entete: T_entete;


Procedure LitFichierGroupe(Var buffer; nombre: Word); Assembler;
ASM
 PUSH DS
 MOV AH,3Fh
 MOV BX,handle_groupe
 MOV CX,nombre
 LDS DX,buffer
 INT 21h
 POP DS
 MOV f_erreur,f_ok
 JNC @fin               {pas d'erreur}
 MOV f_erreur,AX
@fin:
End; {LitFichierGroupe}


Begin {Fichier.Ouvre}
 nom_fichier:=Maj(nom_fichier);
 ASM
  MOV AX,4200h
  MOV BX,handle_groupe
  XOR CX,CX
  XOR DX,DX
  INT 21h    {d‚but du fichier group‚}
 End;
 LitFichierGroupe(nbr_fichiers_groupes,2);
 If f_erreur<>f_ok Then Exit;

 For i:=1 to nbr_fichiers_groupes do
  Begin
   LitFichierGroupe(elem_entete,Sizeof(T_entete));
   If Maj(elem_entete.Nom)=nom_fichier Then
    Begin
     offset:=elem_entete.offset;
     Taille:=elem_entete.longueur;
     Fichier.PlacePointeur(0);  {d‚but du fichier}
     f_erreur:=f_ok;
     Exit
    End
  End;
 f_erreur:=f_err_fich_intr  {nom_fichier n'est pas dans l'entˆte}
End; {Fichier.Ouvre}

{----------------------------------------------------------}

PROCEDURE Fichier.Ferme;
Begin
 {ne fait rien !!}
End; {Fichier.Ferme}

{----------------------------------------------------------}

PROCEDURE Fichier.PlacePointeur(position: Longint);
Var position_: Longint;
Begin
 position_:=offset+position;
 ASM
  MOV AX,4200h           {position par rapport au d‚but du fichier}
  MOV BX,handle_groupe
  LES DX,position_       {DX=mot faible}
  MOV CX,ES              {CX=mot fort}
  INT 21h
 End
End; {Fichier.PlacePointeur}

{----------------------------------------------------------}

PROCEDURE Fichier.DeplacePointeur(distance: Longint); Assembler;
ASM
 MOV AX,4201h           {distance par rapport … la position courante}
 MOV BX,handle_groupe
 LES DX,distance        {DX=mot faible}
 MOV CX,ES              {CX=mot fort}
 INT 21h
End; {Fichier.DeplacePointeur}

{----------------------------------------------------------}

PROCEDURE Fichier.Lit(Var buffer; nombre: Word); Assembler;
ASM
 PUSH DS
 MOV AH,3Fh
 MOV BX,handle_groupe
 MOV CX,nombre
 LDS DX,buffer
 INT 21h
 POP DS
 MOV f_erreur,f_ok
 JNC @fin               {pas d'erreur}
 MOV f_erreur,AX
@fin:
End; {Fichier.Lit}

{----------------------------------------------------------}

PROCEDURE Fichier.LitPos(position: Longint; Var buffer; nombre: Word);
Begin
 Fichier.PlacePointeur(position);
 Fichier.Lit(buffer,nombre)
End; {Fichier.LitPos}

{==========================================================}

END.
