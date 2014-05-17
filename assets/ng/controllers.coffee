tempoMs = (t) -> (60/t) * 1000

drum.controller("MainCtrl", ($scope, $interval) ->
  $scope.seq =
    count: 0
    beat: 0
  $scope.tempo = 120
  $scope.heartbeat = null
  advance = ->
    $scope.seq.count += 1

  reset = ->
    $scope.seq.beat = 0
    $scope.seq.count = 0

  $scope.setStrTempo = -> $scope.tempo = parseInt($scope.tempoInput)

  $scope.on = ->
    return if $scope.heartbeat
    $scope.heartbeat = $interval(advance, (tempoMs($scope.tempo)))

  $scope.off = ->
    return unless $scope.heartbeat
    $interval.cancel($scope.heartbeat)
    $scope.heartbeat = null


)