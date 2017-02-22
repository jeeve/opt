app.directive("dirTableMatiere", function() {
    return {
        restrict: 'E',
        replace: false,
		scope: { matiere: '=table'},
        templateUrl: 'app/directives/dir-table-matiere.html'
        }
});