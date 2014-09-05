###
Echo Forms - Hellicar & Lewis
Coding - Benjamin Blundell @ section9.co.uk

###


class OpticalFlow

  constructor : (@dom_webcam, @dom_canvas) ->
    @curr_img_pyr = new jsfeat.pyramid_t(3)
    @prev_img_pyr = new jsfeat.pyramid_t(3)
    @curr_img_pyr.allocate(@dom_webcam.videoWidth, @dom_webcam.videoHeight, jsfeat.U8_t|jsfeat.C1_t)
    @prev_img_pyr.allocate(@dom_webcam.videoWidth, @dom_webcam.videoHeight, jsfeat.U8_t|jsfeat.C1_t)

    @point_count = 0
    @point_status = new Uint8Array(100)
    @prev_xy = new Float32Array(100*2)
    @curr_xy = new Float32Array(100*2)

    @options = {}
    @options['win_size'] = 7
    @options['max_iterations'] = 4
    @options['epsilon'] = 0.01
    @options['min_eigen'] = 0.01

    @dom_canvas.width = @dom_webcam.videoWidth
    @dom_canvas.height = @dom_webcam.videoHeight

    @ctx = @dom_canvas.getContext('2d');

    @ctx.fillStyle = "rgb(0,255,0)";
    @ctx.strokeStyle = "rgb(0,255,0)";

    @

  update : (dt) ->

    @ctx.drawImage(@dom_webcam, 0, 0, @dom_webcam.videoWidth, @dom_webcam.videoHeight)

    _pt_xy = @prev_xy
    @prev_xy = @curr_xy
    @curr_xy = _pt_xy
    _pyr = @prev_img_pyr
    @prev_img_pyr = @curr_img_pyr
    @curr_img_pyr = _pyr

    jsfeat.imgproc.grayscale(@dom_webcam, @dom_webcam.videoWidth, @dom_webcam.videoHeight, @curr_img_pyr.data[0])

    @curr_img_pyr.build(@curr_img_pyr.data[0], true)

    jsfeat.optical_flow_lk.track(@prev_img_pyr, @curr_img_pyr, @prev_xy, @curr_xy, @point_count, @options.win_size|0, @options.max_iterations|0, @point_status, @options.epsilon, @options.min_eigen)


module.exports =
  OpticalFlow : OpticalFlow