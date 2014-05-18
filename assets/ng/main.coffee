drum = angular.module('drum', ["mgcrea.ngStrap"])

drum.filter('range', ->
  (val, range) ->
    range = parseInt(range) - 1
    [0..range]
)

instruments =
  kick: [0, 89]
  snare: [109, 197]
  snare2: [358, 183]
  tom: [554, 496]
  hatOpen: [1054, 238]
  hatClosed: [1328, 107]
  tamb: [1457, 139]
  ride: [1616, 457]