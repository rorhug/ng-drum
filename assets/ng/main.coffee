(window.btoa = (str) -> Base64.encode(str)) if (!window.btoa)
(window.atob = (str) -> Base64.decode(str)) if (!window.atob)

drum = angular.module('drum', ["mgcrea.ngStrap"])

drum.filter('range', ->
  (val, range) ->
    range = parseInt(range) - 1
    [0..range]
)

drum.filter('trackJson', ->
  (object) ->
    return '' unless object
    JSON.stringify(object)
)

instruments =
  kick: [0, 280]
  snare: [350, 250]
  cowbell: [653, 87]
  hiTom: [774, 627]
  midTom: [1418, 525]
  lowTom: [1977, 790]
  hatOpen: [2866, 575]
  hatClosed: [3442, 140]
  ride: [3602, 739]
  tamb: [4365, 293]

instrumentNames = Object.keys(instruments)