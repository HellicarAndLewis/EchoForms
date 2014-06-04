###
Kaliedoscope Test

http://stackoverflow.com/questions/13739901/vertex-kaleidoscope-shader

###


class Kaliedoscope

  setupPlane : () ->
  

    # Alter the texture co-ordinates to create a Kaliedoscope
    # Essentially, each triangle covers the entire texture
    # with each shared edge reflecting

    # Also alter to make the hexagons more regular
    @plane = new CoffeeGL.PlaneHexagonFlat @plane_xres, @plane_yres 

    idt = 0
    tcs = [ {u:0.0, v:0.0}, {u:1.0, v:0.0}, {u:1.0, v:1.0} ]
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

    @plane_base = CoffeeGL.clone @plane
    

  # We do this in CPU space as there is no real speed issue
  morphPlane : () ->

    if not (@mouse_over and @mouse_pressed)
      return

    idt = 0 
    np = new CoffeeGL.Vec3 0,0,0
    tp = new CoffeeGL.Vec2 0,0
    ray2 = new CoffeeGL.Vec2 @ray.x, @ray.y
    ray2_prev = new CoffeeGL.Vec2 @ray_prev.x, @ray_prev.y

    inv =  CoffeeGL.Matrix4.invert @video_node.matrix

    for i in [0..@plane_yres-1]
      for j in [0..@plane_xres-1]

        np.x = @plane.p[idt]
        np.y = @plane.p[idt+1]
        np.z = @plane.p[idt+2]

        @video_node.matrix.multVec(np)

        # Work in 2D with the ray and plane
        tp.x = np.x
        tp.y = np.y


        dir = CoffeeGL.Vec2.sub(ray2, ray2_prev)
        dir_dist = ray2.dist ray2_prev

        dd = tp.dist ray2
        
        dir.normalize()

        if dd < @warp.range

          falloff = dd / @warp.range * @warp.falloff_factor

          tp.add( dir.multScalar( Math.pow(dir_dist,@warp.exponent) * @warp.factor * falloff))

        # Back to 3D

        np.x = tp.x
        np.y = tp.y

        inv.multVec np

        @plane.p[idt++] = np.x
        @plane.p[idt++] = np.y
        @plane.p[idt++] = np.z

  # Spring back to where we started

  springBack : () ->

    idt = 0

    np = new CoffeeGL.Vec3 0,0,0
    bp = new CoffeeGL.Vec3 0,0,0

    for i in [0..@plane_yres-1]
      for j in [0..@plane_xres-1]

        np.x = @plane.p[idt]
        np.y = @plane.p[idt+1]
        np.z = @plane.p[idt+2]

        bp.x = @plane_base.p[idt]
        bp.y = @plane_base.p[idt+1]
        bp.z = @plane_base.p[idt+2]


        dir = CoffeeGL.Vec3.sub bp, np
        dir_dist = bp.dist np

        dir.normalize()
        dir.multScalar(@warp.springiness)

        if dir_dist > 0.01

          @plane.p[idt] = np.x + dir.x
          @plane.p[idt+1] = np.y + dir.y
          @plane.p[idt+2] = np.z + dir.z

        idt += 3

  videoNodeTrans : (w=1,h=1) ->

    @video_node.matrix.identity()
    @video_node.matrix.rotate  new CoffeeGL.Vec3(1,0,0), CoffeeGL.PI / 2

    xfactor = 2.0 * w / h
    yfactor = 2.0

    @video_node.matrix.scale new CoffeeGL.Vec3 xfactor,1,yfactor

 

  init : () ->
    
    @plane_yres = 9
    @plane_xres = 21

    @ray = new CoffeeGL.Vec3 0,0,0
    @ray_prev = new CoffeeGL.Vec3 0,0,0

    @setupPlane()
    
    @video_node = new CoffeeGL.Node @plane

    # Warp parameters

    @warp =
      exponent  : 2
      factor    : 0.6
      range     : 0.4
      falloff_factor : 1.0
      springiness : 0.0001

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
    @camera.setViewport CoffeeGL.Context.width, CoffeeGL.Context.height

    @video_node.add @camera
   
    @t = new CoffeeGL.TextureBase({ width: 240, height: 134 })

    GL.enable(GL.CULL_FACE)
    GL.cullFace(GL.BACK)
    GL.enable(GL.DEPTH_TEST)

    @video_ready = false
    @video_element = document.getElementById "video"

    
    @video_element.preload = "auto"
    @video_element.src = "/background.mp4"

    @video_element.oncanplay = (event) =>
      @video_element.play()
      @t.update @video_element
      @video_node.add @t
      @video_ready = true
      console.log "Video Loaded"
    

    # GUI Setup

    datg = new dat.GUI()
    datg.remember(@)

    datg.add(@warp,'exponent',1.0,5.0)
    datg.add(@warp,'factor',0.001,10.0)
    datg.add(@warp,'range',0.01,1.0)
    datg.add(@warp,'falloff_factor',0.01,10.0)
    datg.add(@warp,'springiness', 0.00001, 0.01)

    
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

    @video_node.rebrew( { position_buffer : 0 })
  
    @springBack()

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

    @ray_prev.copyFrom @ray
    @ray = @camera.castRay x,y

    # Multiply by the distance away of the camera 
    # The plane is at the origin and the camera is looking down the z
    # so distance can be computed easily
    @ray.multScalar @camera.pos.z


  mouseOver : (event) ->
    @mouse_over = true


  mouseOut : (event) ->
    @mouse_over = false

  mouseDown : (event) ->
    @mouse_pressed = true

  mouseUp : (event) ->
    @mouse_pressed = false

# Initial Size of the Canvas, pre WebGL
canvas = document.getElementById 'webgl-canvas'
canvas.width = window.innerWidth
canvas.height = window.innerHeight

kk = new Kaliedoscope()
cgl = new CoffeeGL.App('webgl-canvas', kk, kk.init, kk.draw, kk.update)

window.addEventListener('resize', kk.resize, false) if window?


