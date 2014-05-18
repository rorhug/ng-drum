# tick or sq refer to semi-quaver

tempoMs = (t) -> ((60/t) * 1000)/4

drum.controller("MainCtrl", ($scope, $interval, $location, $alert, Sound, Track, Keyboard) ->
  $scope.instruments = instruments
  $scope.instrumentNames = instrumentNames

  # Track
  trackRawData = $location.path().split("/")[1]
  $scope.t = new Track(trackRawData)
  if $scope.t.invalidRawData
    $location.path("")
    $alert(
      title: 'Error'
      content: 'The track data in the url was invalid!'
      placement: 'top-right'
      container: '#alerts'
      type: 'danger'
      duration: 8
    )

  $scope.chList = ->
    list = []
    unordered = Object.keys($scope.t.channels)
    instrumentNames.forEach((i) ->
      list.push(i) unless unordered.indexOf(i) == -1
    )
    list
  $scope.deleteChannel = (inst) ->
    delete $scope.t.channels[inst]

  strike = ->
    # Play sounds
    angular.forEach($scope.t.channels, (notes, inst) ->
      Sound.play(inst) if notes[$scope.seq.semi]
    )
  Keyboard.register(80, strike)
  $scope.seq =
    ticks: -1
    beat: -1
    semi: -1
  $scope.advance = ->
    $scope.seq.ticks += 1
    recalculate()
    strike()
  $scope.retreat = ->
    if $scope.seq.ticks <= 0
      $scope.seq.ticks = $scope.t.len()
    $scope.seq.ticks -= 1
    recalculate()
    strike()
  Keyboard.register(39, $scope.advance) # right arrow
  Keyboard.register(76, $scope.advance) # l
  Keyboard.register(37, $scope.retreat) # left arrow
  Keyboard.register(72, $scope.retreat) # h
  recalculate = ->
    $scope.seq.semi = $scope.seq.ticks % ($scope.t.beatCount * 4)
    $scope.seq.beat = Math.floor($scope.seq.semi / 4)

  $scope.testPlay = (inst) ->
    Sound.play(inst)

  lastDataGenerated = ""
  $scope.generateRawData = ->
    $scope.t.cleanup()
    rawData = $scope.t.getPath()
    lastDataGenerated = rawData
  $scope.permalink = ->
    $location.path(lastDataGenerated)
    $location.absUrl()

  $scope.keyPressed = (e) ->
    Keyboard.callFn(e)

  # Random helpers
  $scope.isEmpty = (obj) ->
    !obj || angular.equals({}, obj)
)

drum.controller("PlayCtrl", ($scope, $interval, Keyboard) ->
  $scope.heartbeat = null
  $scope.reset = ->
    $scope.off()
    $scope.seq.ticks = -1
    $scope.seq.beat = -1
    $scope.seq.semi = -1
  Keyboard.register(83, $scope.reset)

  $scope.toggle = -> if $scope.heartbeat then $scope.off() else $scope.on()
  Keyboard.register(32, $scope.toggle)

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
  Keyboard.register(49, -> $scope.changeTempo(-1))
  Keyboard.register(50, -> $scope.changeTempo(1))

  $scope.changeBeatCount = (diff) ->
    if diff
      $scope.t.beatCount += diff
    $scope.t.beatCount = 1 if $scope.t.beatCount < 1
    $scope.t.beatCount = 64 if $scope.t.beatCount > 64
    no
  Keyboard.register(51, -> $scope.changeBeatCount(-1))
  Keyboard.register(52, -> $scope.changeBeatCount(1))

)

drum.controller("GridCtrl", ($scope, Keyboard) ->
  $scope.curCh =
    num: -1
    name: ""
  moveChannel = (diff) ->
    chList = $scope.chList()
    newNum = $scope.curCh.num + diff
    if (newNum >= chList.length)
      newNum = 0
    else if (newNum <= -1)
      newNum = chList.length - 1
    newName = chList[newNum]
    if $scope.seq.semi == -1
      $scope.seq.semi = 0
      $scope.seq.beat = 0
      $scope.seq.ticks = 0
    $scope.curCh.num = newNum
    $scope.curCh.name = newName
    $scope.testPlay(newName) if $scope.t.channels[newName][$scope.seq.semi]

  Keyboard.register(38, -> moveChannel(-1))
  Keyboard.register(40, -> moveChannel(1))

  $scope.noteClasses = (chan, beat, tick) ->
    s = ""
    sq = (beat * 4) + tick
    s += if $scope.t.channels[chan][sq] then "on" else "off"
    s += " active" if sq == $scope.seq.semi
    s

  $scope.toggleNote = (chan, sq) ->
    a = $scope.t.channels[chan]
    a[sq] = if a[sq] == 1 then 0 else 1
  Keyboard.register(73, ->
    $scope.toggleNote($scope.curCh.name, $scope.seq.semi)
  )
)