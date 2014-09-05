###
Echo Forms - Hellicar & Lewis
Coding - Benjamin Blundell obj. section9.co.uk


###

# Maybe this should be a class but I've split this out as its logically a little
# different to the Kaleidoscope itself - its a decorator really

{OpticalFlow} = require './flow'

loadAssets = (obj) ->

  a = () =>

    for i in [0..10]
      tt =  Math.floor(Math.random() * obj.colour_palette.length)

      item =
        target : obj.colour_palette[tt]
        colour : new CoffeeGL.Colour.RGBA.BLACK()
        idx : Math.floor(Math.random() * obj.plane.getNumTris())

      obj.loading_items.push item

    console.log ( "Loaded: " + obj.lq.completed_items.length / obj.lq.items.length)

  b = () =>
    console.log "Loaded All"
    obj.state_loaded = true


  obj.lq = new CoffeeGL.Loader.LoadQueue obj, a, b

  # Load the major video

  _loadVideo = new CoffeeGL.Loader.LoadItem () ->

    obj.video_element = document.getElementById "video_lexus"
    obj.video_element.preload = "auto"

    # Select different video format depending on the browser
    if obj.profile.browser == "Firefox"
      obj.video_element.src = "/H&L-Lexus-Edit01-final01.ogv"
    else
      obj.video_element.src = "/H&L-Lexus-Edit01-final01.mp4"

    obj.video_element.addEventListener "ended", () ->
      obj.video_element.currentTime = 0
      obj.video_element.play()
    ,false

    # This is a cheat to get the video lopping as nothing else works ><
    # Actually, a proper server link nginx works fine. Its to do with partial downloads
    obj.video_element.addEventListener "timeupdate", () ->
      #console.log obj.video_element.currentTime
      if obj.video_element.currentTime > 53 
        obj.video_element.pause()
        obj.video_element.currentTime = 0
        obj.video_element.play()
        return
    ,false

    obj.video_element.oncanplay = (event) =>
      # This play pause stuff is needed to get around events not firing ><
      if not obj.video_ready
        #obj.video_element.play()
        #obj.video_element.pause()
        #obj.video_element.currentTime = 0
        obj.video_element.play()
        obj.t.update obj.video_element
        obj.video_node.add obj.t
        obj.video_ready = true

        @loaded()
        console.log "Video Loaded"

  # Get access to the webcam for our optical flow
  _loadWebcam = new CoffeeGL.Loader.LoadItem () ->

    obj.webcam_element = document.getElementById "video_webcam"
    obj.webcam_canvas = document.getElementById "webcam-canvas"
    obj.webcam = new CoffeeGL.WebCamRTC("video_webcam",640,480,false)
  
    obj.webcam_element.oncanplay = (event) =>
      if not obj.webcam_ready

        # Create the texture that matches the webcam size
        obj.wt = new CoffeeGL.TextureBase({ width: obj.webcam_element.videoWidth, height: obj.webcam_element.videoHeight })
        obj.webcam_node.add obj.wt
        obj.webcam_element.play()
        obj.webcam_ready = true

        # Turns out jsfeat needs the window object which sucks! ><

        #obj.flow_worker = new Worker '/js/flow.js'
        #obj.flow_worker.onmessage = obj.onFlowEvent
        #obj.flow_worker.postMessage { cmd: "startup", data : obj.webcam_element }

        obj.optical_flow = new OpticalFlow(obj.webcam_element, obj.webcam_canvas)

        @loaded()
        console.log "Webcam Loaded", obj.webcam_element.videoWidth, obj.webcam_element.videoHeight

  # Return Audio Load Items
  _genLoadAudio = (audio_url,attach,long) ->

    _loadAudioSample = new CoffeeGL.Loader.LoadItem () ->
      sound = new Howl {
        urls: [audio_url]
        onload : () =>
          attach.push sound
          sound.playing = false
          @loaded()

        onplay : () ->
          obj.playing  = true
          if long
            self.sound_long_playing = true

        onend : () ->
          obj.playing  = false
          if long
            self.sound_long_playing = false
      }

      return _loadAudioSample


  obj.lq.add _loadWebcam
  obj.lq.add _loadVideo

  obj.lq.add _genLoadAudio('/sound/long/Lexus.mp3', obj.sounds_long, true)

  # Short sounds
  for i in [0..5] 
    obj.lq.add _genLoadAudio('/sound/short/sound00' + i + '.mp3', obj.sounds_short, false)

  obj.lq.start()
    
  obj

module.exports =
  loadAssets : loadAssets
