// Generated by CoffeeScript 1.6.3
/*
Echo Forms - Hellicar & Lewis
Coding - Benjamin Blundell @ section9.co.uk
*/


(function() {
  var OpticalFlow;

  OpticalFlow = (function() {
    function OpticalFlow(dom_webcam, dom_canvas, grid_x, grid_y) {
      var i, idx, offset, _i, _ref;
      this.dom_webcam = dom_webcam;
      this.dom_canvas = dom_canvas;
      this.grid_x = grid_x;
      this.grid_y = grid_y;
      this.curr_img_pyr = new jsfeat.pyramid_t(3);
      this.prev_img_pyr = new jsfeat.pyramid_t(3);
      this.curr_img_pyr.allocate(this.dom_webcam.videoWidth, this.dom_webcam.videoHeight, jsfeat.U8_t | jsfeat.C1_t);
      this.prev_img_pyr.allocate(this.dom_webcam.videoWidth, this.dom_webcam.videoHeight, jsfeat.U8_t | jsfeat.C1_t);
      this.max_points = this.grid_x * this.grid_y;
      this.point_count = 0;
      this.point_status = new Uint8Array(this.max_points);
      this.prev_xy = new Float32Array(this.max_points * 2);
      this.curr_xy = new Float32Array(this.max_points * 2);
      this.base_xy = new Float32Array(this.max_points * 2);
      this.options = {};
      this.options['win_size'] = 11;
      this.options['max_iterations'] = 7;
      this.options['epsilon'] = 0.015;
      this.options['min_eigen'] = 0.005;
      this.dom_canvas.width = this.dom_webcam.videoWidth;
      this.dom_canvas.height = this.dom_webcam.videoHeight;
      this.ctx = this.dom_canvas.getContext('2d');
      this.ctx.fillStyle = "rgb(0,255,0)";
      this.ctx.strokeStyle = "rgb(0,255,0)";
      for (i = _i = 0, _ref = this.max_points - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        offset = 0;
        if (Math.floor(i / this.grid_x) % 2 === 0) {
          offset = this.dom_webcam.videoWidth / (2 * this.grid_x);
        }
        idx = i << 1;
        this.curr_xy[idx] = Math.floor(((i % this.grid_x) / this.grid_x) * this.dom_webcam.videoWidth + offset);
        this.curr_xy[idx + 1] = Math.floor((Math.floor(i / this.grid_x) / this.grid_y) * this.dom_webcam.videoHeight);
        this.base_xy[idx] = this.curr_xy[idx];
        this.base_xy[idx + 1] = this.curr_xy[idx + 1];
      }
      this.point_count = this.max_points;
      this;
    }

    OpticalFlow.prototype.draw_circle = function(x, y) {
      this.ctx.beginPath();
      this.ctx.arc(x, y, 4, 0, Math.PI * 2, true);
      this.ctx.closePath();
      return this.ctx.fill();
    };

    OpticalFlow.prototype.set_and_draw = function() {
      var i, idx, _i, _ref, _results;
      _results = [];
      for (i = _i = 0, _ref = this.max_points - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        idx = i << 1;
        if (this.point_status[i] === 0) {
          this.curr_xy[idx] = this.base_xy[idx];
          this.curr_xy[idx + 1] = this.base_xy[idx + 1];
        }
        _results.push(this.draw_circle(this.curr_xy[idx], this.curr_xy[idx + 1]));
      }
      return _results;
    };

    OpticalFlow.prototype.active_intersections = function() {
      var active, i, idx, _i, _ref;
      active = [];
      for (i = _i = 0, _ref = this.max_points - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        idx = i << 1;
        if (this.point_status[i] === 1) {
          active.push([[this.curr_xy[idx], this.curr_xy[idx + 1]], [this.prev_xy[idx], this.prev_xy[idx + 1]]]);
        }
      }
      return active;
    };

    OpticalFlow.prototype.update = function(dt) {
      var imageData, _pt_xy, _pyr;
      this.ctx.drawImage(this.dom_webcam, 0, 0, this.dom_webcam.videoWidth, this.dom_webcam.videoHeight);
      imageData = this.ctx.getImageData(0, 0, this.dom_webcam.videoWidth, this.dom_webcam.videoHeight);
      _pt_xy = this.prev_xy;
      this.prev_xy = this.curr_xy;
      this.curr_xy = _pt_xy;
      _pyr = this.prev_img_pyr;
      this.prev_img_pyr = this.curr_img_pyr;
      this.curr_img_pyr = _pyr;
      jsfeat.imgproc.grayscale(imageData.data, this.dom_webcam.videoWidth, this.dom_webcam.videoHeight, this.curr_img_pyr.data[0]);
      this.curr_img_pyr.build(this.curr_img_pyr.data[0], true);
      jsfeat.optical_flow_lk.track(this.prev_img_pyr, this.curr_img_pyr, this.prev_xy, this.curr_xy, this.max_points, this.options.win_size | 0, this.options.max_iterations | 0, this.point_status, this.options.epsilon, this.options.min_eigen);
      return this.set_and_draw();
    };

    return OpticalFlow;

  })();

  module.exports = {
    OpticalFlow: OpticalFlow
  };

}).call(this);