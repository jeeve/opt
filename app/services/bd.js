app.service("bd", function($http) {
	
	var myAlliages = [];
	var myMinimaxis = [];
	var myMatieres = [];
	var myCompos = [];
	var myMatieresAlliage = [];
	
	var myPromise = $http.get('rest/api.php/alliage').success(function(response) {
		myAlliages = php_crud_api_transform(response).alliage; })
		.then(function () {
			return $http.get('rest/api.php/v_minimaxi').success(function(response) {
				myMinimaxis = php_crud_api_transform(response).v_minimaxi; })
				})
		.then(function () {
			return $http.get('rest/api.php/matiere').success(function(response) {
				myMatieres = php_crud_api_transform(response).matiere; })
				})
		.then(function () {
			return $http.get('rest/api.php/v_compo').success(function(response) {
				myCompos = php_crud_api_transform(response).v_compo; })
				})
		.then(function () {
			return $http.get('rest/api.php/matieresalliage').success(function(response) {
				myMatieresAlliage = php_crud_api_transform(response).matieresalliage; })	
				});				
			
	return {
		promise: myPromise,
		alliages : function() { return myAlliages; }, 
		minimaxis : function() { return myMinimaxis; },
		matieres : function() { return myMatieres; },
		compos : function() { return myCompos; },
		matieresAlliage : function() { return myMatieresAlliage; }	
	}
});
	