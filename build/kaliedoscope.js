// Generated by CoffeeScript 1.6.3
/*
Kaliedoscope Test

http://stackoverflow.com/questions/13739901/vertex-kaleidoscope-shader
*/


(function() {
  var Kaliedoscope, canvas, cgl, kk,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Kaliedoscope = (function() {
    function Kaliedoscope() {
      this.resize = __bind(this.resize, this);
    }

    Kaliedoscope.prototype.setupPlane = function() {
      var i, ids, idt, j, sstep, tcs, _i, _ref, _results;
      this.plane = new CoffeeGL.PlaneHexagonFlat(this.plane_xres, this.plane_yres);
      idt = 0;
      tcs = [
        {
          u: 0.0,
          v: 0.0
        }, {
          u: 1.0,
          v: 0.0
        }, {
          u: 1.0,
          v: 1.0
        }
      ];
      sstep = [0, 1, 2];
      ids = 0;
      _results = [];
      for (i = _i = 0, _ref = this.plane_yres - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        ids = 0;
        _results.push((function() {
          var _j, _ref1, _results1;
          _results1 = [];
          for (j = _j = 0, _ref1 = this.plane_xres - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; j = 0 <= _ref1 ? ++_j : --_j) {
            this.plane.t[idt++] = tcs[ids].u;
            this.plane.t[idt++] = tcs[ids].v;
            ids++;
            if (ids > 2) {
              _results1.push(ids = 0);
            } else {
              _results1.push(void 0);
            }
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    Kaliedoscope.prototype.morphPlane = function() {
      var dir, i, idt, j, np, _i, _ref, _results;
      idt = 0;
      np = new CoffeeGL.Vec3(0, 0, 0);
      _results = [];
      for (i = _i = 0, _ref = this.plane_yres - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        _results.push((function() {
          var _j, _ref1, _results1;
          _results1 = [];
          for (j = _j = 0, _ref1 = this.plane_xres - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; j = 0 <= _ref1 ? ++_j : --_j) {
            np.x = this.plane.p[idt];
            np.y = this.plane.p[idt + 1];
            np.z = this.plane.p[idt + 2];
            dir = CoffeeGL.Vec3.sub(np, this.ray);
            dir.multScalar(0.01);
            np.add(dir);
            np.z = this.plane.p[idt + 2];
            this.plane.p[idt++] = np.x;
            this.plane.p[idt++] = np.y;
            _results1.push(this.plane.p[idt++] = np.z);
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    Kaliedoscope.prototype.videoNodeTrans = function(w, h) {
      var xfactor, yfactor;
      if (w == null) {
        w = 1;
      }
      if (h == null) {
        h = 1;
      }
      this.video_node.matrix.identity();
      this.video_node.matrix.rotate(new CoffeeGL.Vec3(1, 0, 0), CoffeeGL.PI / 2);
      xfactor = 2.0 * w / h;
      yfactor = 2.0;
      return this.video_node.matrix.scale(new CoffeeGL.Vec3(xfactor, 1, yfactor));
    };

    Kaliedoscope.prototype.mouseMoved = function(event) {
      var x, y;
      x = event.mouseX;
      y = event.mouseY;
      return this.ray = this.c.castRay(x, y);
    };

    Kaliedoscope.prototype.mouseOver = function(event) {
      this.morphing = true;
      if (this.shader != null) {
        return this.shader.setUniform1i("uDrag", 1);
      }
    };

    Kaliedoscope.prototype.mouseOut = function(event) {
      this.morphing = false;
      if (this.shader != null) {
        return this.shader.setUniform1i("uDrag", 0);
      }
    };

    Kaliedoscope.prototype.init = function() {
      var datg, r0,
        _this = this;
      this.plane_yres = 9;
      this.plane_xres = 21;
      this.ray = new CoffeeGL.Vec3(0, 0, 0);
      this.setupPlane();
      this.video_node = new CoffeeGL.Node(this.plane);
      this.video_node.brew({
        position_buffer_access: GL.DYNAMIC_DRAW
      });
      this.videoNodeTrans(CoffeeGL.Context.width, CoffeeGL.Context.height);
      r0 = new CoffeeGL.Request('/basic_texture.glsl');
      r0.get(function(data) {
        _this.shader = new CoffeeGL.Shader(data);
        _this.shader.bind();
        return _this.shader.setUniform3v("uMouseRay", new CoffeeGL.Vec3(0, 0, 0));
      });
      this.c = new CoffeeGL.Camera.PerspCamera();
      this.c.setViewport(CoffeeGL.Context.width, CoffeeGL.Context.height);
      this.video_node.add(this.c);
      this.t = new CoffeeGL.TextureBase({
        width: 240,
        height: 134
      });
      GL.enable(GL.CULL_FACE);
      GL.cullFace(GL.BACK);
      GL.enable(GL.DEPTH_TEST);
      this.video_ready = false;
      this.video_element = document.getElementById("video");
      this.video_element.preload = "auto";
      this.video_element.src = "/background.mp4";
      this.video_element.oncanplay = function(event) {
        _this.video_element.play();
        _this.t.update(_this.video_element);
        _this.video_node.add(_this.t);
        _this.video_ready = true;
        return console.log("Video Loaded");
      };
      datg = new dat.GUI();
      datg.remember(this);
      CoffeeGL.Context.mouseMove.add(this.mouseMoved, this);
      CoffeeGL.Context.mouseOut.add(this.mouseOut, this);
      return this.morphing = false;
    };

    Kaliedoscope.prototype.update = function(dt) {
      if (this.video_ready) {
        this.t.update(this.video_element);
      }
      if (this.shader != null) {
        return this.shader.setUniform3v("uMouseRay", this.ray);
      }
    };

    Kaliedoscope.prototype.draw = function() {
      GL.clearColor(0.15, 0.15, 0.15, 1.0);
      GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
      return this.video_node.draw();
    };

    Kaliedoscope.prototype.resize = function() {
      CoffeeGL.Context.resizeCanvas(window.innerWidth, window.innerHeight);
      this.c.setViewport(CoffeeGL.Context.width, CoffeeGL.Context.height);
      return this.videoNodeTrans(CoffeeGL.Context.width, CoffeeGL.Context.height);
    };

    return Kaliedoscope;

  })();

  canvas = document.getElementById('webgl-canvas');

  canvas.width = window.innerWidth;

  canvas.height = window.innerHeight;

  kk = new Kaliedoscope();

  cgl = new CoffeeGL.App('webgl-canvas', kk, kk.init, kk.draw, kk.update);

  if (typeof window !== "undefined" && window !== null) {
    window.addEventListener('resize', kk.resize, false);
  }

}).call(this);
