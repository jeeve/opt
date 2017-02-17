unit Simplexe;

{
  TSimplex : calcul du simplexe
  --------
    AjouteContrainte() : ex 5x + 3y < 10
    DefinitFonction() : fonction économique
    PrepareCalcul() : définit les paramètres d'optimisation
    Optimise() : lance le calcul du simplexe
    LitResultats() : renvoie la valeur des variables
}

interface

uses SysUtils, Matrices, Calculs;

const rowmx    = 50{72};  { colonnes des contraintes }
      colmx    = 500{112}; { lignes des matières }
      mxval    = 1.0E+35;
      zero     = 0.0;
      eqzero   = 0;

type

  TListeCoeff = array [0..colmx] of real;

  ESimplexError = class(Exception);

  TSimplex = class
  public
    constructor Create(Calc : TCalcul);
    destructor Destroy; override;
    procedure AjouteContrainte(Coeff : TListeCoeff; Signe : integer; SecondMembre : real);
    procedure DefinitFonction(Coeff : TListeCoeff);
    procedure PrepareCalcul(Sens, NbVariables, NbInferieurs, NbEgals, NbSuperieurs : integer);
    function Optimise : boolean;
    procedure LitResultats(var Fonction : real; var Coeff : TListeCoeff);
  private
    Calcul : TCalcul;
    Matrice  : TMatrice;
   { matrix   : array [0..rowmx, 0..colmx] of real; }
    Inegalite: array [1..rowmx] of integer;
    basis    : array [1..rowmx] of integer;
    basisp   : array [1..colmx] of integer;
    minmax   : real;
    error    : integer;
    ncon     : integer; {number of constraints}
    nvar     : integer; {number of variables}
    nltcon   : integer; {number of less than constraints}
    neqcon   : integer; {number of equal to constraints}
    ngtcon   : integer; {number of greater than contraints}
    trows1   : integer;
    trows2   : integer;
    tcols1   : integer;
    tcols2   : integer;
    tcols3   : integer;
    ni, ne, ns : integer; { utilisé pour vérifier le nombre de contraintes }
    procedure TrieContraintes;
    procedure PermuteContraintes(i, j : integer);
    function  getmatrix( row, col : integer ) : real;
    procedure putmatrix( row, col : integer; value : real );
    procedure initmatrix;
    procedure setbasis;
    procedure price( var xcol : integer; trow : integer; var error : integer );
    procedure leave( var xrow : integer; xcol : integer; var error : integer );
    procedure pivot( xrow, xcol : integer );
    procedure optimize( trow : integer; var error : integer);
    procedure simplex( var error : integer );
  end;

implementation

constructor TSimplex.Create(Calc : TCalcul);
begin
  Calcul := Calc;
  Matrice := nil;
{  Matrice := TMatrice.Create(rowmx, colmx); }
end;

destructor TSimplex.Destroy;
begin
{  Matrice.Destroy; }
  if Matrice <> nil then Matrice.Destroy;
end;

procedure TSimplex.PrepareCalcul(Sens, NbVariables, NbInferieurs, NbEgals, NbSuperieurs : integer);
var row, col, column : integer;
begin
  ni := 0; ne := 0; ns := 0;
  error := 0;
  nltcon := NbInferieurs;
  neqcon := NbEgals;
  ngtcon := NbSuperieurs;
  ncon   := nltcon+neqcon+ngtcon;
  minmax := -Sens;
  nvar   := NbVariables;
  trows1 := ncon + 1;
  trows2 := ncon + 2;
  tcols1 := nvar + ncon + ngtcon;
  tcols2 := tcols1 + 1;
  tcols3 := nvar + nltcon + ngtcon;
   {prepare matrix and basis}

  if Matrice <> nil then
    begin
      Matrice.Destroy;
      Matrice := nil;
    end;
  Matrice := TMatrice.Create(trows2, tcols2, zero);

   for row := 1 to trows2 do
      for col := 1 to tcols2 do
         putmatrix( row, col, zero );
   for row := 1 to ncon do
      basis[ row ] := 0;
   {prepare artificial and surplus variables}
   for row := 1 to ncon do
      if ( row <= nltcon ) then
         begin
            column := nvar + row;
            basis[ row ] := column;
            putmatrix( row, column, +1.0 );
         end
      else
         begin
            column := nvar + ngtcon + row;
            basis[ row ] := column;
            putmatrix( row, column, +1.0 );
            if ( row > nltcon + neqcon ) then
               begin
                  column := nvar - neqcon + row;
                  putmatrix( row, column, -1.0 );
                  putmatrix( trows1, column, +1.0 );
               end
         end;
  ncon := 0;
end;

procedure TSimplex.AjouteContrainte(Coeff : TListeCoeff; Signe : integer; SecondMembre : real);
var col : integer;
begin
  case Signe of
    -1 : ni := ni + 1;
     0 : ne := ne + 1;
    +1 : ns := ns + 1;
    else raise ESimplexError.Create('Signe non définit');
  end;

  ncon := ncon + 1;
  if ncon+2 > rowmx then raise ESimplexError.Create('Trop de contraintes');

  for col := 1 to nvar do
    putmatrix(ncon, col, Coeff[col]);
  Inegalite[ncon] := Signe;
  putmatrix(ncon, 0, SecondMembre);
  putmatrix(ncon, tcols2, SecondMembre);
end;

procedure TSimplex.DefinitFonction(Coeff : TListeCoeff);
var col, row : integer;
    value : real;
begin
  TrieContraintes;
  for col := 1 to nvar do
    begin
      putmatrix(0 , col, minmax * Coeff[col]);
      putmatrix(trows2, col, minmax * Coeff[col]);
    end;
  { calculate artifical variables }
  for col := 1 to nvar do
    begin
      value := zero;
      for row := nltcon+1 to ncon do
        value := value - getmatrix( row, col );
      putmatrix( trows1, col, value );
    end;
end;

function TSimplex.Optimise : boolean;
begin
  if (ni <> nltcon) or (ne <> neqcon) or (ns <> ngtcon) then
    raise ESimplexError.Create('Nombre de contraintes incorrect');
   if ( error = 0 ) then
      simplex( error );
   if ( error < 0 ) then
     raise ESimplexError.Create('Inconsistent Data - Not Run');
   if ( error = 2 ) then
     raise ESimplexError.Create('The Solution is Unbounded');
   if ( error = 3 ) then
     raise ESimplexError.Create('Le problème est insoluble');
   if (error = 0) or (error = 1) then Result := true
   else Result := false;
end;

procedure TSimplex.LitResultats(var Fonction : real; var Coeff : TListeCoeff);
var col : integer;
begin
  setbasis;
  Fonction := -minmax*getmatrix(trows2, tcols2);
  for col := 1 to nvar do
    if basisp[col] <> 0 then
      Coeff[col] := getmatrix(basisp[col], tcols2)
    else
      Coeff[col] := 0;
end;

procedure TSimplex.TrieContraintes;

  procedure QuickSort(iLo, iHi: Integer);
  var
    Lo, Hi, Mid, T: Integer;
  begin
    Lo := iLo;
    Hi := iHi;
    Mid := Inegalite[(Lo + Hi) div 2];
    repeat
      while Inegalite[Lo] < Mid do Inc(Lo);
      while Inegalite[Hi] > Mid do Dec(Hi);
      if Lo <= Hi then
      begin
        PermuteContraintes(Hi, Lo);
        T := Inegalite[Lo];
        Inegalite[Lo] := Inegalite[Hi];
        Inegalite[Hi] := T;
        Inc(Lo);
        Dec(Hi);
      end;
    until Lo > Hi;
    if Hi > iLo then QuickSort(iLo, Hi);
    if Lo < iHi then QuickSort(Lo, iHi);
  end;

begin
  QuickSort(1, ncon);
end;

procedure TSimplex.PermuteContraintes(i, j : integer);
var col : integer;
    tmp : real;
begin
 { showmessage('permute '+inttostr(i)+' '+inttostr(j)); }
  for col := 1 to nvar do
    begin
      tmp := getmatrix(i, col);
      putmatrix(i, col, getmatrix(j, col));
      putmatrix(j, col, tmp);
    end;
  tmp := getmatrix(i, 0);
  putmatrix(i, 0, getmatrix(j, 0));
  putmatrix(j, 0, tmp);
  tmp := getmatrix(i, tcols2);
  putmatrix(i, tcols2, getmatrix(j, tcols2));
  putmatrix(j, tcols2, tmp);
end;

function TSimplex.getmatrix( row, col : integer ) : real;
begin
{   getmatrix := matrix[ row, col ]; }
  Result := Matrice.GetValeur(row, col);

end;

procedure TSimplex.putmatrix( row, col : integer; value : real );
begin
{   matrix[ row, col ] := value; }
  Matrice.PutValeur(row, col, value);
end;

procedure TSimplex.initmatrix;
var row, col : integer;
begin
   for row := 0 to rowmx do
      for col := 0 to colmx do
         putmatrix( row, col, zero );
end;

procedure TSimplex.setbasis;
var row, col : integer;
    flag     : boolean;
begin
   for col := 1 to nvar{+ncon} do
      begin
         flag := false;
         row := 1;
         repeat
            if ( basis[ row ] = col ) then
               flag := true
            else
               row := row + 1;
         until ( (flag) or (row > ncon) );
         if (flag) then
            basisp[ col ] := row
         else
            basisp[ col ] := 0;
      end;
end;

procedure TSimplex.price( var xcol : integer; trow : integer; var error : integer );
var quant, val : real;
    col        : integer;
begin
   quant := -eqzero;
   for col := 1 to tcols3 do
      begin
         val := getmatrix( trow, col );
         if ( val < quant ) then
            begin
               xcol := col;
               quant := val;
            end;
      end;
   error := 0;
   if ( quant = -eqzero ) then
      error := 1;
end;

procedure TSimplex.leave( var xrow : integer; xcol : integer; var error : integer );
var quant, val : real;
    row        : integer;
begin
   quant := mxval;
   for row := 1 to ncon do
      begin
         val := getmatrix( row, xcol );
         if ( val > eqzero ) then
            begin
               try
                 val := getmatrix( row, tcols2 ) / val;
               except
                 on EMathError do val := mxval;
               end;
               if ( val < quant ) then
                  begin
                     xrow := row;
                     quant := val;
                  end;
            end;
      end;
   error := 0;
   if ( quant = mxval ) then
      error := 2;
end;

procedure TSimplex.pivot( xrow, xcol : integer );
var value, val, vl : real;
    row, col       : integer;
begin
   Calcul.TesteStop;
   value := getmatrix( xrow, xcol );
   for row := 1 to trows2 do
      if ( row <> xrow ) then
         begin
            vl := getmatrix( row, xcol );
            for col := 1 to tcols2 do
               if ( col <> xcol ) then
                  begin
                    val := getmatrix( row, col ) - vl * getmatrix( xrow, col ) / value;
                     if ( abs( val ) < eqzero ) then
                        val := zero;
                     putmatrix( row, col, val );
                  end;
         end;
   for col := 1 to tcols2 do
      putmatrix( xrow, col, getmatrix( xrow, col ) / value );
   for row := 1 to trows2 do
      putmatrix( row, xcol, zero );
   putmatrix( xrow, xcol, 1.0);
   basis[ xrow ] := xcol;
end;

procedure TSimplex.optimize( trow : integer; var error : integer);
var xrow, xcol : integer;
begin
   repeat
      price( xcol, trow, error );
      if ( error = 0 ) then
         leave( xrow, xcol, error );
      if ( error = 0 ) then
         pivot( xrow, xcol );
   until ( error <> 0 )
end;

procedure TSimplex.simplex( var error : integer );
var row, col : integer;
    flag     : boolean;
begin
   if ( ncon <> nltcon ) then
      begin
         optimize( trows1, error );
         if ( error > 1 ) then exit;
         error := 3;
         for row := 1 to ncon do
            if ( basis[ row ] > tcols3 ) then
               begin
                  if ( getmatrix( row, tcols2 ) > eqzero ) then exit;
                  flag := false;
                  col := 1;
                  repeat
                     if ( abs( getmatrix( row, col ) ) >= eqzero ) then
                        begin
                           pivot( row, col );
                           flag := true;
                        end;
                     col := col + 1;
                  until ( (flag) or (col > tcols3) );
               end;
      end;
   error := 0;
   optimize( trows2, error );
end;

end.
