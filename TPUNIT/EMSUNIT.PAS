UNIT EMSUnit;

{$A+,Q-,R-,S-}

INTERFACE

USES DOS;

const EMS_INT   = $67;        { Nø d'interruption pour l'accŠs … l'EMM }
      EMS_ERR   = -1;                    { Est renvoy‚ en cas d'erreur }
      W_EMS_ERR = $FFFF;                { Code d'erreur en format WORD }

var   EmmEC:byte;             { Ici sont plac‚s les codes d'erreur EMM }

function EmsVersion : integer;
function EmsSaveMap( Handle : integer ) : boolean;

IMPLEMENTATION


{**********************************************************************}
{* EmsVersion: D‚termine le num‚ro de version de l'EMM                *}
{* Entr‚e : Aucune                                                    *}
{* Sortie : EMS_ERR en cas d'erreur, sinon le num‚ro de version.      *}
{*          11 signifie 1.1, 40 signifie 4.0 etc.                     *}
{**********************************************************************}

function EmsVersion : integer;

var Regs : Registers;   { Registres processeur pour appel interruption }

begin
  Regs.ah := $46;                    { Nø fct.: D‚terminer version EMM }
  Intr(EMS_INT, Regs);                                   { Appeler EMM }
  if (Regs.ah <>0 ) then               { Une erreur est-elle apparue ? }
    begin                                                        { Oui }
      EmmEC := Regs.ah;                      { Ranger le code d'erreur }
      EmsVersion := EMS_ERR;                       { Afficher l'erreur }
    end
  else   { Pas d'erreur, calculer num‚ro de version d'aprŠs nombre BCD }
   EmsVersion := (Regs.al and 15) + (Regs.al shr 4) * 10;
end;

END.
