###
Kaliedoscope Test

http://stackoverflow.com/questions/13739901/vertex-kaleidoscope-shader

###


class Kaliedoscope

  # Simple loading queue - We need to add some funky functions for the loading of
  # faces and things
  loadAssets : () ->
  
    a = () -> 
      console.log ( "Loaded: " + @completed_items.length / @items.length)

    b = () ->
      console.log "Loaded All"

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
    _genLoadAudio = (audio_url) ->

      _loadAudioSample = new CoffeeGL.Loader.LoadItem () ->
        sound = new Howl {
          urls: [audio_url]
          onload : () =>
            self.sounds.push sound
            sound.playing = false
            @loaded()

          onplay : () ->
            @playing  = true

          onend : () ->
            @playing  = false
        }

        return _loadAudioSample

    @lq.add _loadVideo

    for i in [0..30] 
      if i > 9
        @lq.add _genLoadAudio('/sound/sound0' + i + '.mp3')
      else
        @lq.add _genLoadAudio('/sound/sound00' + i + '.mp3')

    @lq.start()
    
  @

  # Playing audio on roll over
  playSound : () ->
    if not @mouse_over
      return

    for sound in @sounds
      if sound.playing
        sound.fadeOut()

    x = Math.floor( ((@ray.x + 3.0) / 6.0) * 10)
    y = Math.floor( ((@ray.y + 3.0) / 6.0) * 3)

    choice = x + y

    if choice >= 0 && choice < @sounds.length
      if @sound_current != choice
        @sounds[choice].play()
        @sound_current = choice



  # Setup the plane
  setupPlane : () ->
  

    # Alter the texture co-ordinates to create a Kaliedoscope
    # Essentially, each triangle covers the entire texture
    # with each shared edge reflecting

    # Also alter to make the hexagons more regular

    # Appears to be a bug at certain resolutions of the hex plane where the texture
    # isnt mapped right? :S
    @plane = new CoffeeGL.PlaneHexagonFlat @plane_xres, @plane_yres 

    idt = 0
    idc = 0
    tcs = [ {u:0.0, v:0.0}, {u:0.5, v:1.0}, {u:1.0, v:0.0} ]
    sstep = [0,1,2]
    ids = 0
  
    for i in [0..@plane_yres-1]

      ids = 0

      for j in [0..@plane_xres-1]

        # Spider on Crack function

        #r = Math.random()

        #if r > 0.7
        #  @plane.t[idt++] = tcs[ids].u * (1.0 - r)
        #  @plane.t[idt++] = tcs[ids].v * (1.0 - r)
        #else

        @plane.t[idt++] = tcs[ids].u
        @plane.t[idt++] = tcs[ids].v
        ids++

        if ids > 2
          ids = 0

        # We use the colour part as the force part
        @plane.c[idc++] = 0
        @plane.c[idc++] = 0
        @plane.c[idc++] = 0
        @plane.c[idc++] = 0

    @plane_base = JSON.parse(JSON.stringify(@plane)) # CoffeeGL Clone doesnt quite work
    

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
        

        # Create a force on the vertices

        #if dd < @warp.range

        #  falloff = dd / @warp.range * @warp.falloff_factor
          #Math.pow(dir_dist,@warp.exponent) * @warp.factor * falloff)
          #tp.add( dir.multScalar(dir_dist * 0.001))
         

        if force_dist > 0.001

          if dd < @warp.range

            force.normalize()
            force.multScalar(0.01 * 1.0/(dd * dd) )

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
        #Math.pow(spring_dist,@warp.springiness_exponent) * @warp.springiness
        spring_force.multScalar(spring_dist * 0.01) 

    
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


  # Transformation for the geometry based on width and height
  videoNodeTrans : (w=1,h=1) ->

    @video_node.matrix.identity()
    @video_node.matrix.rotate  new CoffeeGL.Vec3(1,0,0), CoffeeGL.PI / 2

    xfactor = 2.0 * w / h
    yfactor = 2.0

    @video_node.matrix.scale new CoffeeGL.Vec3 xfactor,1,yfactor

 
  init : () ->
    
    # Plane
    @plane_yres = 9
    @plane_xres = 21
    @setupPlane()
    @video_node = new CoffeeGL.Node @plane

    # Intersections
    @ray = new CoffeeGL.Vec3 0,0,0
    @intersect_prev = new CoffeeGL.Vec3 0,0,0
    @intersect = new CoffeeGL.Vec3 0,0,0

    # Warp parameters

    @warp =
      exponent  : 1.4
      factor    : 2.6
      range     : 1.0
      falloff_factor : 1.0
      springiness : 0.3
      springiness_exponent : 2.0
      rot_speed : 4.0
      spring_damping : 0.92

    # Sound parameters
    @sound_current = -1
    @sound_on = false

    # Pre brew with correct dynamic flags
    @video_node.brew {position_buffer_access : GL.DYNAMIC_DRAW, texcoord_buffer_access : GL.DYNAMIC_DRAW} 

    @videoNodeTrans CoffeeGL.Context.width, CoffeeGL.Context.height

    r0 = new CoffeeGL.Request('/basic_texture.glsl')
    r0.get (data) =>
      @shader = new CoffeeGL.Shader(data)
      #@video_node.add @shader
      @shader.bind()
      @shader.setUniform3v "uMouseRay", new CoffeeGL.Vec3 0,0,0

    @camera = new CoffeeGL.Camera.PerspCamera()
    @camera.pos.z = 4.8
    @camera.setViewport CoffeeGL.Context.width, CoffeeGL.Context.height

    @video_node.add @camera
   
    @t = new CoffeeGL.TextureBase({ width: 240, height: 134 })

    GL.enable(GL.CULL_FACE)
    GL.cullFace(GL.BACK)
    GL.enable(GL.DEPTH_TEST)


    # Asset Loading
    @video_ready = false
    @sounds = []
    @loadAssets()


    # GUI Setup

    datg = new dat.GUI()
    datg.remember(@)

    datg.add(@warp,'exponent',1.0,5.0)
    datg.add(@warp,'factor',0.001,10.0)
    datg.add(@warp,'range',0.1,5.0)
    datg.add(@warp,'falloff_factor',0.01,10.0)
    datg.add(@warp,'springiness', 0.01, 5.0)
    datg.add(@warp,'springiness_exponent', 0.1, 5.0)
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

  update : (dt) ->
    
    @t.update @video_element if @video_ready

    @shader.setUniform3v "uMouseRay", @ray if @shader?

    @morphPlane()

    @video_node.rebrew( { position_buffer : 0 , texcoord_buffer : 0})
  
    @springBack()

    @playSound() if @sound_on

  draw : () ->
    
    GL.clearColor(0.15, 0.15, 0.15, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

    @video_node.draw()

  resize : () =>
    CoffeeGL.Context.resizeCanvas window.innerWidth, window.innerHeight
    @camera.setViewport CoffeeGL.Context.width, CoffeeGL.Context.height
    @videoNodeTrans CoffeeGL.Context.width, CoffeeGL.Context.height

  mouseMoved : (event) ->
    x = event.mouseX
    y = event.mouseY

    @intersect_prev.copyFrom @intersect 
    #@ray = @camera.castRay x,y

    #intersect_depth = CoffeeGL.Math.rayPlaneIntersect new CoffeeGL.Vec3(0,0,0), new CoffeeGL.Vec3(0,0,1), @camera.pos, @ray

    #@intersect = CoffeeGL.Vec3.multScalar @ray, intersect_depth
    #@intersect.add @camera.pos

    @rotateTexCoords()
    
    @intersect.set 0,0,0
    
    index = CoffeeGL.Math.screenNodeHitTest(x,y,@camera,@video_node,@intersect)
    if index != -1
      console.log index


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


