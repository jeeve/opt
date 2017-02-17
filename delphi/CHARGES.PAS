unit Charges;

{
  TCharge : calcul de charge à partir de l'alliage visé
  -------   et de la liste des matières premières
    PrepareCalcul() : lance le calcul du simplexe
    CalculOK : vrai si l'optimisation est réussie
    CalculePertes() : pertes au feu en fonction du tonnage entré
    CalculeResultats() : composition et cout de la charge
    GetTonnage() : renvoie le tonnage calculé d'une matière donnée
    Composition : composition de l'alliage calculé
    Affiche() : affiche l'ensemble des résultats dans des grilles
    VerifieStocks() : renvoie faux si les stocks sont insufisants
    FixeContraintesStock() : ajoute des contraintes pour palier le
                             problème des stocks
}

interface

uses Compositions, Alliages, Matieres, Simplexe, Grids, Calculs;

type

  TTypeCharge = (tcCalculCharge, tcCorrectionBain, tcCalculMelange);

  TCharge = class
  protected
    Simplex : TSimplex;
    FNbCharges : integer;
    Q, V : TListeCoeff;
    FPrecision : real;
    FCout, FMiseAuMille, FPertesAuFeu, FChargeSortie : real;
    FChargeEntree, FR0, FTotalPourcentEntre, FTotalPourcentSorti : real;
    FCalculOK : boolean;
    IndiceBain : integer;
    procedure RechercheIndiceBain;
    procedure ContraintesMiniMaxi; virtual;
    procedure ContraintesPoids; virtual;
    procedure ContraintesMatieres; virtual;
    procedure CalculeComposition; virtual;
    procedure VerifieComposition;
    procedure CalculeCout;
  public
    ListeMatieres : TListeMatieres;
    AlliageVise : TAlliageVise;
    Composition : TAlliage; { analyse de l'alliage calculé }
    TypeCharge : TTypeCharge;
    CodeFusion : integer; // appartient a la fusion x
    RepereFusion : string;
    property Precision : real read FPrecision write FPrecision;
    property R0 : real read FR0 write FR0; { rendement en % sur élément non cité }
    property NbCharges : integer read FNbCharges; { nb de matières utilisées }
    property ChargeEntree : real read FChargeEntree; { tonnage total des matières premières avant fusion }
    property ChargeSortie : real read FChargeSortie; { tonnage de l'alliage après fusion }
    property TotalPourcentEntre : real read FTotalPourcentEntre;
    property TotalPourcentSorti : real read FTotalPourcentSorti;
    property CalculOK : boolean read FCalculOK; { indique si le calcul a abouti }
    property Cout : real read FCout; { cout de la fusion en F/t }
    property MiseAuMille : real read FMiseAuMille;
    property PertesAuFeu : real read FPertesAuFeu;
    constructor Create(Calcul : TCalcul; RendementEltNonCite : real); virtual;
    destructor Destroy; override;
    procedure Assign(Charge : TCharge);
    procedure Init; virtual;
    procedure PrepareCalcul; { calcul du simplex }
    procedure CalculePertes(TonnageEntre : real);
    procedure CalculeResultats;
    function GetNomMatiere(NumMatiere : integer) : string;
    function GetPourcentEntre(NumMatiere : integer): real; { retourne le pourcentage de la charge entree d'une matiere }
    function GetPourcentSorti(NumMatiere : integer): real; { retourne le pourcentage de la charge sortie d'une matiere }
    function GetTonnage(NumMatiere : integer) :real; { retourne le tonnage d'entree d'une matiere }
    procedure Affiche(GrilleCharge, GrilleTotal, GrilleComposition : TStringGrid; GrilleValeurs : TStringGrid = nil);
    function VerifieStocks : boolean;
    procedure FixeContraintesStock;
    function GetPrix(NumMatiere : integer) : real;
    function Bain : TMatiere;
    procedure Imprimer(Titre : string);
  end;

implementation

uses SysUtils, Donnees, dAdministration, Constantes, dBases, fFusion, rFusion, FormatNombres, Math, Forms;

constructor TCharge.Create(Calcul : TCalcul; RendementEltNonCite : real);
begin
  AlliageVise := TAlliageVise.Create;
  ListeMatieres := TListeMatieres.Create;
  ListeMatieres.Analyse := AlliageVise;
  Simplex := TSimplex.Create(Calcul);
  Composition := TComposition.Create;
  R0 := RendementEltNonCite;
  FPrecision := DataAdministration.PrecisionCharge; { TODO : précision variable : rajouté dans la version 2 }
  FCalculOK := false;
  FNbCharges := 0;
  Composition.Init;
  TypeCharge := tcCalculCharge;
  CodeFusion := 0;
  IndiceBain := -1;
end;

destructor TCharge.Destroy;
begin
  AlliageVise.Destroy;
  ListeMatieres.Destroy;
  Simplex.Destroy;
  Composition.Destroy;
end;

procedure TCharge.Init;
begin
  FCalculOK := false;
  FNbCharges := 0;
  Composition.Init;
end;

procedure TCharge.PrepareCalcul;
var NbMatieres, i,
    Inf1, Inf2, Egal1, Egal2, Sup1, Sup2 : integer;
    Coeff : TListeCoeff;
begin
  Init;
  RechercheIndiceBain;
  NbMatieres := ListeMatieres.NbMatieres;

  ListeMatieres.GetNbContraintes(Inf1, Egal1, Sup1);
  AlliageVise.GetNbContraintes(Inf2, Egal2, Sup2);
  Simplex.PrepareCalcul(-1, NbMatieres, Inf1+Inf2, 1+Egal1+Egal2, Sup1+Sup2);

  ContraintesMiniMaxi;
  ContraintesPoids;
  ContraintesMatieres;

  for i := 1 to NbMatieres do { fonction des couts à minimiser }
    Coeff[i] := ListeMatieres.GetMatiere(i).Prix;
  Simplex.DefinitFonction(Coeff);

  if Simplex.Optimise then
    begin
      Simplex.LitResultats(FCout, Q);
      FNbCharges := NbMatieres;
      FCalculOK := true;
    end;
end;

procedure TCharge.ContraintesMiniMaxi;
var i, j : integer;
    Coeff : TListeCoeff;
    Mini, Maxi : real;
begin
  for i := 1 to AlliageVise.NbElements do
    begin
      for j := 1 to ListeMatieres.NbMatieres do
        with ListeMatieres.GetMatiere(j).Composition do
          Coeff[j] := GetTeneur(i)*GetRendement(i)/100;
      Mini := AlliageVise.GetTeneurMini(i);
      Maxi := AlliageVise.GetTeneurMaxi(i);
      if Mini <> Maxi then
        begin
          Simplex.AjouteContrainte(Coeff, +1, Mini);
          Simplex.AjouteContrainte(Coeff, -1, Maxi);
        end
      else Simplex.AjouteContrainte(Coeff, 0, Mini);
    end;
end;

procedure TCharge.ContraintesPoids;
var i, j : integer;
    Coeff : TListeCoeff;
    V0, W0 : real;
begin
  for i := 1 to ListeMatieres.NbMatieres do { bouclage à 100 sur le poids }
    begin
      V0 := 0; W0 := 0;
      for j := 1 to AlliageVise.NbElements do
        begin
          with ListeMatieres.GetMatiere(i).Composition do
            begin
              V0 := V0 + GetTeneur(j)/100*GetRendement(j)/100;
              W0 := W0 + GetTeneur(j)/100;
            end;
        end;
     { 1-W0 = bouclage à 100 sur élément non identifié }
      V[i] := V0 + (1-W0)*R0/100;
      Coeff[i] := V[i];
    end;
  Simplex.AjouteContrainte(Coeff, 0, 1);
end;

procedure TCharge.ContraintesMatieres;
var c , i, j : integer;
    Coeff : TListeCoeff;
//    Taux, a, b : real;
begin
  for i := 1 to ListeMatieres.NbMatieres do { contraintes sur matières premieres }
    with ListeMatieres.GetMatiere(i) do begin
      for c := 0 to ListeContraintes.Count-1 do
        if ListeContraintes[c].EstUneRelation then
          begin
            for j := 1 to ListeMatieres.NbMatieres do begin
              if i = j then Coeff[j] := 1
              else
                if ListeMatieres.GetMatiere(j).Code = ListeContraintes[c].CodeMatiere then
                  Coeff[j] := -ListeContraintes[c].a
                else
                  Coeff[j] := 0;
            end;
            Simplex.AjouteContrainte(Coeff, 0, ListeContraintes[c].b/100);
          end
        else
        //if GetContrainte(c, Signe, Taux) then
          begin
            for j := 1 to ListeMatieres.NbMatieres do
              if i = j then Coeff[j] := 1 else Coeff[j] := 0;
            Simplex.AjouteContrainte(Coeff, ListeContraintes[c].Signe, ListeContraintes[c].b/100);
          end;
    end;
end;

function TCharge.GetNomMatiere(NumMatiere : integer) : string;
begin
  Result := ListeMatieres.GetMatiere(NumMatiere).Nom;
end;

function TCharge.GetPourcentEntre(NumMatiere : integer) : real;
begin
  Result := 100*(Q[NumMatiere]/FMiseAuMille);
end;

function TCharge.GetPourcentSorti(NumMatiere : integer) : real;
begin
  Result := 100*((Q[NumMatiere]/(1-FPertesAufeu))/FMiseAuMille);
end;

function TCharge.GetTonnage(NumMatiere : integer) : real;
begin
  Result := ChargeEntree * GetPourcentEntre(NumMatiere)/100;
end;

procedure TCharge.CalculePertes(TonnageEntre : real);
var i : integer;
begin
  FChargeEntree := TonnageEntre;
  FPertesAuFeu := 0; FChargeSortie := 0;
  for i := 1 to FNbCharges do
    FPertesAuFeu := FPertesAuFeu + (1-V[i])*Q[i];
  FMiseAuMille := 1 + FPertesAufeu;

  for i := 1 to FNbCharges do
    FChargeSortie := FChargeSortie + ChargeEntree*Q[i]/MiseAuMille;
  FChargeSortie := FChargeSortie*(1-FPertesAuFeu);
end;

procedure TCharge.CalculeResultats;
begin
  CalculeComposition;
  VerifieComposition;
  CalculeCout;
end;

procedure TCharge.CalculeComposition;
var i, j, n : integer;
    Teneur, Total : real;
begin
  Total := 0; n := AlliageVise.NbElements;
  for i := 1 to n do
    begin
      Teneur := 0;
      for j := 1 to ListeMatieres.NbMatieres do
        with ListeMatieres.GetMatiere(j).Composition do
          Teneur := Teneur + Q[j] * GetTeneur(i) * GetRendement(i)/100;
      Composition.SetElement(i, AlliageVise.GetSymbole(i), Teneur);
      Total := Total + Teneur;
    end;
  if abs(100-Total) > AlliageVise.Precision then Composition.SetElement(n+1, 'Autres', 100-Total);
end;

procedure TCharge.VerifieComposition;
var i : integer;
    OK : boolean;
begin
  OK := true;
  for i := 1 to AlliageVise.NbElements do begin
    if (Composition.GetTeneur(i) > AlliageVise.GetTeneurMaxi(i)+AlliageVise.Precision) or
       (Composition.GetTeneur(i) < AlliageVise.GetTeneurMini(i)-AlliageVise.Precision) then
      OK := false;
  end;
  if not OK then
    raise ESimplexError.Create('Résultats incohérents');
end;

procedure TCharge.CalculeCout;
var i : integer;
begin
  FCout := 0; FTotalPourcentEntre := 0; FTotalPourcentSorti := 0;
  with ListeMatieres do
    for i := 1 to NbMatieres do
      begin
        FTotalPourcentEntre := FTotalPourcentEntre + GetPourcentEntre(i);
        FTotalPourcentSorti := FTotalPourcentSorti + GetPourcentSorti(i);
        FCout := FCout + GetMatiere(i).Prix * GetTonnage(i);
      end;
  FCout := FCout * FMiseAuMille / FChargeEntree;
end;

procedure TCharge.Affiche(GrilleCharge, GrilleTotal, GrilleComposition : TStringGrid; GrilleValeurs : TStringGrid = nil);
var i, j : integer;
begin
  Composition.Affiche(GrilleComposition);
  with GrilleCharge do
    begin
      Cells[0, 0] := RMatierePremiere;
      Cells[1, 0] := RKgEntre;
      Cells[2, 0] := RPourcentageEntre;
      Cells[3, 0] := RPourcentageSorti;
      for i := 1 to RowCount do
        for j := 0 to 3 do
          Cells[j, i] := '';
      j := 1;
      for i:= 1 to NbCharges do
        if GetTonnage(i) > Precision then { affiche les charges non nulles }
        begin
          RowCount := j+1;
          Cells[0, j] := GetNomMatiere(i);
       //   if ListeMatieres.GetMatiere(i).Composition.MetalLiquide then
       //     Cells[0, j] := Cells[0, j] + '*';
          Cells[1, j] := FormatTonnage.Texte(GetTonnage(i));
          Cells[2, j] := Format('%3.2f', [GetPourcentEntre(i)]);
          Cells[3, j] := Format('%3.2f', [GetPourcentSorti(i)]);
          j := j + 1; {ligne suivante }
        end;
    end;
  with GrilleTotal do
    begin
      if CalculOK then
        begin
          Cells[0, 0] := RTotal;
          Cells[1, 0] := FormatTonnage.Texte(ChargeEntree);
          Cells[2, 0] := Format('%3.2f', [TotalPourcentEntre]);
          Cells[3, 0] := Format('%3.2f', [TotalPourcentSorti]);
        end
      else for i := 1 to 3 do Cells[i, 0] := '';
    end;
  if GrilleValeurs = nil then
    Exit;  
  with GrilleValeurs do begin
    Cells[0, 0] := RAlliage;
    Cells[0, 1] := RPertesAuFeu;
    Cells[0, 2] := RMiseAuMille;
    Cells[0, 3] := RTonnageEntre;
    Cells[0, 4] := RTonnageSorti;
    Cells[0, 5] := RCout;
    if CalculOK then
      begin
        if AlliageVise.EstModifie then Cells[1,0] := AlliageVise.Nom + '*'
        else Cells[1, 0] := AlliageVise.Nom;
        Cells[1, 1] := Format('%1.4f ', [PertesAuFeu*100]) + '%';
        Cells[1, 2] := Format('%1.4f', [MiseAuMille]);
        Cells[1, 3] := FormatTonnage.Texte(ChargeEntree) + ' kg';
        Cells[1, 4] := FormatTonnage.Texte(ChargeSortie) + ' kg';
        Cells[1, 5] := Format('%1.2f %s/t', [Cout, DataAdministration.SymboleMonetaire]);
       end
     else for i := 0 to 5 do Cells[1, i] := '';
   end;
end;

function TCharge.VerifieStocks : boolean;
var i : integer;
begin
  Result := true;
  for i := 1 to NbCharges do
    if GetTonnage(i) > Precision then
      if GetTonnage(i) > Base.StockMatiere(ListeMatieres.GetMatiere(i)) then
        Result := false;
end;

procedure TCharge.FixeContraintesStock;
var i : integer;
   Taux, Qe, TonnageEntre, EnStock : real;
begin
  for i := 1 to NbCharges do begin
    EnStock := Base.StockMatiere(ListeMatieres.GetMatiere(i));
    with ListeMatieres.GetMatiere(i) do
      if (GetTonnage(i) > Precision) and (GetTonnage(i) > EnStock) then
        begin
          TonnageEntre := ChargeEntree;
          Qe := EnStock*MiseAuMille/TonnageEntre;
          Taux := 100*((Qe/(1-FPertesAufeu))/FMiseAuMille);
          // Taux := 100*Stock/(ChargeSortie*MiseAuMille); // version 1.0
          Taux := Taux - Taux*Precision; { TODO : Marge pour contrainte de stock (à vérifier !) }
          SupprimeContraintes;
          FixeContrainteStock(Taux);
        end;
  end;
end;

function TCharge.GetPrix(NumMatiere: integer): real;
begin
  Result := ListeMatieres.GetMatiere(NumMatiere).Prix;
end;

procedure TCharge.Assign(Charge: TCharge);
begin
  AlliageVise.Assign(Charge.AlliageVise);
  ListeMatieres.Assign(Charge.ListeMatieres);
  Composition.Assign(Charge.Composition);
  FNbCharges := Charge.NbCharges;
  Q := Charge.Q;
  V := Charge.V;
  FPrecision := Charge.Precision;
  FCout := Charge.Cout;
  FMiseAuMille := Charge.MiseAuMille;
  FPertesAuFeu := Charge.PertesAuFeu;
  FChargeSortie := Charge.ChargeSortie;
  FChargeEntree := Charge.ChargeEntree;
  FR0 := Charge.R0;
  FTotalPourcentEntre := Charge.TotalPourcentEntre;
  FTotalPourcentSorti := Charge.TotalPourcentSorti;
  FCalculOK := Charge.CalculOK;
  TypeCharge := Charge.TypeCharge;
  CodeFusion := Charge.CodeFusion;
  RepereFusion := Charge.RepereFusion;
  IndiceBain := Charge.IndiceBain;
end;

procedure TCharge.RechercheIndiceBain;
var i : integer;
begin
  IndiceBain := -1;
  for i := 1 to ListeMatieres.NbMatieres do
    if ListeMatieres.GetMatiere(i).Code = -1 then
      begin
        IndiceBain := i;
        Exit;
      end;
end;

function TCharge.Bain: TMatiere;
begin
  Result := nil;
  if IndiceBain > 0 then
    Result := ListeMatieres.GetMatiere(IndiceBain);
end;

procedure TCharge.Imprimer(Titre : string);
var CodeFusionTmp, CodeChargeTmp : integer;
begin
  FormFusion.EnregistreFusion(Self, '', Now, CodeFusionTmp, CodeChargeTmp);
  with TFormReportFusions.Create(Application) do
    try
        with Query1 do
          begin
            Close;
            SQL.Clear;
            SQL.Add('select * from "FUSION.DB"');
            SQL.Add('where CodeFusion='+IntToStr(CodeFusionTmp));
            SQL.Add('and CodeCharge='+IntToStr(CodeChargeTmp));
            Open;
          end;
        Rapport.ReportTitle := Titre;
//        LabRepere.Caption := '';
        DBRepere.Enabled := false;
//        LabDate.Caption := '';
        Rapport.Preview;
    finally
//      DBRepere.Enabled := true;
      Free;
      FormFusion.SupprimeCharge(CodeFusionTmp, CodeChargeTmp);
    end;
end;

end.
