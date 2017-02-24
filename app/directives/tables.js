app.directive("tableAlliage", function() {
    return {
        restrict: 'E',
        replace: false,
		scope: { alliage: '=table'},
        templateUrl: 'app/directives/table-alliage.html',
		link: function(scope, element, attrs){
			scope.etatBouton = 'btn-releve';
            scope.showMe = false;
            scope.toggle = function toggle(){
                scope.showMe = !scope.showMe;
				if (scope.etatBouton == 'btn-releve')
					scope.etatBouton = 'btn-enfonce'
				else
					scope.etatBouton = 'btn-releve';
            };
        }
        }
});

app.directive("tableMatiere", function() {
    return {
        restrict: 'E',
        replace: false,
		scope: { matiere: '=table'},
        templateUrl: 'app/directives/table-matiere.html',
		link: function(scope, element, attrs) {
			scope.etatBoutonEdit = 'btn-releve';
            scope.showMe = false;
            scope.edit = function () {
                scope.showMe = !scope.showMe;
				if (scope.etatBoutonEdit == 'btn-releve')
					scope.etatBoutonEdit = 'btn-enfonce'
				else
					scope.etatBoutonEdit = 'btn-releve';
            };
			scope.etatBoutonDetail = 'btn-releve';
			scope.detail = false;
            scope.developpe = function () {
				scope.detail = !scope.detail;
				if (scope.etatBoutonDetail == 'btn-releve') {
					scope.etatBoutonDetail = 'btn-enfonce';
					element.addClass('nom-matiere-selectionnee');
				}
				else
				{
					scope.etatBoutonDetail = 'btn-releve';
					element.removeClass('nom-matiere-selectionnee');

				}
            };
			}
        }
});