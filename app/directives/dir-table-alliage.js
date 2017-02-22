app.directive("dirTableAlliage", function() {
    return {
        restrict: 'E',
        replace: false,
		scope: { alliage: '=table'},
        templateUrl: 'app/directives/dir-table-alliage.html',
		link: function(scope, element, attrs){
            scope.showMe = false;
            scope.toggle = function toggle(){
                scope.showMe = !scope.showMe;
            };
        }
        }
});