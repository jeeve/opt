var app = angular.module('opt', ['ngRoute']);
	
app.controller('optima', ['$scope', '$http', function($scope, $http) {
 
	$http.get('rest/api.php/alliage').success(function(response) {
		$scope.alliages = php_crud_api_transform(response).alliage;	
	});

	var minimaxis = null;
	$http.get('rest/api.php/minimaxi').success(function(response) {
		minimaxis = php_crud_api_transform(response).minimaxi; 
	});		

	$http.get('rest/api.php/matiere').success(function(response) {
		$scope.matieres = php_crud_api_transform(response).matiere; 
		
		var compos = null;
		$http.get('rest/api.php/compo').success(function(response) {
			compos = php_crud_api_transform(response).compo; 
			for (var i = 0; i < $scope.matieres.length; i++) {
				for (var j = 0; j < compos.length; j++) {
					if ($scope.matieres[i].CodeMatiere == compos[j].CodeMatiere) {
						$scope.matieres[i].compo = compos[j];
						break;
					}
				}
			}
		});	
	});		
		
	$scope.changeAlliage = function() {
		if ($scope.alliage != null) {
			for (var k = 0; k < minimaxis.length; k++) {
				if (minimaxis[k].CodeAlliage == $scope.alliage.CodeAlliage) {
					$scope.alliage.minimaxi = minimaxis[k];
					break;
				}
			}
		}
	}
}

]);
	


