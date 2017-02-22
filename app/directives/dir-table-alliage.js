app.directive("dirTableAlliage", function() {
    return {
        restrict: 'E',
        replace: false,
		scope: { alliage: '=table'},
        templateUrl: 'app/directives/dir-table-alliage.html'
        }
});