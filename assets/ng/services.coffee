drum.service("Storage", ->
  @encode = (track) -> encodeURIComponent(btoa(JSON.stringify(track)))
  @decode = (str) ->
    try
      JSON.parse(atob(decodeURIComponent(str)))
    catch e
      null
  this
)

drum.factory("Track", (Storage) ->
  Track = (encoded) ->
    trackObj = Storage.decode(encoded) if encoded
    if trackObj
      @tempo = trackObj.tempo
      @beatCount = trackObj.beatCount
      @channels = trackObj.channels
    # Default
    @tempo ?= 120
    @beatCount ?= 4
    @channels ?=
      snare: [1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0]
    this

  Track.prototype.getPath = ->
    that = this
    Storage.encode(
      tempo: that.tempo
      beatCount: that.beatCount
      channels: that.channels
    )

  Track
)

drum.service("Sound", ->
  h = new Howl(
    urls: ['public/kit.mp3', 'public/kit.ogg']
    sprite: instruments
  )
  that = this
  @lastOpenHat = null
  @play = (name) ->
    h.play(name, (id) ->
      if name == "hatOpen" # HiHat stop
        that.lastOpenHat = id
      else if name == "hatClosed" && that.lastOpenHat
        h.stop(that.lastOpenHat)
        that.lastOpenHat = null
    )
  this
)