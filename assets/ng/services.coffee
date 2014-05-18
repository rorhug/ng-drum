drum.service("Sound", ->
  h = new Howl(
    urls: ['public/kit.mp3', 'public/kit.ogg']
    sprite: instruments
  )
  @play = (name) ->
    h.play(name)
  this
)