# tick or sq refer to semi-quaver

tempoMs = (t) -> ((60/t) * 1000)/4

drum.controller("MainCtrl", ($scope, $interval, $location, Sound, Track) ->
  $scope.instruments = instruments

  # Track
  trackRawData = $location.path().split("/")[1]
  $scope.t = new Track(trackRawData)

  $scope.deleteChannel = (inst) ->
    delete $scope.t.channels[inst]

  $scope.seq =
    ticks: -1
    beat: -1
    semi: -1
  $scope.advance = ->
    ticks = $scope.seq.ticks + 1
    $scope.seq.ticks = ticks
    s = ticks % ($scope.t.beatCount * 4)
    $scope.seq.semi = s
    $scope.seq.beat = Math.floor($scope.seq.semi / 4)

    # Play sounds
    angular.forEach($scope.t.channels, (notes, inst) ->
      Sound.play(inst) if notes[s]
    )

  $scope.testPlay = (inst) ->
    console.log(inst)
    Sound.play(inst)

  lastDataGenerated = ""
  $scope.generateRawData = ->
    $scope.t.cleanup()
    rawData = $scope.t.getPath()
    lastDataGenerated = rawData
  $scope.permalink = ->
    $location.path(lastDataGenerated)
    $location.absUrl()

  # Random helpers
  $scope.isEmpty = (obj) ->
    !obj || angular.equals({}, obj)
)

drum.controller("PlayCtrl", ($scope, $interval) ->
  $scope.heartbeat = null
  $scope.reset = ->
    $scope.off()
    $scope.seq.ticks = -1
    $scope.seq.beat = -1
    $scope.seq.semi = -1

  $scope.on = ->
    return if $scope.heartbeat
    $scope.heartbeat = $interval($scope.advance, (tempoMs($scope.t.tempo)))

  $scope.off = ->
    return unless $scope.heartbeat
    $interval.cancel($scope.heartbeat)
    $scope.heartbeat = null

  $scope.addChannel = (inst) ->
    return if !$scope.instruments[inst] || $scope.t.channels[inst]
    $scope.t.channels[inst] = [0]

  $scope.changeTempo = (diff) ->
    if diff
      $scope.t.tempo += diff
    $scope.t.tempo = 1 if $scope.t.tempo < 1
    $scope.t.tempo = 350 if $scope.t.tempo > 350
    if $scope.heartbeat
      $scope.off()
      $scope.on()
    no

  $scope.changeBeatCount = (diff) ->
    if diff
      $scope.t.beatCount += diff
    $scope.t.tempo = 1 if $scope.t.tempo < 1
    $scope.t.tempo = 64 if $scope.t.tempo > 64
    no
)

drum.controller("GridCtrl", ($scope) ->
  $scope.noteClasses = (chan, beat, tick) ->
    s = ""
    sq = (beat * 4) + tick
    s += if $scope.t.channels[chan][sq] then "on" else "off"
    s += " active" if sq == $scope.seq.semi
    s

  $scope.toggleNote = (chan, beat, tick) ->
    sq = (beat * 4) + tick
    a = $scope.t.channels[chan]
    a[sq] = if a[sq] == 1 then 0 else 1
)