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
  kick: [0, 420]
  snare: [453, 434]
  clap: [11383, 157]
  cowbell: [908, 115]
  hiTom: [1360, 602]
  midTom: [1997, 851]
  lowTom: [2894, 839]
  hatOpen: [3756, 955]
  hatClosed: [4734, 130]
  ride: [4911, 962]
  tamb: [5878, 277]
  crash: [6830, 1267]
  splash: [8127, 843]
  china: [9578, 855]
  hiAgogo: [10591, 433]
  lowAgogo: [11095, 273]

instrumentNames = Object.keys(instruments)