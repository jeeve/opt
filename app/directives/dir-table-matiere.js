app.directive("dirTableMatiere", function() {
    return {
        restrict: 'E',
        replace: false,
		scope: { matiere: '=table'},
        templateUrl: 'app/directives/dir-table-matiere.html',
		link: function(scope, element, attrs) {
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