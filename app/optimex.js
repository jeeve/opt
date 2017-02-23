var app = angular.module('optimex', ['ngRoute']);

	app.config(function($routeProvider) {
		$routeProvider
		.when("/", {
			templateUrl: "app/views/calcul.html",
			controller: 'calculCtrl' })		
		.when("/calcul", {
			templateUrl: "app/views/calcul.html",
			controller: 'calculCtrl' })		
		.when("/alliages", {
			templateUrl: "app/views/alliages.html",
			controller: 'calculCtrl' })
		.when("/matieres", {
			templateUrl: "app/views/matieres.html",
			controller: 'calculCtrl' })
		.otherwise({
			redirectTo: "/" }
		)});
	
app.controller('mainCtrl', ['$scope', function($scope) {	

}]);

app.controller('calculCtrl', ['$scope', '$http', 'bd', function($scope, $http, bd) {

	bd.promise.then(function () {
		    
	$scope.alliages = bd.alliages();
	var minimaxis = bd.minimaxis();
	var matieres = bd.matieres();
	var compos = bd.compos();
	var matieresAlliage = bd.matieresAlliage();
	
	$scope.tonnage = 100;

	for (var i = 0; i < matieres.length; i++) {
		matieres[i].compo = [];
		for (var j = 0; j < compos.length; j++) {
			if (matieres[i].CodeMatiere == compos[j].CodeMatiere) {
				matieres[i].compo.push(compos[j]);
			}
		}
	}		
	
	$scope.changeAlliage = function() {
		$scope.matieres = [];
		$scope.alliage.minimaxi = [];
		if ($scope.alliage != null) {
			for (var k = 0; k < minimaxis.length; k++) {
				if (minimaxis[k].CodeAlliage == $scope.alliage.CodeAlliage) {
					$scope.alliage.minimaxi.push(minimaxis[k]);
				}
			}
		}
		for (var i = 0; i < matieresAlliage.length; i++) {
			if (matieresAlliage[i].CodeAlliage == $scope.alliage.CodeAlliage) {
				for (var j = 0; j < matieres.length; j++) {
					if (matieresAlliage[i].CodeMatiere == matieres[j].CodeMatiere) {
						$scope.matieres.push(matieres[j]);
					}
				}
			}
		}
	}
	
	});
}]);






