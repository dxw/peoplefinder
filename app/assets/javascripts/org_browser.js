/* global angular, window */
var peoplefinderApp = angular.module('peoplefinderApp', ['ngAnimate']);

peoplefinderApp.controller('OrgBrowserCtrl', function($scope, $http) {
  var pathToNodeId = function(node, id, path) {
    path = path || [node];

    if (node.id === id) { return path; }

    for (var i = 0, ii = node.children.length; i < ii; i++) {
      var child = node.children[i];
      var res = pathToNodeId(child, id, path.concat(child));
      if (res) { return res; }
    }

    return null;
  };

  $scope.moveDown = function(group) {
    if ($scope.isExpandable(group)) {
      $scope.groups.push(group);
    }
    $scope.select(group);
  };

  $scope.moveUp = function(group) {
    while ($scope.current !== group) { $scope.groups.pop(); }
    $scope.select(group);
  };

  $scope.isExpandable = function(group) {
    return group.children.length > 0;
  };

  $scope.isSelected = function(group) {
    return group.id === $scope.selectedId;
  };

  $scope.select = function(group) {
    $scope.selectedId = group.id;
    if (window.setOrgBrowserGroupId) {
      window.setOrgBrowserGroupId(group.id);
    }
  };

  Object.defineProperty(
    $scope, 'current',
    { get: function() { return $scope.groups[$scope.groups.length - 1]; } }
  );

  $scope.groups = [];

  if (window.getOrgBrowserGroupId) {
    $scope.selectMode = true;
    $scope.selectedId = window.getOrgBrowserGroupId();
  }

  $http.get('/org.json').success(function(tree) {
    var path;
    if ($scope.selectMode) {
      path = pathToNodeId(tree, $scope.selectedId);
      $scope.select(path[path.length - 1]);
    } else {
      path = [tree];
    }
    path.forEach(function(group) { $scope.moveDown(group); });
  });
});