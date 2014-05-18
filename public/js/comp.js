var drum, instruments;

drum = angular.module('drum', ["mgcrea.ngStrap"]);

drum.filter('range', function() {
  return function(val, range) {
    var _i, _results;
    range = parseInt(range) - 1;
    return (function() {
      _results = [];
      for (var _i = 0; 0 <= range ? _i <= range : _i >= range; 0 <= range ? _i++ : _i--){ _results.push(_i); }
      return _results;
    }).apply(this);
  };
});

instruments = {
  kick: [0, 89],
  snare: [109, 197],
  snare2: [358, 183],
  tom: [554, 496],
  hatOpen: [1054, 238],
  hatClosed: [1328, 107],
  tamb: [1457, 139],
  ride: [1616, 457]
};

drum.service("Sound", function() {
  var h;
  h = new Howl({
    urls: ['public/kit.mp3', 'public/kit.ogg'],
    sprite: instruments
  });
  this.play = function(name) {
    return h.play(name);
  };
  return this;
});

var tempoMs;

tempoMs = function(t) {
  return ((60 / t) * 1000) / 4;
};

drum.controller("MainCtrl", function($scope, $interval, Sound) {
  $scope.instruments = instruments;
  $scope.t = {
    beatCount: 4,
    channels: {
      snare: [1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0]
    }
  };
  $scope.deleteChannel = function(inst) {
    return delete $scope.t.channels[inst];
  };
  $scope.seq = {
    ticks: -1,
    beat: -1,
    semi: -1
  };
  $scope.tempo = 120;
  $scope.advance = function() {
    var s, ticks;
    ticks = $scope.seq.ticks + 1;
    $scope.seq.ticks = ticks;
    s = ticks % ($scope.t.beatCount * 4);
    $scope.seq.semi = s;
    $scope.seq.beat = Math.floor($scope.seq.semi / 4) % 4;
    return angular.forEach($scope.t.channels, function(notes, inst) {
      if (notes[s]) {
        return Sound.play(inst);
      }
    });
  };
  return $scope.isEmpty = function(obj) {
    return angular.equals({}, obj);
  };
});

drum.controller("PlayCtrl", function($scope, $interval) {
  $scope.heartbeat = null;
  $scope.reset = function() {
    $scope.off();
    $scope.seq.ticks = -1;
    $scope.seq.beat = -1;
    return $scope.seq.semi = -1;
  };
  $scope.on = function() {
    if ($scope.heartbeat) {
      return;
    }
    return $scope.heartbeat = $interval($scope.advance, tempoMs($scope.tempo));
  };
  $scope.off = function() {
    if (!$scope.heartbeat) {
      return;
    }
    $interval.cancel($scope.heartbeat);
    return $scope.heartbeat = null;
  };
  return $scope.addChannel = function(inst) {
    if (!$scope.instruments[inst] || $scope.t.channels[inst]) {
      return;
    }
    return $scope.t.channels[inst] = [0];
  };
});

drum.controller("GridCtrl", function($scope) {
  $scope.noteAmount = function() {
    return $scope.t.beatCount * 4;
  };
  $scope.noteClasses = function(chan, beat, tick) {
    var s, sq;
    s = "";
    sq = (beat * 4) + tick;
    s += $scope.t.channels[chan][sq] ? "on" : "off";
    if (sq === $scope.seq.semi) {
      s += " active";
    }
    return s;
  };
  return $scope.toggleNote = function(chan, beat, tick) {
    var a, sq;
    sq = (beat * 4) + tick;
    a = $scope.t.channels[chan];
    return a[sq] = a[sq] === 1 ? 0 : 1;
  };
});

drum.directive("focusMe", function($timeout, $parse) {
  return {
    link: function(scope, element, attrs) {
      var model;
      model = $parse(attrs.focusMe);
      scope.$watch(model, function(value) {
        if (value === true) {
          return $timeout(function() {
            return element[0].focus();
          });
        }
      });
      return element.bind("blur", function() {
        return scope.$apply(model.assign(scope, false));
      });
    }
  };
});
