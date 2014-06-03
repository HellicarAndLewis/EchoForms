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
    

  # We do this in CPU space as there is no real speed issue
  morphPlane : () ->

    #if not @morphing
    #  return

    idt = 0 
    np = new CoffeeGL.Vec3 0,0,0
    for i in [0..@plane_yres-1]
      for j in [0..@plane_xres-1]

        np.x = @plane.p[idt]
        np.y = @plane.p[idt+1]
        np.z = @plane.p[idt+2]

        dir = CoffeeGL.Vec3.sub(np, @ray)
        dir.multScalar(0.01)
        
        np.add(dir)

        np.z = @plane.p[idt+2]

        @plane.p[idt++] = np.x
        @plane.p[idt++] = np.y
        @plane.p[idt++] = np.z

  videoNodeTrans : (w=1,h=1) ->

    @video_node.matrix.identity()
    @video_node.matrix.rotate  new CoffeeGL.Vec3(1,0,0), CoffeeGL.PI / 2

    xfactor = 2.0 * w / h
    yfactor = 2.0

    @video_node.matrix.scale new CoffeeGL.Vec3 xfactor,1,yfactor

  mouseMoved : (event) ->
    x = event.mouseX
    y = event.mouseY

    @ray = @c.castRay x,y

  mouseOver : (event) ->
    @morphing = true
    @shader.setUniform1i "uDrag", 1 if @shader?


  mouseOut : (event) ->
    @morphing = false
    @shader.setUniform1i "uDrag", 0 if @shader?

  init : () ->
    
    @plane_yres = 9
    @plane_xres = 21

    @ray = new CoffeeGL.Vec3 0,0,0

    @setupPlane()
    
    @video_node = new CoffeeGL.Node @plane

    # Pre brew with correct dynamic flags
    @video_node.brew {position_buffer_access : GL.DYNAMIC_DRAW } 

    @videoNodeTrans CoffeeGL.Context.width, CoffeeGL.Context.height

    r0 = new CoffeeGL.Request('/basic_texture.glsl')
    r0.get (data) =>
      @shader = new CoffeeGL.Shader(data)
      #@video_node.add @shader
      @shader.bind()
      @shader.setUniform3v "uMouseRay", new CoffeeGL.Vec3 0,0,0

    @c = new CoffeeGL.Camera.PerspCamera()
    @c.setViewport CoffeeGL.Context.width, CoffeeGL.Context.height

    @video_node.add @c
   
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
    

    datg = new dat.GUI()
    datg.remember(@)

    
    # Setup mouse listener
    CoffeeGL.Context.mouseMove.add @mouseMoved, @
    CoffeeGL.Context.mouseOut.add @mouseOut, @

    @morphing = false

  update : (dt) ->
    
    @t.update @video_element if @video_ready

    @shader.setUniform3v "uMouseRay", @ray if @shader?

    #@morphPlane()

    #@video_node.rebrew( { position_buffer : 0 })
  
  draw : () ->
    
    GL.clearColor(0.15, 0.15, 0.15, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

    @video_node.draw()

  resize : () =>
    CoffeeGL.Context.resizeCanvas window.innerWidth, window.innerHeight
    @c.setViewport CoffeeGL.Context.width, CoffeeGL.Context.height
    @videoNodeTrans CoffeeGL.Context.width, CoffeeGL.Context.height

# Initial Size of the Canvas, pre WebGL
canvas = document.getElementById 'webgl-canvas'
canvas.width = window.innerWidth
canvas.height = window.innerHeight

kk = new Kaliedoscope()
cgl = new CoffeeGL.App('webgl-canvas', kk, kk.init, kk.draw, kk.update)

window.addEventListener('resize', kk.resize, false) if window?


