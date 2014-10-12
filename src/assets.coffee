###
Echo Forms - Hellicar & Lewis
Coding - Benjamin Blundell obj. section9.co.uk


###

# Maybe this should be a class but I've split this out as its logically a little
# different to the Kaleidoscope itself - its a MASSIVE decorator really

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

  b = () =>
    obj.state["loaded"] = true


  obj.lq = new CoffeeGL.Loader.LoadQueue obj, a, b

  # Load the major video

  _loadVideo = new CoffeeGL.Loader.LoadItem () ->

    obj.video_element = document.getElementById "video_default"
    obj.video_element.preload = "auto"

    # Select different video format depending on the browser
    if CoffeeGL.Context.profile.browser == "Firefox"
      obj.video_element.src = "/video_default.ogv"
    else
      obj.video_element.src = "/video_default.mp4"

    obj.video_element.addEventListener "ended", () ->
      obj.video_element.currentTime = 0
      obj.video_element.play()
    ,false

    # This is a cheat to get the video lopping as nothing else works ><
    # Actually, a proper server link nginx works fine. Its to do with partial downloads
    
    obj.video_element.addEventListener "timeupdate", () ->
      if obj.video_element.currentTime > 53 
        obj.video_element.pause()
        obj.video_element.currentTime = 0
        obj.video_element.play()
        return
    ,false

    obj.video_element.oncanplay = (event) =>
      # This play pause stuff is needed to get around events not firing ><
      if not obj.state["video"]
        obj.video_element.play()
        obj.t.update obj.video_element
        obj.video_node.add obj.t
        obj.state["video"] = true

        @loaded()
        console.log "Video Loaded"

  # Get access to the webcam for our optical flow
  _loadWebcam = new CoffeeGL.Loader.LoadItem () ->

    webcamError = () =>
      # webcam couldnt be loaded so proceed without
      obj.state["webcam"] = false
      @loaded()

    obj.webcam_element = document.getElementById "video_webcam"
    obj.webcam_canvas = document.getElementById "webcam_canvas"
    obj.webcam = new CoffeeGL.WebCamRTC("video_webcam",640,480,false,webcamError)
  

    obj.webcam_element.oncanplay = (event) =>
      if not obj.state["webcam"]

        # Create the texture that matches the webcam size
        obj.wt = new CoffeeGL.TextureBase({ width: obj.webcam_element.videoWidth, height: obj.webcam_element.videoHeight, unit: 1 })
        obj.webcam_node.add obj.wt
        obj.webcam_element.play()
       
        # Add the new texture to the video node so we can fade
        obj.video_node.add obj.wt

        # Turns out jsfeat needs the window object which sucks! ><
        obj.optical_flow = new OpticalFlow(obj.webcam_element, obj.webcam_canvas, obj.flow_xres, obj.flow_yres)

        # Additional options for dat.gui
        #obj.datg.add(obj.optical_flow.options, 'win_size',7,30).step(1)
        #obj.datg.add(obj.optical_flow.options, 'max_iterations',3,30).step(1)
        #obj.datg.add(obj.optical_flow.options, 'epsilon',0.001,0.1).step(0.0025)
        #obj.datg.add(obj.optical_flow.options, 'min_eigen',0.001,0.01).step(0.0001)

        obj.state["webcam"] = true
        @loaded()

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

  if CoffeeGL.Context.profile.browser == "Chrome"
    obj.lq.add _loadWebcam

  obj.lq.add _loadVideo

  #obj.lq.add _genLoadAudio('/sound/long/long.mp3', obj.sounds_long, true)

  # Short sounds
  #for i in [0..5] 
  #  obj.lq.add _genLoadAudio('/sound/short/sound00' + i + '.mp3', obj.sounds_short, false)

  obj.lq.start()
    
  obj

module.exports =
  loadAssets : loadAssets
