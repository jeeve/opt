	var app = angular.module('opt', ['ngRoute']);
	
	app.controller('opt', ['$scope', '$http', function($scope, $http) {
 
		$http.get('rest/api.php/alliage').success(function(response){
			$scope.alliages = php_crud_api_transform(response).alliage; });		
	}
	]);
	


