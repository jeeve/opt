var app = angular.module('optimex', ['ngRoute']);
	
app.controller('optimexCtrl', ['$scope', '$http', function($scope, $http) {
 
	$http.get('rest/api.php/alliage').success(function(response) {
		$scope.alliages = php_crud_api_transform(response).alliage;	
	});

	var minimaxis = null;
	$http.get('rest/api.php/v_minimaxi').success(function(response) {
		minimaxis = php_crud_api_transform(response).v_minimaxi; 
	});		

	$http.get('rest/api.php/matiere').success(function(response) {
		$scope.matieres = php_crud_api_transform(response).matiere; 
		
		var compos = null;
		$http.get('rest/api.php/v_compo').success(function(response) {
			compos = php_crud_api_transform(response).v_compo; 
			for (var i = 0; i < $scope.matieres.length; i++) {
				$scope.matieres[i].compo = [];
				for (var j = 0; j < compos.length; j++) {
					if ($scope.matieres[i].CodeMatiere == compos[j].CodeMatiere) {
						$scope.matieres[i].compo.push(compos[j]);
					}
				}
			}
		});	
	});		
	
	$scope.changeAlliage = function() {
		$scope.alliage.minimaxi = [];
		if ($scope.alliage != null) {
			for (var k = 0; k < minimaxis.length; k++) {
				if (minimaxis[k].CodeAlliage == $scope.alliage.CodeAlliage) {
					$scope.alliage.minimaxi.push(minimaxis[k]);
				}
			}
		}
	}
}]);
	


