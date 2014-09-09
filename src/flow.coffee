###
Echo Forms - Hellicar & Lewis
Coding - Benjamin Blundell @ section9.co.uk

###


class OpticalFlow

  constructor : (@dom_webcam, @dom_canvas, @grid_x, @grid_y) ->
    @curr_img_pyr = new jsfeat.pyramid_t(3)
    @prev_img_pyr = new jsfeat.pyramid_t(3)
    @curr_img_pyr.allocate(@dom_webcam.videoWidth, @dom_webcam.videoHeight, jsfeat.U8_t|jsfeat.C1_t)
    @prev_img_pyr.allocate(@dom_webcam.videoWidth, @dom_webcam.videoHeight, jsfeat.U8_t|jsfeat.C1_t)

    @max_points = @grid_x * @grid_y

    @point_count = 0
    @point_status = new Uint8Array(@max_points)
    @prev_xy = new Float32Array(@max_points*2)
    @curr_xy = new Float32Array(@max_points*2)
    @base_xy = new Float32Array(@max_points*2)

    @options = {}
    @options['win_size'] = 11
    @options['max_iterations'] = 7
    @options['epsilon'] = 0.015
    @options['min_eigen'] = 0.005

    @dom_canvas.width = @dom_webcam.videoWidth
    @dom_canvas.height = @dom_webcam.videoHeight

    @ctx = @dom_canvas.getContext('2d');

    @ctx.fillStyle = "rgb(0,255,0)";
    @ctx.strokeStyle = "rgb(0,255,0)";

    # setup the points, grid style -  same as the kaleidoscope 


    for i in [0..(@max_points-1)]

      offset = 0
      if Math.floor(i/@grid_x) % 2 == 0
        offset = @dom_webcam.videoWidth / (2 * @grid_x)
      
      idx = i<<1

      @curr_xy[idx] = Math.floor(((i % @grid_x) / @grid_x) * @dom_webcam.videoWidth + offset) 
      @curr_xy[idx+1] = Math.floor((Math.floor(i/@grid_x) / @grid_y) * @dom_webcam.videoHeight)
      
      @base_xy[idx] = @curr_xy[idx]
      @base_xy[idx+1] = @curr_xy[idx+1]

    @point_count = @max_points

    @


  draw_circle : (x, y) ->
    @ctx.beginPath()
    @ctx.arc(x, y, 4, 0, Math.PI*2, true)
    @ctx.closePath()
    @ctx.fill()
            
  set_and_draw : () ->
    for i in [0..@max_points-1]   
      idx = i<<1
      if @point_status[i] == 0

        @curr_xy[idx] = @base_xy[idx]
        @curr_xy[idx+1]=  @base_xy[idx+1]
          
      @draw_circle( @curr_xy[idx], @curr_xy[idx+1])

      
 
  # return interactions as current and prev positions
  active_intersections : () ->
    active = []

    for i in [0..@max_points-1]
      idx = i<<1
      if @point_status[i] == 1
        active.push [[@curr_xy[idx], @curr_xy[idx+1]], [@prev_xy[idx], @prev_xy[idx+1]]]

    active

  update : (dt) ->

    @ctx.drawImage(@dom_webcam, 0, 0, @dom_webcam.videoWidth, @dom_webcam.videoHeight)
    imageData = @ctx.getImageData(0, 0, @dom_webcam.videoWidth, @dom_webcam.videoHeight)

    _pt_xy = @prev_xy
    @prev_xy = @curr_xy
    @curr_xy = _pt_xy
    _pyr = @prev_img_pyr
    @prev_img_pyr = @curr_img_pyr
    @curr_img_pyr = _pyr

    jsfeat.imgproc.grayscale(imageData.data, @dom_webcam.videoWidth, @dom_webcam.videoHeight, @curr_img_pyr.data[0])

    @curr_img_pyr.build(@curr_img_pyr.data[0], true)

    jsfeat.optical_flow_lk.track( @prev_img_pyr, @curr_img_pyr, @prev_xy, @curr_xy, @max_points, @options.win_size|0, @options.max_iterations|0, @point_status, @options.epsilon, @options.min_eigen)

    @set_and_draw()

module.exports =
  OpticalFlow : OpticalFlow