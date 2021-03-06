###
Kaliedoscope Test

http://stackoverflow.com/questions/13739901/vertex-kaleidoscope-shader

###


class Kaliedoscope

  # Simple loading queue - We need to add some funky functions for the loading of
  # faces and things
  loadAssets : () ->

  
    a = () =>

      for i in [0..10]
        tt =  Math.floor(Math.random() * @colour_palette.length)

        item =
          target : @colour_palette[tt]
          colour : new CoffeeGL.Colour.RGBA.BLACK()
          idx : Math.floor(Math.random() * @plane.getNumTris())

        @loading_items.push item

      console.log ( "Loaded: " + @lq.completed_items.length / @lq.items.length)

    b = () =>
      console.log "Loaded All"
      @state_loaded = true


    @lq = new CoffeeGL.Loader.LoadQueue @, a, b

    self = @
    # Load the major video

    _loadVideo = new CoffeeGL.Loader.LoadItem () ->

      self.video_element = document.getElementById "video"
      self.video_element.preload = "auto"
      self.video_element.src = "/H&L-Lexus-Edit01-final01.mp4"

      self.video_element.addEventListener "ended", () ->
        self.video_element.currentTime = 0
        self.video_element.play()
      ,false

      # This is a cheat to get the video lopping as nothing else works ><
      # Actually, a proper server link nginx works fine. Its to do with partial downloads
      self.video_element.addEventListener "timeupdate", () ->
        #console.log self.video_element.currentTime
        if self.video_element.currentTime > 53 
          self.video_element.pause()
          self.video_element.currentTime = 0
          self.video_element.play()
          return
      ,false

      self.video_element.oncanplay = (event) =>
        # This play pause stuff is needed to get around events not firing ><
        if not self.video_ready
          #self.video_element.play()
          #self.video_element.pause()
          #self.video_element.currentTime = 0
          self.video_element.play()
          self.t.update self.video_element
          self.video_node.add self.t
          self.video_ready = true

          @loaded()
          console.log "Video Loaded"

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
            @playing  = true
            if long
              self.sound_long_playing = true

          onend : () ->
            @playing  = false
            if long
              self.sound_long_playing = false
        }

        return _loadAudioSample

  
    @lq.add _loadVideo
  
    @lq.add _genLoadAudio('/sound/long/Lexus.mp3', @sounds_long, true)

    # Short sounds
    for i in [0..5] 
      @lq.add _genLoadAudio('/sound/short/sound00' + i + '.mp3', @sounds_short, false)

    @lq.start()
    
  @

  
  # Playing audio when a triangle is selected if it has a trigger

  playSound : () ->

    #if @selected_tris in @sound_long_triggers
    #  if not @sound_long_playing
    #    @sounds_long[Math.floor(Math.random() * @sounds_long.length)].play()
        
    if @selected_tris != @selected_tris_prev
      if @selected_tris in @sound_short_triggers
        @sounds_short[Math.floor(Math.random() * @sounds_short.length)].play()


  # Setup the plane
  setupPlane : () ->
  

    # Alter the texture co-ordinates to create a Kaliedoscope
    # Essentially, each triangle covers the entire texture
    # with each shared edge reflecting

    # Also alter to make the hexagons more regular

    # Appears to be a bug at certain resolutions of the hex plane where the texture
    # isnt mapped right? :S
    @plane = new CoffeeGL.PlaneHexagonFlat @plane_xres, @plane_yres
    @plane_face = new CoffeeGL.PlaneHexagonFlat @plane_xres, @plane_yres, false

    idt = 0
    idp = 0
    idc = 0
    tcs = [ {u:0.0, v:0.0}, {u:0.5, v:1.0}, {u:1.0, v:0.0} ]
    sstep = [0,1,2]
    ids = 0
  
    for i in [0..@plane_yres-1]

      ids = 0

      for j in [0..@plane_xres-1]

        # A little noise to offset the tex coords
        tx = (2.0 * Math.random() - 1)
        ty = (2.0 * Math.random() - 1)

        @plane.t[idt++] = tcs[ids].u + ( @noise.simplex2(tx,ty) * 0.25)
        @plane.t[idt++] = tcs[ids].v + ( @noise.simplex2(tx,ty) * 0.25)
        
        @plane.p[idp++] += (@noise.simplex2(tx,ty) * 0.02)
        idp++
        @plane.p[idp++] += (@noise.simplex2(tx,ty) * 0.02)


        ids++

        if ids > 2
          ids = 0

        # We use the colour part as the force part
        for i in [0..3]
          @plane.c[idc++] = 0

    @plane_base = JSON.parse(JSON.stringify(@plane)) # CoffeeGL Clone doesnt quite work

    # Set the colours of plane_face to zeroes
    
    idc = 0
   
    for i in [0..@plane_yres-1]
      for j in [0..@plane_xres-1]
        for k in [0..11]
            @plane_face.c[idc * 12 + k ] = 0
        idc++
  

  # when we mvoe the mouse, lets rotate the tex coords as well
  rotateTexCoords : () ->

    np = new CoffeeGL.Vec3 0,0,0
    idt = 0

    rotm = new CoffeeGL.Matrix4()
    rotm.rotate new CoffeeGL.Vec3(0,0,1), 0.001 * @warp.rot_speed

    for i in [0..@plane_yres-1]
      for j in [0..@plane_xres-1]
        
        tx = (Math.random() * 2.0 -1) * 0.1
        ty = (Math.random() * 2.0 -1) * 0.1

        noize = @noise.simplex2 @intersect.x + tx, @intersect.y + ty

        np.x = (@plane.t[idt] * 2.0 ) - 1 
        np.y = (@plane.t[idt+1] * 2.0) - 1

        rotm.multVec np

        @plane.t[idt++] = (np.x + 1) / 2
        @plane.t[idt++] = (np.y + 1) / 2


  # using some noise apply some random force
  naturalForce : () ->
    np = new CoffeeGL.Vec3 0,0,0
    idt = 0
    idc = 0
    for i in [0..@plane_yres-1]
      for j in [0..@plane_xres-1]
        if Math.random() > @warp.natural_rate
          np.x = @plane.p[idt++]
          np.y = @plane.p[idt++]
          np.z = @plane.p[idt++]

          #np.add @intersect

          noize = @noise.simplex2 np.x * 1.5, np.y * 1.5

          @plane.c[idc+1] += noize * @warp.natural_force
        idc += 4


  # We do this in CPU space as there is no real speed issue
  morphPlane : () ->

    if not @mouse_pressed
      return

    idt = 0 
    idc = 0
    np = new CoffeeGL.Vec3 0,0,0

    inv =  CoffeeGL.Matrix4.invert @video_node.matrix

    for i in [0..@plane_yres-1]
      for j in [0..@plane_xres-1]

        np.x = @plane.p[idt++]
        np.y = @plane.p[idt++]
        np.z = @plane.p[idt++]

        @video_node.matrix.multVec(np)

        force = CoffeeGL.Vec3.sub(@intersect, @intersect_prev)
        force_dist = @intersect.dist @intersect_prev

        dd = np.dist @intersect
      
        if force_dist > 0.01

          if dd < @warp.range

            force.normalize()
            force.multScalar(@warp.force * 1.0 / Math.pow(dd,@warp.exponent) )

            np.x = force.x
            np.y = force.y
            np.z = 0

            inv.multVec np

            # Commit this new force
            @plane.c[idc] += np.x
            @plane.c[idc+1] += np.y
            @plane.c[idc+2] += np.z
            @plane.c[idc+3] = 0

        idc += 4
    @

  # Spring back to where we started
  springBack : () ->

    idt = 0
    idc = 0

    np = new CoffeeGL.Vec3 0,0,0
    bp = new CoffeeGL.Vec3 0,0,0
    ff = new CoffeeGL.Vec3 0,0,0

    for i in [0..@plane_yres-1]
      for j in [0..@plane_xres-1]

        np.x = @plane.p[idt]
        np.y = @plane.p[idt+1]
        np.z = @plane.p[idt+2]

        bp.x = @plane_base.p[idt]
        bp.y = @plane_base.p[idt+1]
        bp.z = @plane_base.p[idt+2]

        ff.x = @plane.c[idc]
        ff.y = @plane.c[idc+1]
        ff.z = @plane.c[idc+2]

        spring_force = CoffeeGL.Vec3.sub bp, np
        spring_dist = bp.dist np

        spring_force.normalize()
      
        spring_force.multScalar(spring_dist * @warp.springiness) 

        # Resolve the forces - spring and mouse
        ff.add spring_force

        ff.multScalar @warp.spring_damping

        @plane.c[idc] = ff.x
        @plane.c[idc+1] = ff.y
        @plane.c[idc+2] = ff.z

        @plane.p[idt] = np.x + ff.x
        @plane.p[idt+1] = np.y + ff.y
        @plane.p[idt+2] = np.z + ff.z
    
        idt += 3
        idc += 4

  # Copy from the plane to the plane_face to keep things as close as possible :S

  copyToFace : () ->
    idp = 0
    for i in [0..@plane.indices.length-1]
      idx = @plane.indices[i]
      for j in [0..2]
        @plane_face.p[ idp++ ] = @plane.p[idx * 3 + j]

  # Transformation for the geometry based on width and height
  geomTrans : (w=1,h=1) ->

    @video_node.matrix.identity()
    @video_node.matrix.rotate  new CoffeeGL.Vec3(1,0,0), CoffeeGL.PI / 2

    xfactor = 2.0 * w / h
    yfactor = 2.0

    @video_node.matrix.scale new CoffeeGL.Vec3 xfactor,1,yfactor

    @face_node.matrix.copyFrom @video_node.matrix


  init : () ->

    # State
    if not @state_ready?
      @state_ready = false
    
    # Check to see if we've already loaded things
    if not @state_loaded?
      @state_loaded = false
    
      @loading_items = []
      @loading_timeout = 0
      @ready_fade_in = 0
      @loading_time_limit = 3
      @ready_fade_time = 3

    # Noise
    @noise = new CoffeeGL.Noise.Noise()
    @noise.setSeed(Math.random())

    # Colours
    if not @colour_palette?
      @colour_palette = [ new CoffeeGL.Colour.RGBA(31,169,225),  
        new CoffeeGL.Colour.RGBA(34,54,107),
        new CoffeeGL.Colour.RGBA(240,77,35), 
        new CoffeeGL.Colour.RGBA(228,198,158), 
        new CoffeeGL.Colour.RGBA(195,206,207) ]
  
    # Plane
    #if not @plane
    @plane_yres = 7
    @plane_xres = 15
    @setupPlane()
    @video_node = new CoffeeGL.Node @plane
    @face_node = new CoffeeGL.Node @plane_face

    # Pre brew with correct dynamic flags
    @video_node.brew {position_buffer_access : GL.DYNAMIC_DRAW, texcoord_buffer_access : GL.DYNAMIC_DRAW} 
    @face_node.brew {position_buffer_access : GL.DYNAMIC_DRAW, colour_buffer_access: GL.DYNAMIC_DRAW} 

    @geomTrans CoffeeGL.Context.width, CoffeeGL.Context.height

    # Load shaders seperately as they are important to the context
    r2 = new CoffeeGL.Request('/basic_texture.glsl')
    r2.get (data) =>
      @shader = new CoffeeGL.Shader(data)
    
    r3 = new CoffeeGL.Request('/face.glsl')
    r3.get (data) =>
      @shader_face = new CoffeeGL.Shader(data)
      @shader_face.bind()
      @shader_face.setUniform1f "uAlphaScalar", @highLight.alpha_scalar
     

    # Intersections
    @ray = new CoffeeGL.Vec3 0,0,0
    @intersect_prev = new CoffeeGL.Vec3 0,0,0
    @intersect = new CoffeeGL.Vec3 0,0,0
    @selected_tris = @selected_tris_prev = -1

    # Warp parameters
    @warp =
      exponent  : 2
      force    : 0.004 + (Math.random() * 0.001) 
      range     : 2.0 + (Math.random() * 0.5) 
      falloff_factor : 1.0
      springiness : 0.0019 + (Math.random() * 0.01) 
      springiness_exponent : 2.0
      rot_speed : 4.0
      spring_damping : 0.26 + (Math.random() * 0.5) 
      natural_rate : 0.9
      natural_force : 0.002 

    # hightlight parameters
    @highLight = 
      speed_in : 0.1 + (-0.01 + Math.random() * 0.02) 
      speed_out : 0.009 + (Math.random() * 0.01) 
      alpha_scalar : 0.24 + (Math.random() * 0.01) 

    # Sound parameters
    @sound_long_playing = false
    @sound_on = true
    @sound_short_triggers = []

    if not @state_loaded
      @sounds_long = []
      @sounds_short = []

    for i in [0..100]
      @sound_short_triggers.push Math.floor( Math.random() * @plane.getNumTris())

    #if not @camera?
    @camera = new CoffeeGL.Camera.PerspCamera()
    @camera.pos.z = 3.8
    @camera.near = 0.001
    @camera.far = 8.0
    @camera.setViewport CoffeeGL.Context.width, CoffeeGL.Context.height

    @video_node.add @camera
    @face_node.add @camera
    
    #if not @t?
    @t = new CoffeeGL.TextureBase({ width: 256, height: 256 })

    #GL.enable(GL.CULL_FACE)
    #GL.cullFace(GL.BACK)
    #GL.enable(GL.DEPTH_TEST)

    GL.enable(GL.BLEND)
    GL.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)

    # Asset Loading
    if not @video_ready? # Don't reload video if its already loaded
      @video_ready = false
    else
      @video_element.play()
      @video_node.add @t
    
    if not @state_loaded
      @loadAssets()

    # GUI Setup

    ###
    datg = new dat.GUI()
    datg.remember(@)

    datg.add(@warp,'exponent',1.0,5.0)
    datg.add(@warp,'force',0.0001,0.01)
    datg.add(@warp,'range',0.1,5.0)
    datg.add(@warp,'springiness', 0.0001, 0.01)
    datg.add(@warp,'spring_damping', 0.1, 1.0)
    datg.add(@warp,'rot_speed', 0.01, 10.0)
    datg.add(@warp,'natural_rate', 0.1, 1.0)
    datg.add(@warp,'natural_force', 0.0001, 0.01)
    datg.add(@,'sound_on')
    datg.add(@highLight,'speed_in', 0.001, 0.1)
    datg.add(@highLight,'speed_out', 0.001, 0.1)
    datg.add(@highLight, 'alpha_scalar',0.1,1.0)

    datg.add(@dof_params,'focal_range', 0.001, 1.0)
    datg.add(@dof_params, 'focal_distance',0.1,10.0)
    ###

    # Setup mouse listener
    CoffeeGL.Context.mouseMove.add @mouseMoved, @
    CoffeeGL.Context.mouseOut.add @mouseOut, @
    CoffeeGL.Context.mouseOver.add @mouseOver, @
    CoffeeGL.Context.mouseDown.add @mouseDown, @
    CoffeeGL.Context.mouseUp.add @mouseUp, @

    # Setup touch listener
    #CoffeeGL.Context.touchSwipe.add @touchSwipe, @

    # Mouse states
    @mouse_over = false
    @mouse_pressed = false


  # Given a face, make it lighter
  updateFaceHighlight : (idx) ->
     # Update the colour buffer for selection
    idc = 0
    for i in [0..@plane_yres-1]
      for j in [0..@plane_xres-1]
        for k in [0..11]
            if idx == idc
              @plane_face.c[idc * 12 + k ] += @highLight.speed_in
            else
              @plane_face.c[idc * 12 + k ] -= @highLight.speed_out

            if @plane_face.c[idc * 12 + k ] <= 0
              @plane_face.c[idc * 12 + k ] = 0

            if @plane_face.c[idc * 12 + k ] >= 1.0
              @plane_face.c[idc * 12 + k ] = 1.0
        idc++ 

  # Update Face Colour - used in Loading -  stays loaded - colour

  updateFaceColour : (idx, colour) ->
    idc = 0
    for i in [0..@plane_yres-1]
      for j in [0..@plane_xres-1]
        for k in [0..2]
          if idx == idc
            @plane_face.c[idc * 12 + (k * 4) ] = colour.r
            @plane_face.c[idc * 12 + (k * 4) + 1] = colour.g
            @plane_face.c[idc * 12 + (k * 4) + 2] = colour.b
            @plane_face.c[idc * 12 + (k * 4) + 3] = colour.a
        idc++

  updateLoading : (dt) ->

    if @shader_face?
      @shader_face.bind()
      @shader_face.setUniform1f "uClockTick", CoffeeGL.Context.contextTime 
      @shader_face.setUniform1f "uAlphaScalar", 1.0

    #if Math.random() > 0.1
    for i in @loading_items

      tc = i.colour
      tt = i.target

      tc.r += @highLight.speed_in * tt.r if tc.r < tt.r
      tc.g += @highLight.speed_in * tt.g if tc.g < tt.g
      tc.b += @highLight.speed_in * tt.b if tc.b < tt.b
      tc.a += @highLight.speed_in * tt.a if tc.a < tt.a

      @updateFaceColour i.idx, tc

    @naturalForce()
     
    #@morphPlane()
    @copyToFace()
    
    @springBack()

    @face_node.rebrew( { position_buffer : 0, colour_buffer: 0})

  updateActual : (dt) ->

    @t.update @video_element if @video_ready
    if @shader?
      @shader.bind()
      @shader.setUniform1f "uClockTick", CoffeeGL.Context.contextTime 
      @shader.setUniform1f "uMasterAlpha", @ready_fade_in

    if @shader_face?
      @shader_face.bind()
      @shader_face.setUniform1f "uClockTick", CoffeeGL.Context.contextTime
      @shader_face.setUniform1f "uAlphaScalar", @highLight.alpha_scalar

    @naturalForce()
     
    @morphPlane()
    @copyToFace()

    @updateFaceHighlight(@selected_tris)

    @video_node.rebrew( { position_buffer : 0, texcoord_buffer : 0})
    @face_node.rebrew( { position_buffer : 0, colour_buffer: 0})
    @springBack()
    @playSound() if @sound_on


  update : (dt) -> 

    if @state_ready
      @ready_fade_in += (dt / 1000) / @ready_fade_time
      if @ready_fade_in > 1.0
        @ready_fade_in = 1.0

      @updateActual()
    else
      @updateLoading()
      @loading_timeout += dt/1000
      if @state_loaded and @loading_timeout > @loading_time_limit
        @state_ready = true
        credits = document.getElementById 'credits'
        credits.style.display = 'none'

    #if CoffeeGL.Context.ongoingTouches.length > 0
    #  @mouse_over = false

  # Loaded and running
  drawActual : () ->
    GL.clearColor(0.15, 0.15, 0.15, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

    @shader.bind()
    @video_node.draw()
    @shader_face.bind()
    @face_node.draw()

  # draw the loading screen
  drawLoading : () ->  
    GL.clearColor(0.15, 0.15, 0.15, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)
    if @shader_face?
      @shader_face.bind()
      @face_node.draw()

  # Main Draw Loop
  draw : () ->
    if @state_ready
      @drawActual()
    else
      @drawLoading()


  resize : () =>
    CoffeeGL.Context.resizeCanvas window.innerWidth, window.innerHeight
    @camera.setViewport CoffeeGL.Context.width, CoffeeGL.Context.height
    @geomTrans CoffeeGL.Context.width, CoffeeGL.Context.height

  
  interact : (x,y) ->
    @intersect_prev.copyFrom @intersect 
  
    @rotateTexCoords()
    
    @intersect.set 0,0,0

    @selected_tris_prev = @selected_tris  
    @selected_tris = CoffeeGL.Math.screenNodeHitTest(x,y,@camera,@video_node,@intersect)
  
    # Tidy this up - it sucks a bit ><
    if @shader?
      @shader.bind()
      if @selected_tris != -1
        #console.log index
        @shader.setUniform1f "uHighLight", 1.0
      else
        @shader.setUniform1f "uHighLight", 0.0

      @shader.setUniform3v "uMousePos", @intersect


    if @shader_face?
      @shader_face.bind()
      if @selected_tris != -1
        #console.log index
        @shader_face.setUniform1f "uHighLight", 1.0
      else
        @shader_face.setUniform1f "uHighLight", 0.0
        
      @shader_face.setUniform3v "uMousePos", @intersect
      @shader_face.setUniform1i "uChosenIndex", @selected_tris


  mouseMoved : (event) ->
    x = event.mouseX # Why is this off? :S
    y = event.mouseY 
    @interact(x,y)

    if @mouse_pressed and @sound_on
      if not @sounds_long[0].playing
        @sounds_long[0].play()
        @sounds_long[0].playing = true

  ###
  touchSwipe : (event) ->
    @mouse_over = true
    @mouse_pressed = true

    for touch in CoffeeGL.Context.ongoingTouches
      @interact touch.ppos.x, touch.ppos.y
  ###

  mouseOver : (event) ->
    #@mouse_over = true

  mouseOut : (event) ->
    #@mouse_over = false
    @selected_tris_prev = @selected_tris = -1

  mouseDown : (event) ->
    @mouse_pressed = true

  mouseUp : (event) ->
    @mouse_pressed = false
    @intersect_prev.set 0,0,0
    @intersect.set 0,0,0 

    if @sound_on
      @sounds_long[0].fadeOut(1.0)
      @sounds_long[0].playing = false

  # Called when we shutdown rendering
  shutdown : () ->

    # Remove triggers
    sound_short_triggers = []

    # Reset Video but keep it in context
    video = document.getElementById "video"
    video.pause()
    video.currentTime = 0

    # Destroy nodes - removing from the graphics card
    @video_node.washup()
    @face_node.washup()

    delete @video_node
    delete @face_node

    # Destroy the texure
    @t.washup()
    delete @t


# resize the credits div
credits_resize = () ->
  credits = document.getElementById 'credits'
  credits.style.left = (window.innerWidth / 2 - credits.clientWidth / 2) + 'px'
  credits.style.top = (window.innerHeight / 2 - credits.clientHeight / 2) + 'px'

window.notSupported = () ->
    
  $('#webgl-canvas').remove()
  $('#credits').append('<h3>Your browser does not support WebGL</h3><p>Visit <a href="http://get.webgl.org">get.webgl.org</a> to learn more.</p>')


# Initial Size of the Canvas, pre WebGL
canvas = document.getElementById 'webgl-canvas'
canvas.width = window.innerWidth
canvas.height = window.innerHeight

kk = new Kaliedoscope()

params = 
  canvas : 'webgl-canvas'
  context : kk
  init : kk.init
  draw : kk.draw
  update : kk.update
  error : window.notSupported
  delay_start : false
  shutdown : kk.shutdown

kaliedoscopeWebGL = new CoffeeGL.App(params)

###
keypressed = (event) ->
  if event.keyCode == 115
    kaliedoscopeWebGL.shutdown()
  else if event.keyCode == 103
    kaliedoscopeWebGL.startup()
###

#canvas.addEventListener "keypress", keypressed

window.addEventListener('resize', kk.resize, false) if window?
window.addEventListener('resize', credits_resize, false) if window?
credits_resize()

#kaliedoscopeWebGL.startup()




