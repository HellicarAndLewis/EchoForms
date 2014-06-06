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
        @loading_items.push Math.floor(Math.random() * @plane.getNumTris())

      console.log ( "Loaded: " + @lq.completed_items.length / @lq.items.length)

    b = () =>
      console.log "Loaded All"
      @state_ready = true

    @lq = new CoffeeGL.Loader.LoadQueue @, a, b

    self = @

    # Load the major video

    _loadVideo = new CoffeeGL.Loader.LoadItem () ->

      self.video_element = document.getElementById "video"
      self.video_element.preload = "auto"
      self.video_element.src = "/background.mp4"

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

    # Long sounds
    for i in [0..8] 
      @lq.add _genLoadAudio('/sound/long/sound00' + i + '.mp3', @sounds_long, true)

    # Short sounds
    for i in [0..7] 
      @lq.add _genLoadAudio('/sound/short/sound00' + i + '.mp3', @sounds_short, false)


    @lq.start()
    
  @

  
  # Playing audio when a triangle is selected if it has a trigger

  playSound : () ->

    if @selected_tris in @sound_long_triggers
      if not @sound_long_playing
        @sounds_long[Math.floor(Math.random() * @sounds_long.length)].play()
        
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
    idc = 0
    tcs = [ {u:0.0, v:0.0}, {u:0.5, v:1.0}, {u:1.0, v:0.0} ]
    sstep = [0,1,2]
    ids = 0
  
    for i in [0..@plane_yres-1]

      ids = 0

      for j in [0..@plane_xres-1]

        @plane.t[idt++] = tcs[ids].u
        @plane.t[idt++] = tcs[ids].v
        
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
        
        np.x = (@plane.t[idt] * 2.0 ) - 1 
        np.y = (@plane.t[idt+1] * 2.0) - 1

        rotm.multVec np

        @plane.t[idt++] = (np.x + 1) / 2
        @plane.t[idt++] = (np.y + 1) / 2

  # We do this in CPU space as there is no real speed issue
  morphPlane : () ->

    if not (@mouse_over and @mouse_pressed)
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
    @state_ready = false
    @loading_items = []

    # Plane
    @plane_yres = 9
    @plane_xres = 21
    @setupPlane()
    @video_node = new CoffeeGL.Node @plane
    @face_node = new CoffeeGL.Node @plane_face

    # Intersections
    @ray = new CoffeeGL.Vec3 0,0,0
    @intersect_prev = new CoffeeGL.Vec3 0,0,0
    @intersect = new CoffeeGL.Vec3 0,0,0
    @selected_tris = @selected_tris_prev = -1

    # Warp parameters

    @warp =
      exponent  : 2
      force    : 0.004
      range     : 2.0
      falloff_factor : 1.0
      springiness : 0.0068
      springiness_exponent : 2.0
      rot_speed : 4.0
      spring_damping : 0.91

    # Sound parameters
    @sound_long_playing = false
    @sound_on = false
    @sound_long_triggers = []
    @sound_short_triggers = []

    for i in [0..55]
      @sound_long_triggers.push Math.floor( Math.random() * @plane.getNumTris())

    for i in [0..100]
      @sound_short_triggers.push Math.floor( Math.random() * @plane.getNumTris())


    # Pre brew with correct dynamic flags
    @video_node.brew {position_buffer_access : GL.DYNAMIC_DRAW, texcoord_buffer_access : GL.DYNAMIC_DRAW} 
    @face_node.brew {position_buffer_access : GL.DYNAMIC_DRAW, colour_buffer_access: GL.DYNAMIC_DRAW} 

    @geomTrans CoffeeGL.Context.width, CoffeeGL.Context.height

    r0 = new CoffeeGL.Request('/basic_texture.glsl')
    r0.get (data) =>
      @shader = new CoffeeGL.Shader(data)
      @video_node.add @shader
     
    r1 = new CoffeeGL.Request('/face.glsl')
    r1.get (data) =>
      @shader_face = new CoffeeGL.Shader(data)
      @face_node.add @shader_face

    @camera = new CoffeeGL.Camera.PerspCamera()
    @camera.pos.z = 3.8
    @camera.setViewport CoffeeGL.Context.width, CoffeeGL.Context.height

    @video_node.add @camera
    @face_node.add @camera
   
    @t = new CoffeeGL.TextureBase({ width: 240, height: 134 })

    #GL.enable(GL.CULL_FACE)
    #GL.cullFace(GL.BACK)
    #GL.enable(GL.DEPTH_TEST)

    GL.enable(GL.BLEND)
    GL.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)

    # Asset Loading
    @video_ready = false
    @sounds_long = []
    @sounds_short = []
    @loadAssets()

    # GUI Setup

    datg = new dat.GUI()
    datg.remember(@)

    datg.add(@warp,'exponent',1.0,5.0)
    datg.add(@warp,'force',0.0001,0.01)
    datg.add(@warp,'range',0.1,5.0)
    datg.add(@warp,'springiness', 0.0001, 0.01)
    datg.add(@warp,'spring_damping', 0.1, 1.0)
    datg.add(@warp,'rot_speed', 0.01, 10.0)
    datg.add(@,'sound_on')
    
    # Setup mouse listener
    CoffeeGL.Context.mouseMove.add @mouseMoved, @
    CoffeeGL.Context.mouseOut.add @mouseOut, @
    CoffeeGL.Context.mouseOver.add @mouseOver, @
    CoffeeGL.Context.mouseDown.add @mouseDown, @
    CoffeeGL.Context.mouseUp.add @mouseUp, @

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
              @plane_face.c[idc * 12 + k ] += 0.08
            else
              @plane_face.c[idc * 12 + k ] -= 0.01

            if @plane_face.c[idc * 12 + k ] <= 0
              @plane_face.c[idc * 12 + k ] = 0

            if @plane_face.c[idc * 12 + k ] >= 1.0
              @plane_face.c[idc * 12 + k ] = 1.0
        idc++ 

  updateLoading : (dt) ->

    if @shader_face?
      @shader_face.bind()
      @shader_face.setUniform1f "uClockTick", CoffeeGL.Context.contextTime 
      @shader_face.setUniform1f "uHighLight", 1.0

    #if Math.random() > 0.1
    for i in @loading_items
      @updateFaceHighlight i

    @face_node.rebrew( { colour_buffer: 0})


  updateActual : (dt) ->

    @t.update @video_element if @video_ready
    if @shader?
      @shader.bind()
      @shader.setUniform1f "uClockTick", CoffeeGL.Context.contextTime 

    if @shader_face?
      @shader_face.bind()
      @shader_face.setUniform1f "uClockTick", CoffeeGL.Context.contextTime 

    @morphPlane()
    @copyToFace()

    @updateFaceHighlight(@selected_tris)

    @video_node.rebrew( { position_buffer : 0 , texcoord_buffer : 0})
    @face_node.rebrew( { position_buffer : 0 , colour_buffer: 0})
    @springBack()
    @playSound() if @sound_on


  update : (dt) ->  
    if @state_ready
      @updateActual()
    else
      @updateLoading()

  # Loaded and running
  drawActual : () ->
    GL.clearColor(0.15, 0.15, 0.15, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)
    @video_node.draw()
    @face_node.draw()

  # draw the loading screen
  drawLoading : () ->  
    GL.clearColor(0.15, 0.15, 0.15, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)
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
    @videoNodeTrans CoffeeGL.Context.width, CoffeeGL.Context.height

  mouseMoved : (event) ->
    x = event.mouseX # Why is this off? :S
    y = event.mouseY 

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


  mouseOver : (event) ->
    @mouse_over = true

  mouseOut : (event) ->
    @mouse_over = false


  mouseDown : (event) ->
    @mouse_pressed = true

  mouseUp : (event) ->
    @mouse_pressed = false
    @intersect_prev.set 0,0,0
    @intersect.set 0,0,0 

# Initial Size of the Canvas, pre WebGL
canvas = document.getElementById 'webgl-canvas'
canvas.width = window.innerWidth
canvas.height = window.innerHeight

kk = new Kaliedoscope()
cgl = new CoffeeGL.App('webgl-canvas', kk, kk.init, kk.draw, kk.update)

window.addEventListener('resize', kk.resize, false) if window?


