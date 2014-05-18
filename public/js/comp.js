var drum, instrumentNames, instruments;

if (!window.btoa) {
  window.btoa = function(str) {
    return Base64.encode(str);
  };
}

if (!window.atob) {
  window.atob = function(str) {
    return Base64.decode(str);
  };
}

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

drum.filter('trackJson', function() {
  return function(object) {
    if (!object) {
      return '';
    }
    return JSON.stringify(object);
  };
});

instruments = {
  kick: [0, 280],
  snare: [350, 250],
  cowbell: [653, 87],
  hiTom: [774, 627],
  midTom: [1418, 525],
  lowTom: [1977, 790],
  hatOpen: [2866, 575],
  hatClosed: [3442, 140],
  ride: [3602, 739],
  tamb: [4365, 293]
};

instrumentNames = Object.keys(instruments);

drum.service("Storage", function() {
  this.encode = function(track) {
    return encodeURIComponent(btoa(JSON.stringify(track)));
  };
  this.decode = function(str) {
    var e;
    try {
      return JSON.parse(atob(decodeURIComponent(str)));
    } catch (_error) {
      e = _error;
      return null;
    }
  };
  return this;
});

drum.factory("Track", function(Storage) {
  var Track;
  Track = function(encoded) {
    var trackObj;
    if (encoded) {
      trackObj = Storage.decode(encoded);
    }
    if (trackObj === null) {
      this.invalidRawData = true;
    } else if (trackObj) {
      this.tempo = trackObj.tempo;
      this.beatCount = trackObj.beatCount;
      this.channels = trackObj.channels;
    }
    if (this.tempo == null) {
      this.tempo = 120;
    }
    if (this.beatCount == null) {
      this.beatCount = 4;
    }
    if (this.channels == null) {
      this.channels = {
        "snare": [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
        "kick": [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1],
        "hatClosed": [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0],
        "hatOpen": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0]
      };
    }
    return this;
  };
  Track.prototype.getPath = function() {
    var that;
    that = this;
    return Storage.encode({
      tempo: that.tempo,
      beatCount: that.beatCount,
      channels: that.channels
    });
  };
  Track.prototype.len = function() {
    return this.beatCount * 4;
  };
  Track.prototype.cleanup = function() {
    var len, that;
    that = this;
    len = this.len();
    return angular.forEach(this.channels, function(notes, inst) {
      var n;
      notes.splice(len);
      return that.channels[inst] = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = notes.length; _i < _len; _i++) {
          n = notes[_i];
          _results.push(n ? n : 0);
        }
        return _results;
      })();
    });
  };
  return Track;
});

drum.service("Sound", function() {
  var h, that;
  h = new Howl({
    urls: ['public/kit.mp3', 'public/kit.ogg'],
    sprite: instruments
  });
  that = this;
  this.lastOpenHat = null;
  this.play = function(name) {
    return h.play(name, function(id) {
      if (name === "hatOpen") {
        return that.lastOpenHat = id;
      } else if (name === "hatClosed" && that.lastOpenHat) {
        h.stop(that.lastOpenHat);
        return that.lastOpenHat = null;
      }
    });
  };
  return this;
});

drum.service("Keyboard", function() {
  this.funcs = {};
  this.register = function(keyCode, fn) {
    return this.funcs[keyCode] = fn;
  };
  this.callFn = function(e) {
    if (this.funcs[e.keyCode] && e.target.localName !== "input") {
      e.preventDefault();
      return this.funcs[e.keyCode]();
    }
  };
  return this;
});

var tempoMs;

tempoMs = function(t) {
  return ((60 / t) * 1000) / 4;
};

drum.controller("MainCtrl", function($scope, $interval, $location, $alert, Sound, Track, Keyboard) {
  var lastDataGenerated, recalculate, strike, trackRawData;
  $scope.instruments = instruments;
  $scope.instrumentNames = instrumentNames;
  trackRawData = $location.path().split("/")[1];
  $scope.t = new Track(trackRawData);
  if ($scope.t.invalidRawData) {
    $location.path("");
    $alert({
      title: 'Error',
      content: 'The track data in the url was invalid!',
      placement: 'top-right',
      container: '#alerts',
      type: 'danger',
      duration: 8
    });
  }
  $scope.chList = function() {
    var list, unordered;
    list = [];
    unordered = Object.keys($scope.t.channels);
    instrumentNames.forEach(function(i) {
      if (unordered.indexOf(i) !== -1) {
        return list.push(i);
      }
    });
    return list;
  };
  $scope.deleteChannel = function(inst) {
    return delete $scope.t.channels[inst];
  };
  strike = function() {
    return angular.forEach($scope.t.channels, function(notes, inst) {
      if (notes[$scope.seq.semi]) {
        return Sound.play(inst);
      }
    });
  };
  Keyboard.register(80, strike);
  $scope.seq = {
    ticks: -1,
    beat: -1,
    semi: -1
  };
  $scope.advance = function() {
    $scope.seq.ticks += 1;
    recalculate();
    return strike();
  };
  $scope.retreat = function() {
    if ($scope.seq.ticks <= 0) {
      $scope.seq.ticks = $scope.t.len();
    }
    $scope.seq.ticks -= 1;
    recalculate();
    return strike();
  };
  Keyboard.register(39, $scope.advance);
  Keyboard.register(76, $scope.advance);
  Keyboard.register(37, $scope.retreat);
  Keyboard.register(72, $scope.retreat);
  recalculate = function() {
    $scope.seq.semi = $scope.seq.ticks % ($scope.t.beatCount * 4);
    return $scope.seq.beat = Math.floor($scope.seq.semi / 4);
  };
  $scope.testPlay = function(inst) {
    return Sound.play(inst);
  };
  lastDataGenerated = "";
  $scope.generateRawData = function() {
    var rawData;
    $scope.t.cleanup();
    rawData = $scope.t.getPath();
    if (rawData === lastDataGenerated) {
      return;
    }
    lastDataGenerated = rawData;
    return ga('send', 'event', 'permalink', 'generate');
  };
  $scope.permalink = function() {
    $location.path(lastDataGenerated);
    return $location.absUrl();
  };
  $scope.keyPressed = function(e) {
    return Keyboard.callFn(e);
  };
  return $scope.isEmpty = function(obj) {
    return !obj || angular.equals({}, obj);
  };
});

drum.controller("PlayCtrl", function($scope, $interval, Keyboard) {
  $scope.heartbeat = null;
  $scope.reset = function() {
    $scope.off();
    $scope.seq.ticks = -1;
    $scope.seq.beat = -1;
    return $scope.seq.semi = -1;
  };
  Keyboard.register(83, $scope.reset);
  $scope.toggle = function() {
    if ($scope.heartbeat) {
      return $scope.off();
    } else {
      return $scope.on();
    }
  };
  Keyboard.register(32, $scope.toggle);
  $scope.on = function() {
    if ($scope.heartbeat) {
      return;
    }
    return $scope.heartbeat = $interval($scope.advance, tempoMs($scope.t.tempo));
  };
  $scope.off = function() {
    if (!$scope.heartbeat) {
      return;
    }
    $interval.cancel($scope.heartbeat);
    return $scope.heartbeat = null;
  };
  $scope.addChannel = function(inst) {
    if (!$scope.instruments[inst] || $scope.t.channels[inst]) {
      return;
    }
    return $scope.t.channels[inst] = [0];
  };
  $scope.changeTempo = function(diff) {
    if (diff) {
      $scope.t.tempo += diff;
    }
    if ($scope.t.tempo < 1) {
      $scope.t.tempo = 1;
    }
    if ($scope.t.tempo > 350) {
      $scope.t.tempo = 350;
    }
    if ($scope.heartbeat) {
      $scope.off();
      $scope.on();
    }
    return false;
  };
  Keyboard.register(49, function() {
    return $scope.changeTempo(-1);
  });
  Keyboard.register(50, function() {
    return $scope.changeTempo(1);
  });
  $scope.changeBeatCount = function(diff) {
    if (diff) {
      $scope.t.beatCount += diff;
    }
    if ($scope.t.beatCount < 1) {
      $scope.t.beatCount = 1;
    }
    if ($scope.t.beatCount > 64) {
      $scope.t.beatCount = 64;
    }
    return false;
  };
  Keyboard.register(51, function() {
    return $scope.changeBeatCount(-1);
  });
  return Keyboard.register(52, function() {
    return $scope.changeBeatCount(1);
  });
});

drum.controller("GridCtrl", function($scope, Keyboard) {
  var moveChannel;
  $scope.curCh = {
    num: -1,
    name: ""
  };
  moveChannel = function(diff) {
    var chList, newName, newNum;
    chList = $scope.chList();
    newNum = $scope.curCh.num + diff;
    if (newNum >= chList.length) {
      newNum = 0;
    } else if (newNum <= -1) {
      newNum = chList.length - 1;
    }
    newName = chList[newNum];
    if ($scope.seq.semi === -1) {
      $scope.seq.semi = 0;
      $scope.seq.beat = 0;
      $scope.seq.ticks = 0;
    }
    $scope.curCh.num = newNum;
    $scope.curCh.name = newName;
    if ($scope.t.channels[newName][$scope.seq.semi]) {
      return $scope.testPlay(newName);
    }
  };
  Keyboard.register(38, function() {
    return moveChannel(-1);
  });
  Keyboard.register(75, function() {
    return moveChannel(-1);
  });
  Keyboard.register(40, function() {
    return moveChannel(1);
  });
  Keyboard.register(74, function() {
    return moveChannel(1);
  });
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
  $scope.toggleNote = function(chan, sq) {
    var a;
    a = $scope.t.channels[chan];
    return a[sq] = a[sq] === 1 ? 0 : 1;
  };
  return Keyboard.register(73, function() {
    return $scope.toggleNote($scope.curCh.name, $scope.seq.semi);
  });
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

drum.directive("selectAllOnClick", function($timeout) {
  return {
    link: function(scope, element, attrs) {
      return $timeout(function() {
        element[0].focus();
        return element[0].select();
      });
    }
  };
});
