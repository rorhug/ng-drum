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