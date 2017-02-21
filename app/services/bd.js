app.service("bd", function($http) {
	
	var myAlliages = null;
	var myMinimaxis = null;
	
	var myPromise = $http.get('rest/api.php/alliage').success(function(response) {
		myAlliages = php_crud_api_transform(response).alliage; })
		.then(function () {
			return $http.get('rest/api.php/v_minimaxi').success(function(response) {
				myMinimaxis = php_crud_api_transform(response).v_minimaxi; })
				});
			
	return {
		promise: myPromise,
		alliages : function() { return myAlliages; }, 
		minimaxis : function() { return myMinimaxis; }	
	}
});
	