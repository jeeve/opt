app.directive("dirTableMatiere", function() {
    return {
        restrict: 'E',
        replace: false,
		scope: { matiere: '=table'},
        templateUrl: 'app/directives/dir-table-matiere.html',
		link: function(scope, element, attrs){
            scope.showMe = false;
            scope.toggle = function toggle(){
                scope.showMe = !scope.showMe;
            };
		}
        }
});