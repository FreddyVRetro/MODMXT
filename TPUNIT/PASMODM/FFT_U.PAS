{ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป}
{บ                        --==๐๐ FFT_U.PAS ๐๐==--                       บ}
{บ                                                                      บ}
{บ Unit pour calculer les transformes de Fourier directes/inverses en บ}
{บ entiers 16 bits (nombre maximal de points=nbr_points_max).           บ}
{บ                                                                      บ}
{บ AUTEUR: Fabrice Couteau                                              บ}
{วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ}
{บ Compatibilit: 386           Dbut d'criture๚๚๚๚๚๚๚๚๚๚๚๚๚๚๚01/10/95 บ}
{บ                              Dernires modifications๚๚๚๚๚๚๚๚13/02/97 บ}
{ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ}

{si SIN_CODE est dfinie, la table de sinus (QuartSin, taille: 8ko)
 est incluse dans le segment CODE,
 sinon elle est incluse dans le segment DATA}

{$UNDEF SIN_CODE}

UNIT FFT_U;

{$A+,G+,Q-,R-,S-}

INTERFACE

CONST log2_nbr_points_max=8; {=n}
      nbr_points_max=1 SHL log2_nbr_points_max; {=2^n}

      {sens}
      FFT_directe=$0000;
      FFT_inverse=$0001;

      {constantes pour FFT directe}
        FFT_points =$0000; {entre: points rels (toujours!)}

        {fentres}
        FFT_rect   =$0000;
        FFT_trapeze=$0010;
        FFT_hanning=$0020;

        {type des donnes en sortie (harmoniques,module,moduleý ou "module absolu")}
        FFT_harmo  =$0000;
        FFT_module =$0100;
        FFT_module2=$0200;
        FFT_moduleA=$0400;

      {FFT inverse: entre=harmoniques, sortie=points rels (toujours!)}


TYPE  harmo=Record hcos,hsin: Integer End;

      T_FFT_taille=0..nbr_points_max-1;
      T_FFT_moitie=0..(nbr_points_max SHR 1)-1;

      T_FFT_points =Array[T_FFT_taille] of Integer; {points rels}
      T_FFT_harmo  =Array[T_FFT_moitie] of harmo;   {hcos,hsin}
      T_FFT_module =Array[T_FFT_moitie] of Word;    {๛(hcosý+hsiný)}
      T_FFT_module2=Array[T_FFT_moitie] of Longint; {hcosý+hsiný}
      T_FFT_moduleA=T_FFT_module;                   {ณhcosณ+ณhsinณ}

      T_FFT=Record Case Byte of
             FFT_points :(points :T_FFT_points);
             FFT_harmo  :(harmo  :T_FFT_harmo);
             FFT_module :(module :T_FFT_module);
             FFT_module2:(module2:T_FFT_module2);
             FFT_moduleA:(moduleA:T_FFT_moduleA)
            End;

{==========================================================}

PROCEDURE FFT(mode: Word; Var tampon: T_FFT; log2_nbr_points: Byte);

{==========================================================}

IMPLEMENTATION

{$IFNDEF SIN_CODE}
{$I QuartSin.inc}
{$ENDIF}

PROCEDURE FFT(mode: Word; Var tampon: T_FFT; log2_nbr_points: Byte); External;
{$L FFT}

{==========================================================}

END.