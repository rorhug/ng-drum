drum.service("Sound", ->
  h = new Howl(
    urls: ['public/kit.mp3', 'public/kit.ogg']
    sprite: instruments
  )
  # @play = h.play
  @play = (name) ->
    h.play(name)
  # console.log name
  # h.stop("hatOpen") if name == "hatClosed"
  this
)