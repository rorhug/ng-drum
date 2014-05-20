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
  Track = (encoded, trackData) ->
    trackObj = null
    if encoded
      trackObj = Storage.decode(encoded)
      unless trackObj
        @invalidRawData = true
        trackObj = null
    else if trackData
      trackObj = trackData
    trackObj ?= defaultTrack # Default
    @tempo = trackObj.tempo || 120
    @beatCount = trackObj.beatCount || 4
    @channels = trackObj.channels || {}
    this

  Track.prototype.getPath = ->
    that = this
    Storage.encode(
      tempo: that.tempo
      beatCount: that.beatCount
      channels: that.channels
    )

  Track.prototype.len = -> @beatCount * 4

  Track.prototype.cleanup = ->
    that = this
    len = @len()
    angular.forEach(@channels, (notes, inst) ->
      # Remove notes longer than beat length
      notes.splice(len)
      # Set nulls to 0 to save on space in url
      that.channels[inst] = ((if n then n else 0) for n in notes)
    )

  Track
)

drum.service("Sound", ->
  @h = new Howl(
    urls: ['public/kit.mp3', 'public/kit.ogg']
    sprite: instruments
    volume: 1
  )
  that = this
  @lastOpenHat = null
  @play = (name) ->
    @h.play(name, (id) ->
      that.h.volume(1, id)
      if name == "hatOpen" # HiHat stop
        that.lastOpenHat = id
      else if name == "hatClosed" && that.lastOpenHat
        that.h.stop(that.lastOpenHat)
        that.lastOpenHat = null
    )
  this
)

drum.service("Keyboard", ->
  @funcs = {}
  @register = (keyCode, fn) ->
    @funcs[keyCode] = fn
  @callFn = (e) ->
    if @funcs[e.keyCode] && e.target.localName != "input"
      e.preventDefault()
      @funcs[e.keyCode]()
  this
)