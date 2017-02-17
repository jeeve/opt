const rowmx = 50;
const colmx = 500;
const mxval = 1.0E+35;
const zero = 0.0;
const eqzero = 0;

function Simplex() {
	var matice = new Array();
	var inegalite = new Array();
	var basis = new Array();
	var basisp = new Array();
	var minmax = 0.0;
	var error = 0;
	var ncon = 0;
	var nltcon = 0;
	var neqcon = 0;
	var ngtcon = 0;
	var trows1 = 0;
	var trows2 = 0;
	var tcols1 = 0;
	var tcols2 = 0;
	var tcols3 = 0;
	var ni = 0;
	var ne = 0;
	var ns = 0;
	
	function trieContraintes() {
		
		function quickSort(iLo, iHi) {
			var Lo, Hi, Mid, T;
			Lo = iLo;
			Hi = iHi;
			Mid = inegalite[(Lo + Hi) div 2];
			while (Lo < Hi) do {
				while (inegalite[Lo] < Mid) do Lo++;
				while (inegalite[Hi] > Mid) do Hi--;
				if (Lo <= Hi) {
					permuteContraintes(Hi, Lo);
					T = inegalite[Lo];
					inegalite[Lo] := inegalite[Hi];
					inegalite[Hi] := T;
					Lo++;
					Hi--;
				}
			}
			if (Hi > iLo) quickSort(iLo, Hi);
			if (Lo < iHi) quickSort(Lo, iHi);
		}
		
		quickSort(1, ncon);
	}
	
	function permuteContraintes(i, j) {
		var tmp = 0.0;
		for (var col = 1; col <= nvar; col++) {
			tmp = getmatrix(i, col);
			putmatrix(i, col, getmatrix(j, col));
			putmatrix(j, col, tmp);
		}
		tmp = getmatrix(i, 0);
		putmatrix(i, 0, getmatrix(j, 0));
		putmatrix(j, 0, tmp);
		tmp = getmatrix(i, tcols2);
		putmatrix(i, tcols2, getmatrix(j, tcols2));
		putmatrix(j, tcols2, tmp);		
	}
	
	function getmatrix(row, col) {
		return := matice[row, col];	
	}
	
	function putmatrix(row, col, value) {
		matrice[row, col] = value;	
	}
	
	function initmatrix() {
		for (var row = 0; row <= rowmx; row++) 
			for (var col = 0; col <= colmx; col++) 
				putmatrix(row, col, zero);		
	}
	
	function setbasis() {
		var row, flag;
		for (var col = 1; col <= nvar; col++) {
			flag = false;
			row := 1;
			while (!flag && (row <= ncon)) {
				if (basis[row] == col) 
					flag = true
				else
					row++;
			};
         if (flag) 
            basisp[col] = row
         else
            basisp[col] = 0;
		}		
	}
	
	function price(v-xcol, trow, v-error) {
		var quant, val, col;
		quant = -eqzero;
		for (col = 1; col <= tcols3; col++) {
			val = getmatrix(trow, col);
			if (val < quant) {
				v-xcol.value = col;
				quant = val;
			}
		}
		v-error.value = 0;
		if (quant == -eqzero) 
			v-error.value = 1;		
	}
	
	function leave(v-xrow, xcol, v-error) {
		var quant, val, row;
		quant = mxval;
		for (row = 1; row <= ncon; row++) {
			val = getmatrix( row, xcol );
			if (val > eqzero) {
               try {
					val = getmatrix(row, tcols2) / val;
			   }
               catch {
					val = mxval;
               }
               if (val < quant) {
                    v-xrow.value = row;
                    quant = val;
			   }
            }
		}
		v-error.value = 0;
		if (quant == mxval )
			v-error.value = 2;		
	}
	
	function pivot(xrow, xcol) {
		var value, val, vl, row, col;
		value = getmatrix(xrow, xcol);
		for (row = 1; row <= trows2; row++) {
			if (row != xrow) {
				vl = getmatrix( row, xcol );
				for (col = 1; col <= tcols2; col++) {
					if (col != xcol) {
						val = getmatrix( row, col ) - vl * getmatrix( xrow, col ) / value;
						if (abs( val ) < eqzero) 
							val = zero;
						putmatrix( row, col, val );
					}
				}
			}
		for (col = 1; col <= tcols2; col++) 
			putmatrix(xrow, col, getmatrix(xrow, col) / value);
		for (row = 1; row <= trows2; row++)
			putmatrix( row, xcol, zero );
		putmatrix( xrow, xcol, 1.0);
		basis[ xrow ] := xcol;		
		}
	}
	
	function optimize(trow, v-error) {
		var xrow, xcol;
		while (v-error.value == 0) {
			price( xcol, trow, error );
			if ( v-error.value == 0 ) 
				leave( xrow, xcol, error );
			if (v-error.value == 0 ) then
				pivot( xrow, xcol );
		}
	}
	
	function simplex(v-error) {
		var row, col,flag;
		if ( ncon != nltcon ) {
			optimize( trows1, v-error );
			if ( error > 1 ) 
				break;
			v-error.value = 3;
			for (row = 1; row <= ncon; row++) {
				if ( basis[ row ] > tcols3 ) {
					if ( getmatrix( row, tcols2 ) > eqzero ) 
						break;
                  flag = false;
                  col = 1;
                  while (!(flag) && (col <= tcols3)) { 
                     if ( abs( getmatrix( row, col ) ) >= eqzero ) {
                           pivot( row, col );
                           flag = true;
					 }
                     col++;
                  }
				}
			}
		}
		v-error.value = 0;
		optimize( trows2, v-error );		
	}
}

Simplex.prototype.prepareCalcul(sens, nbVariables, nbInferieurs, nbEgals, nbSuperieurs) {
	var row, col, column;
	ni = 0; ne = 0; ns = 0;
	error = 0;
	nltcon = nbInferieurs;
	neqcon = nbEgals;
	ngtcon = nbSuperieurs;
	ncon   = nltcon+neqcon+ngtcon;
	minmax = -sens;
	nvar   = nbVariables;
	trows1 = ncon + 1;
	trows2 = ncon + 2;
	tcols1 = nvar + ncon + ngtcon;
	tcols2 = tcols1 + 1;
	tcols3 = nvar + nltcon + ngtcon;

	for (var i = 0; i < trows2; i++) {
		for (var j = 0; j < tcols2; j++) {
			matrice[i, j] = zero;
		}
	}

   for (row = 1; row <= ncon; row++) 
      basis[ row ] = 0;

   for (row = 1; row <= ncon; row++)
      if ( row <= nltcon ) {
            column = nvar + row;
            basis[ row ] = column;
            putmatrix( row, column, +1.0 );
	  }
      else {
            column := nvar + ngtcon + row;
            basis[ row ] := column;
            putmatrix( row, column, +1.0 );
            if ( row > nltcon + neqcon ) {
                  column = nvar - neqcon + row;
                  putmatrix( row, column, -1.0 );
                  putmatrix( trows1, column, +1.0 );
            }
	  }
  ncon = 0;
}

Simplex.prototype.ajouteContrainte(coeff, signe, secondMembre);
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
