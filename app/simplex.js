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
	var error = {value: 0};
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
				leave( xrow, xcol.value, error );
			if (v-error.value == 0 ) then
				pivot( xrow.value, xcol.value );
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

// méthodes

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

Simplex.prototype.ajouteContrainte(coeff, signe, secondMembre) {
	switch(sign) {
		case -1 : ni++; break;
		case 0 : ne++; break;
		case +1 : ns++; break;
		default console.log('Signe non définit');
  }

	ncon++;
	if (ncon+2 > rowmx)
		console.log('Trop de contraintes');

	for (var col = 1; col <= nvar; col++) {
		putmatrix(ncon, col, coeff[col]);
	}
  
	inegalite[ncon] = signe;
	putmatrix(ncon, 0, secondMembre);
	putmatrix(ncon, tcols2, secondMembre);
  }
}

Simplex.prototype.definitFonction(coeff) {
	var row, value;
	trieContraintes();
	for (var col = 1; col <= nvar; col++) {
		putmatrix(0 , col, minmax * coeff[col]);
		putmatrix(trows2, col, minmax * coeff[col]);
	}
	// calculate artifical variables 
	for (var col = 1; col <= nvar; col++) {
		value = zero;
		for (row = nltcon+1; row <= ncon; row++) {
			value = value - getmatrix( row, col );
		}
      putmatrix( trows1, col, value );
    }
}

Simplex.prototype.Optimise() {
	if ((ni != nltcon) || (ne != neqcon) || (ns != ngtcon)) 
		console.log('Nombre de contraintes incorrect');
	if ( error.value == 0 ) 
      simplex( error );
	if ( error.value < 0 ) 
     console.log('Inconsistent Data - Not Run');
	if ( error.value == 2 ) then
     console.log('The Solution is Unbounded');
	if ( error.value == 3 ) then
     console.log('Le problème est insoluble');
	if ((error.value == 0) || (error.value == 1)) 
		return true;
	else
		return false;
end;

Simplex.prototype.litResultats() {
	var resulat = {fonction: -minmax*getmatrix(trows2, tcols2), coeff: []};
	setbasis;
	resulat.fonction := -minmax*getmatrix(trows2, tcols2);
	for (var col = 1; col <= nvar; col++) {
		if (basisp[col] != 0) {
			resulat.coeff[col] := getmatrix(basisp[col], tcols2);
		}
		else {
			resulat.coeff[col] = 0;
		}
	}
	return resulat;
}