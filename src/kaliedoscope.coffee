###
Echo Forms - Hellicar & Lewis
Coding - Benjamin Blundell @ section9.co.uk


http://stackoverflow.com/questions/13739901/vertex-kaleidoscope-shader

###

{loadAssets} = require './assets'


class Kaliedoscope  


  constructor : (@plane_xres, @plane_yres, @flow_xres, @flow_yres) ->
    @state =
      startup : true
      loaded : false
      webcam : false
      video : false
      youtube : false
      youtube_fetch : false

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
  morphPlane : (intersect, intersect_prev) ->

  
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

        force = CoffeeGL.Vec3.sub(intersect, intersect_prev)
        force_dist = intersect.dist intersect_prev

        dd = np.dist intersect
      
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
    #@plane_yres = 7
    #@plane_xres = 15
    @setupPlane()
    @video_node = new CoffeeGL.Node @plane
    @face_node = new CoffeeGL.Node @plane_face

    # Pre brew with correct dynamic flags
    @video_node.brew {position_buffer_access : GL.DYNAMIC_DRAW, texcoord_buffer_access : GL.DYNAMIC_DRAW} 
    @face_node.brew {position_buffer_access : GL.DYNAMIC_DRAW, colour_buffer_access: GL.DYNAMIC_DRAW} 

    @geomTrans CoffeeGL.Context.width, CoffeeGL.Context.height



    # Webcam Test Quad
    @webcam_node_draw = false
    @webcam_node = new CoffeeGL.Node new CoffeeGL.Quad()

    # Load shaders seperately as they are important to the context
    r2 = new CoffeeGL.Request('/kaliedoscope.glsl')
    r2.get (data) =>
      @shader = new CoffeeGL.Shader(data)
     
    r4 = new CoffeeGL.Request('/basic_texture.glsl')
    r4.get (data) =>
      @shader_basic = new CoffeeGL.Shader(data)
    
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

    @intersect_prev_optical = new CoffeeGL.Vec3 0,0,0
    @intersect_optical = new CoffeeGL.Vec3 0,0,0

    # Warp parameters
    @warp =
      exponent  : 2
      force    : 0.0012 + (Math.random() * 0.001) 
      range     : 1.0 + (Math.random() * 0.5) 
      falloff_factor : 1.0
      springiness : 0.065 + (Math.random() * 0.01) 
      springiness_exponent : 2.0
      rot_speed : 4.0
      spring_damping : 0.77 + (Math.random() * 0.15) 
      natural_rate : 0.9
      natural_force : 0.002 

    # hightlight parameters
    @highLight = 
      speed_in : 0.1 + (-0.01 + Math.random() * 0.02) 
      speed_out : 0.009 + (Math.random() * 0.01) 
      alpha_scalar : 0.24 + (Math.random() * 0.01) 

    # Webcam Parameters
    @webcam_params =
      fader : 0.0
      fade_duration : 3.0 # seconds
      fade_current_duration : 0 # seconds
      fade_target : 0
      fade_time : 60.0 # seconds
      fade_current_time : 0

    # Sound parameters
    @sound_long_playing = false
    @sound_on = false
    @sound_short_triggers = []

    if not @state["loaded"]
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
    @webcam_node.add @camera
    
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


    if not @state["loaded"]
      loadAssets @

    # Youtube Easter Egg Stuff

  
    # GUI Setup

    @datg = new dat.GUI()
    @datg.remember(@)

    @datg.add(@warp,'exponent',1.0,5.0)
    @datg.add(@warp,'force',0.0001,0.01)
    @datg.add(@warp,'range',0.1,5.0)
    @datg.add(@warp,'springiness', 0.0001, 0.1).step(0.0001)
    @datg.add(@warp,'spring_damping', 0.1, 1.0).step(0.001)
    @datg.add(@warp,'rot_speed', 0.01, 10.0)
    @datg.add(@warp,'natural_rate', 0.1, 1.0)
    @datg.add(@warp,'natural_force', 0.0001, 0.01)
    @datg.add(@,'sound_on')
    @datg.add(@highLight,'speed_in', 0.001, 0.1)
    @datg.add(@highLight,'speed_out', 0.001, 0.1)
    @datg.add(@highLight, 'alpha_scalar',0.1,1.0)
    @datg.add(@webcam_params, 'fader', 0.0, 1.0).step(0.01)
    @datg.add(@webcam_params, 'fade_time', 0, 600).step(1)
    @datg.add(@webcam_params, 'fade_duration', 0, 10).step(0.1)

    # More Youtube related stuff
    @youtube_element = document.getElementById "video_youtube"

    #yevent = @datg.add(@, 'youtube_url')
    #yevent.onFinishChange @submitYouTube()

    # Off by default
    dat.GUI.toggleHide();

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


  submitYouTube : (url) ->

    if @state["youtube_fetch"]
      return

    @state["youtube_fetch"] = true

    # Perform a get request and get me some data!    
    @state["youtube"] = false

    youtube_id = url.match(/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/ ]{11})/i)

    if not youtube_id?
      alert "Youtube Link is incorrect."
      @state["youtube_fetch"] = false
      textbox = document.getElementById "youtube-textbox"
      $('#submit-button').button('reset')

      return

    # We have new video here so we must re-address our texture
    # @video_element.pause()
    @youtube_element.src = 'https://dejima.section9.co.uk/youtube?id=' + encodeURIComponent(youtube_id[0])

    @youtube_element.addEventListener "ended", () ->
      @youtube_element.currentTime = 0
      @youtube_element.play()
    ,false

    @youtube_element.oncanplay = (event) =>
      # Resize the texture
      
      @video_node.remove @t
      @t.washup()
      
      @t = new CoffeeGL.TextureBase({ width: @youtube_element.videoWidth, height:  @youtube_element.videoHeight })
      @video_node.add @t
      @youtube_element.play()
      @t.update @youtube_element
      @state["youtube"] = true
      @state["youtube_fetch"] = false

      # Remove our main panel
      credits = document.getElementById 'credits'
      credits.style.display = 'none'

      


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


  updateFader : (dt) ->

    if @webcam_params.fade_current_time >= @webcam_params.fade_time
      
      if @webcam_params.fade_current_duration == 0
        if @webcam_params.fader >= 0.5
          @webcam_params.fade_target = 0.0
        else
          @webcam_params.fade_target = 1.0
  
        @webcam_params.tween = new CoffeeGL.Interpolation @webcam_params.fader,  @webcam_params.fade_target

      @webcam_params.fade_current_duration += (dt / 1000)
    
      @webcam_params.fader = @webcam_params.tween.set(@webcam_params.fade_current_duration / @webcam_params.fade_duration)
      
      # Checks on the fader
      #@webcam_params.fader = 1.0 if @webcam_params.fader > 1.0 
      #@webcam_params.fader = 0.0 if @webcam_params.fader < 1.0 

      if @webcam_params.fade_current_duration >= @webcam_params.fade_duration
        # we should be done

        @webcam_params.fade_current_time = 0
        @webcam_params.fade_dist = 0
        @webcam_params.fade_current_duration = 0


    else
      @webcam_params.fade_current_time += (dt / 1000)

  updateWebcam : (dt) ->
    @optical_flow.update(dt) 

    # Now look at these points that are moving and perform some interaction
    active_flow = @optical_flow.active_intersections()

    max_diff = 0
    max_now = new CoffeeGL.Vec2 0,0
    cur_now = new CoffeeGL.Vec2 0,0
    prev_now = new CoffeeGL.Vec2 0,0


    for i in active_flow
      now = i[0]
      prev = i[1]

      # Flip so its properly mirrored left right
      now[0] = @webcam_element.videoWidth - now[0]
      prev[0] = @webcam_element.videoWidth - prev[0]

      px = prev[0] / @webcam_element.videoWidth * CoffeeGL.Context.width
      py = prev[1] / @webcam_element.videoHeight * CoffeeGL.Context.height

      cx = now[0] / @webcam_element.videoWidth * CoffeeGL.Context.width
      cy = now[1]/ @webcam_element.videoHeight * CoffeeGL.Context.height

      CoffeeGL.Math.screenNodeHitTest(px,py,@camera,@video_node,@intersect_prev_optical)
      CoffeeGL.Math.screenNodeHitTest(cx,cy,@camera,@video_node,@intersect_optical)

      @morphPlane(@intersect_optical, @intersect_prev_optical)

      # Keep a record of the biggest different and use that as our triangle hightlight
      cur_now.x = now[0] / @webcam_element.videoWidth * CoffeeGL.Context.width
      cur_now.y = now[1] / @webcam_element.videoHeight * CoffeeGL.Context.height

      prev_now.x = prev[0] / @webcam_element.videoWidth * CoffeeGL.Context.width
      prev_now.y = prev[1] / @webcam_element.videoHeight * CoffeeGL.Context.height

      dd = cur_now.dist prev_now
      if  dd > max_diff
        max_diff = dd
        max_now.copyFrom cur_now

    if max_diff > 6.5 # This stops small movements repeatedly doing bad things
      @interact max_now.x, max_now.y      


  updateActual : (dt) ->

    # Shader and video updates

    if @state["youtube"]
      @t.update @youtube_element
    else if @state["video"]
      @t.update @video_element 

    @wt.update @webcam_element if @webcam_ready

    if @shader?
      @shader.bind()
      @shader.setUniform1f "uClockTick", CoffeeGL.Context.contextTime 
      @shader.setUniform1f "uMasterAlpha", @ready_fade_in

    if @shader_face?
      @shader_face.bind()
      @shader_face.setUniform1f "uClockTick", CoffeeGL.Context.contextTime
      @shader_face.setUniform1f "uAlphaScalar", @highLight.alpha_scalar

    @naturalForce()
    
    # Work with mouse interactions

    if @mouse_pressed
      @morphPlane(@intersect, @intersect_prev)
    
    @copyToFace()

    @updateFaceHighlight(@selected_tris)

    @video_node.rebrew( { position_buffer : 0, texcoord_buffer : 0})
    @face_node.rebrew( { position_buffer : 0, colour_buffer: 0})
    @springBack()
    
    #@playSound() if @sound_on

    # Update the jsfeat points if we are using the webcam
    if @state["webcam"]
      @updateWebcam(dt)
      @updateFader(dt)
  

  update : (dt) -> 

    if @state["loaded"] and @state["video"]
    
      @ready_fade_in += (dt / 1000) / @ready_fade_time
      if @ready_fade_in > 1.0
        @ready_fade_in = 1.0

      @updateActual(dt)
    else
      @updateLoading(dt)
      @loading_timeout += dt/1000
      ###
      if @state["loaded"] and @loading_timeout > @loading_time_limit
        @state_ready = true
        credits = document.getElementById 'credits'
        credits.style.display = 'none'
      ###


  # Loaded and running
  drawActual : () ->
    GL.clearColor(0.15, 0.15, 0.15, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

    @shader.bind()
    @shader.setUniform1i "uSamplerWebcam", 1
    @shader.setUniform1f "uWebcamFader", @webcam_params.fader
    @video_node.draw()
    @shader_face.bind()
    @face_node.draw()

    # Draw the debug webcam view
    if @webcam_node_draw
      @shader_basic.bind()
      GL.disable(GL.BLEND)
      @webcam_node.draw()
      GL.enable(GL.BLEND)

  # draw the loading screen
  drawLoading : () ->  
    GL.clearColor(0.15, 0.15, 0.15, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)
    if @shader_face?
      @shader_face.bind()
      @face_node.draw()

  # Main Draw Loop
  draw : () ->
    if @state["loaded"] and @state["video"]
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

    @wt.washup()
    delete @wt


# resize the credits div
credits_resize = () ->
  credits = document.getElementById 'credits'
  credits.style.left = (window.innerWidth / 2 - credits.clientWidth / 2) + 'px'
  credits.style.top = (window.innerHeight / 2 - credits.clientHeight / 2) + 'px'

window.notSupported = () ->
    
  $('#webgl-canvas').remove()
  $('#credits').append('<h3>Your browser does not support WebGL</h3><p>Visit <a href="http://get.webgl.org">get.webgl.org</a> to learn more.</p>')


# Initial Size of the Canvas, pre Web
canvas = document.getElementById 'webgl-canvas'
canvas.width = window.innerWidth
canvas.height = window.innerHeight

# Function to read URL parameters
QueryString = () -> 

  query_string = {}
  query = window.location.search.substring(1)
  vars = query.split("&")
  
  for i in [0..vars.length-1]
    pair = vars[i].split("=")
    
    if typeof query_string[pair[0]] == "undefined"
      query_string[pair[0]] = pair[1]

    else if typeof query_string[pair[0]] == "string"
      arr = [ query_string[pair[0]], pair[1] ]
      query_string[pair[0]] = arr
    
    else
      query_string[pair[0]].push(pair[1])
  
  return query_string


url_vars = QueryString()

console.log url_vars

gridx = flowx = 15
gridy = flowy = 7

# Read the query string and set the grid accordingly
gridx = +url_vars.gridx if url_vars.gridx?
gridy = +url_vars.gridy if url_vars.gridy?

# Read the query string and set the number of flow points accordingly
flowx = gridx
flowy = gridy
flowx = +url_vars.flowx if url_vars.flowx? 
flowy = +url_vars.flowy if url_vars.flowy?

kk = new Kaliedoscope(gridx, gridy, flowx, flowy)

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

# Keypress callbacks for non WebGL related things such as the 2D Video canvas
keypressed = (event) ->
  # If 'w' is pressed toggle the flow canvas
  if event.keyCode == 119
    dm = document.getElementById 'webcam-canvas'
    if dm.style.display == "block"
      dm.style.display = "none"
    else
      dm.style.display = "block"

    dat.GUI.toggleHide();

  # If f is pressed, call the swap for the fader now
  if event.keyCode == 102
    kk.webcam_params.fade_current_time = kk.webcam_params.fade_time



# Add callbacks
# Add keypress to the window so we always capture
window.addEventListener "keypress", keypressed 
window.addEventListener('resize', kk.resize, false) if window?
window.addEventListener('resize', credits_resize, false) if window?
credits_resize()

button = document.getElementById "submit-button"

$('#submit-button').click () ->
  btn = $(this)
  btn.button('loading')
  textbox = document.getElementById "youtube-textbox"
  kk.submitYouTube(textbox.value)

  
###
button.addEventListener "mouseup", (event) =>
  textbox = document.getElementById "youtube-textbox"
  textbox.disabled = 'true'
  button.button = 'loading'
  kk.submitYouTube(textbox.value)


, false
###
#kaliedoscopeWebGL.startup()




