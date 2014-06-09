// Generated by CoffeeScript 1.6.3
/*
Kaliedoscope Test

http://stackoverflow.com/questions/13739901/vertex-kaleidoscope-shader
*/


(function() {
  var Kaliedoscope, canvas, cgl, credits_resize, kk,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Kaliedoscope = (function() {
    function Kaliedoscope() {
      this.resize = __bind(this.resize, this);
    }

    Kaliedoscope.prototype.loadAssets = function() {
      var a, b, i, self, _genLoadAudio, _i, _loadShaderBlur, _loadShaderDOF, _loadShaderDepth, _loadVideo,
        _this = this;
      a = function() {
        var i, item, tt, _i;
        for (i = _i = 0; _i <= 10; i = ++_i) {
          tt = Math.floor(Math.random() * _this.colour_palette.length);
          item = {
            target: _this.colour_palette[tt],
            colour: new CoffeeGL.Colour.RGBA.BLACK(),
            idx: Math.floor(Math.random() * _this.plane.getNumTris())
          };
          _this.loading_items.push(item);
        }
        return console.log("Loaded: " + _this.lq.completed_items.length / _this.lq.items.length);
      };
      b = function() {
        console.log("Loaded All");
        return _this.state_loaded = true;
      };
      this.lq = new CoffeeGL.Loader.LoadQueue(this, a, b);
      self = this;
      _loadVideo = new CoffeeGL.Loader.LoadItem(function() {
        var _this = this;
        self.video_element = document.getElementById("video");
        self.video_element.preload = "auto";
        self.video_element.src = "/Lexus-Sample01.mp4";
        self.video_element.addEventListener("ended", function() {
          self.video_element.currentTime = 0;
          return self.video_element.play();
        }, false);
        self.video_element.addEventListener("timeupdate", function() {
          if (self.video_element.currentTime > 53) {
            self.video_element.pause();
            self.video_element.currentTime = 0;
            self.video_element.play();
          }
        }, false);
        return self.video_element.oncanplay = function(event) {
          if (!self.video_ready) {
            self.video_element.play();
            self.t.update(self.video_element);
            self.video_node.add(self.t);
            self.video_ready = true;
            _this.loaded();
            return console.log("Video Loaded");
          }
        };
      });
      _genLoadAudio = function(audio_url, attach, long) {
        var _loadAudioSample;
        return _loadAudioSample = new CoffeeGL.Loader.LoadItem(function() {
          var sound,
            _this = this;
          sound = new Howl({
            urls: [audio_url],
            onload: function() {
              attach.push(sound);
              sound.playing = false;
              return _this.loaded();
            },
            onplay: function() {
              this.playing = true;
              if (long) {
                return self.sound_long_playing = true;
              }
            },
            onend: function() {
              this.playing = false;
              if (long) {
                return self.sound_long_playing = false;
              }
            }
          });
          return _loadAudioSample;
        });
      };
      _loadShaderDepth = new CoffeeGL.Loader.LoadItem(function() {
        var r2,
          _this = this;
        r2 = new CoffeeGL.Request('/depth.glsl');
        return r2.get(function(data) {
          self.shader_depth = new CoffeeGL.Shader(data);
          return _this.loaded();
        });
      });
      _loadShaderDOF = new CoffeeGL.Loader.LoadItem(function() {
        var r3,
          _this = this;
        r3 = new CoffeeGL.Request('/depth_of_field.glsl');
        return r3.get(function(data) {
          self.shader_dof = new CoffeeGL.Shader(data);
          return _this.loaded();
        });
      });
      _loadShaderBlur = new CoffeeGL.Loader.LoadItem(function() {
        var r4,
          _this = this;
        r4 = new CoffeeGL.Request('/blur.glsl');
        return r4.get(function(data) {
          self.shader_blur = new CoffeeGL.Shader(data);
          return _this.loaded();
        });
      });
      this.lq.add(_loadVideo);
      this.lq.add(_loadShaderDepth);
      this.lq.add(_loadShaderDOF);
      this.lq.add(_loadShaderBlur);
      this.lq.add(_genLoadAudio('/sound/long/Lexus.mp3', this.sounds_long, true));
      for (i = _i = 0; _i <= 5; i = ++_i) {
        this.lq.add(_genLoadAudio('/sound/short/sound00' + i + '.mp3', this.sounds_short, false));
      }
      return this.lq.start();
    };

    Kaliedoscope;

    Kaliedoscope.prototype.playSound = function() {
      var _ref;
      if (this.selected_tris !== this.selected_tris_prev) {
        if (_ref = this.selected_tris, __indexOf.call(this.sound_short_triggers, _ref) >= 0) {
          return this.sounds_short[Math.floor(Math.random() * this.sounds_short.length)].play();
        }
      }
    };

    Kaliedoscope.prototype.setupPlane = function() {
      var i, idc, idp, ids, idt, j, k, sstep, tcs, tx, ty, _i, _j, _k, _l, _ref, _ref1, _ref2, _results;
      this.plane = new CoffeeGL.PlaneHexagonFlat(this.plane_xres, this.plane_yres);
      this.plane_face = new CoffeeGL.PlaneHexagonFlat(this.plane_xres, this.plane_yres, false);
      idt = 0;
      idp = 0;
      idc = 0;
      tcs = [
        {
          u: 0.0,
          v: 0.0
        }, {
          u: 0.5,
          v: 1.0
        }, {
          u: 1.0,
          v: 0.0
        }
      ];
      sstep = [0, 1, 2];
      ids = 0;
      for (i = _i = 0, _ref = this.plane_yres - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        ids = 0;
        for (j = _j = 0, _ref1 = this.plane_xres - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; j = 0 <= _ref1 ? ++_j : --_j) {
          tx = 2.0 * Math.random() - 1;
          ty = 2.0 * Math.random() - 1;
          this.plane.t[idt++] = tcs[ids].u + (this.noise.simplex2(tx, ty) * 0.25);
          this.plane.t[idt++] = tcs[ids].v + (this.noise.simplex2(tx, ty) * 0.25);
          this.plane.p[idp++] += this.noise.simplex2(tx, ty) * 0.02;
          idp++;
          this.plane.p[idp++] += this.noise.simplex2(tx, ty) * 0.02;
          ids++;
          if (ids > 2) {
            ids = 0;
          }
          for (i = _k = 0; _k <= 3; i = ++_k) {
            this.plane.c[idc++] = 0;
          }
        }
      }
      this.plane_base = JSON.parse(JSON.stringify(this.plane));
      idc = 0;
      _results = [];
      for (i = _l = 0, _ref2 = this.plane_yres - 1; 0 <= _ref2 ? _l <= _ref2 : _l >= _ref2; i = 0 <= _ref2 ? ++_l : --_l) {
        _results.push((function() {
          var _m, _n, _ref3, _results1;
          _results1 = [];
          for (j = _m = 0, _ref3 = this.plane_xres - 1; 0 <= _ref3 ? _m <= _ref3 : _m >= _ref3; j = 0 <= _ref3 ? ++_m : --_m) {
            for (k = _n = 0; _n <= 11; k = ++_n) {
              this.plane_face.c[idc * 12 + k] = 0;
            }
            _results1.push(idc++);
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    Kaliedoscope.prototype.rotateTexCoords = function() {
      var i, idt, j, noize, np, rotm, tx, ty, _i, _ref, _results;
      np = new CoffeeGL.Vec3(0, 0, 0);
      idt = 0;
      rotm = new CoffeeGL.Matrix4();
      rotm.rotate(new CoffeeGL.Vec3(0, 0, 1), 0.001 * this.warp.rot_speed);
      _results = [];
      for (i = _i = 0, _ref = this.plane_yres - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        _results.push((function() {
          var _j, _ref1, _results1;
          _results1 = [];
          for (j = _j = 0, _ref1 = this.plane_xres - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; j = 0 <= _ref1 ? ++_j : --_j) {
            tx = (Math.random() * 2.0 - 1) * 0.1;
            ty = (Math.random() * 2.0 - 1) * 0.1;
            noize = this.noise.simplex2(this.intersect.x + tx, this.intersect.y + ty);
            np.x = (this.plane.t[idt] * 2.0) - 1;
            np.y = (this.plane.t[idt + 1] * 2.0) - 1;
            rotm.multVec(np);
            this.plane.t[idt++] = (np.x + 1) / 2;
            _results1.push(this.plane.t[idt++] = (np.y + 1) / 2);
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    Kaliedoscope.prototype.naturalForce = function() {
      var i, idc, idt, j, noize, np, _i, _ref, _results;
      np = new CoffeeGL.Vec3(0, 0, 0);
      idt = 0;
      idc = 0;
      _results = [];
      for (i = _i = 0, _ref = this.plane_yres - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        _results.push((function() {
          var _j, _ref1, _results1;
          _results1 = [];
          for (j = _j = 0, _ref1 = this.plane_xres - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; j = 0 <= _ref1 ? ++_j : --_j) {
            if (Math.random() > this.warp.natural_rate) {
              np.x = this.plane.p[idt++];
              np.y = this.plane.p[idt++];
              np.z = this.plane.p[idt++];
              noize = this.noise.simplex2(np.x * 1.5, np.y * 1.5);
              this.plane.c[idc + 1] += noize * this.warp.natural_force;
            }
            _results1.push(idc += 4);
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    Kaliedoscope.prototype.morphPlane = function() {
      var dd, force, force_dist, i, idc, idt, inv, j, np, _i, _j, _ref, _ref1;
      if (!(this.mouse_over && this.mouse_pressed)) {
        return;
      }
      idt = 0;
      idc = 0;
      np = new CoffeeGL.Vec3(0, 0, 0);
      inv = CoffeeGL.Matrix4.invert(this.video_node.matrix);
      for (i = _i = 0, _ref = this.plane_yres - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        for (j = _j = 0, _ref1 = this.plane_xres - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; j = 0 <= _ref1 ? ++_j : --_j) {
          np.x = this.plane.p[idt++];
          np.y = this.plane.p[idt++];
          np.z = this.plane.p[idt++];
          this.video_node.matrix.multVec(np);
          force = CoffeeGL.Vec3.sub(this.intersect, this.intersect_prev);
          force_dist = this.intersect.dist(this.intersect_prev);
          dd = np.dist(this.intersect);
          if (force_dist > 0.01) {
            if (dd < this.warp.range) {
              force.normalize();
              force.multScalar(this.warp.force * 1.0 / Math.pow(dd, this.warp.exponent));
              np.x = force.x;
              np.y = force.y;
              np.z = 0;
              inv.multVec(np);
              this.plane.c[idc] += np.x;
              this.plane.c[idc + 1] += np.y;
              this.plane.c[idc + 2] += np.z;
              this.plane.c[idc + 3] = 0;
            }
          }
          idc += 4;
        }
      }
      return this;
    };

    Kaliedoscope.prototype.springBack = function() {
      var bp, ff, i, idc, idt, j, np, spring_dist, spring_force, _i, _ref, _results;
      idt = 0;
      idc = 0;
      np = new CoffeeGL.Vec3(0, 0, 0);
      bp = new CoffeeGL.Vec3(0, 0, 0);
      ff = new CoffeeGL.Vec3(0, 0, 0);
      _results = [];
      for (i = _i = 0, _ref = this.plane_yres - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        _results.push((function() {
          var _j, _ref1, _results1;
          _results1 = [];
          for (j = _j = 0, _ref1 = this.plane_xres - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; j = 0 <= _ref1 ? ++_j : --_j) {
            np.x = this.plane.p[idt];
            np.y = this.plane.p[idt + 1];
            np.z = this.plane.p[idt + 2];
            bp.x = this.plane_base.p[idt];
            bp.y = this.plane_base.p[idt + 1];
            bp.z = this.plane_base.p[idt + 2];
            ff.x = this.plane.c[idc];
            ff.y = this.plane.c[idc + 1];
            ff.z = this.plane.c[idc + 2];
            spring_force = CoffeeGL.Vec3.sub(bp, np);
            spring_dist = bp.dist(np);
            spring_force.normalize();
            spring_force.multScalar(spring_dist * this.warp.springiness);
            ff.add(spring_force);
            ff.multScalar(this.warp.spring_damping);
            this.plane.c[idc] = ff.x;
            this.plane.c[idc + 1] = ff.y;
            this.plane.c[idc + 2] = ff.z;
            this.plane.p[idt] = np.x + ff.x;
            this.plane.p[idt + 1] = np.y + ff.y;
            this.plane.p[idt + 2] = np.z + ff.z;
            idt += 3;
            _results1.push(idc += 4);
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    Kaliedoscope.prototype.copyToFace = function() {
      var i, idp, idx, j, _i, _ref, _results;
      idp = 0;
      _results = [];
      for (i = _i = 0, _ref = this.plane.indices.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        idx = this.plane.indices[i];
        _results.push((function() {
          var _j, _results1;
          _results1 = [];
          for (j = _j = 0; _j <= 2; j = ++_j) {
            _results1.push(this.plane_face.p[idp++] = this.plane.p[idx * 3 + j]);
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    Kaliedoscope.prototype.geomTrans = function(w, h) {
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
      this.video_node.matrix.scale(new CoffeeGL.Vec3(xfactor, 1, yfactor));
      return this.face_node.matrix.copyFrom(this.video_node.matrix);
    };

    Kaliedoscope.prototype.init = function() {
      var datg, i, r0, r1, _i,
        _this = this;
      CoffeeGL.makeTouchEmitter(CoffeeGL.Context);
      this.state_ready = false;
      this.state_loaded = false;
      this.loading_items = [];
      this.loading_timeout = 0;
      this.ready_fade_in = 0;
      this.loading_time_limit = 3;
      this.ready_fade_time = 3;
      this.noise = new CoffeeGL.Noise.Noise();
      this.noise.setSeed(Math.random());
      this.colour_palette = [new CoffeeGL.Colour.RGBA(31, 169, 225), new CoffeeGL.Colour.RGBA(34, 54, 107), new CoffeeGL.Colour.RGBA(240, 77, 35), new CoffeeGL.Colour.RGBA(228, 198, 158), new CoffeeGL.Colour.RGBA(195, 206, 207)];
      this.plane_yres = 9;
      this.plane_xres = 21;
      this.setupPlane();
      this.video_node = new CoffeeGL.Node(this.plane);
      this.face_node = new CoffeeGL.Node(this.plane_face);
      this.ray = new CoffeeGL.Vec3(0, 0, 0);
      this.intersect_prev = new CoffeeGL.Vec3(0, 0, 0);
      this.intersect = new CoffeeGL.Vec3(0, 0, 0);
      this.selected_tris = this.selected_tris_prev = -1;
      this.screen_node = new CoffeeGL.Node(new CoffeeGL.Quad());
      this.dof_params = {
        focal_distance: 3.78,
        focal_range: 0.02
      };
      this.fbo_depth = new CoffeeGL.Fbo(CoffeeGL.Context.width, CoffeeGL.Context.height);
      this.fbo_depth.texture.unit = 1;
      this.fbo_colour = new CoffeeGL.Fbo(CoffeeGL.Context.width, CoffeeGL.Context.height);
      this.fbo_colour.texture.unit = 0;
      this.fbo_blur = new CoffeeGL.Fbo(CoffeeGL.Context.width, CoffeeGL.Context.height);
      this.fbo_blur.texture.unit = 2;
      this.warp = {
        exponent: 2,
        force: 0.004,
        range: 2.0,
        falloff_factor: 1.0,
        springiness: 0.0068,
        springiness_exponent: 2.0,
        rot_speed: 4.0,
        spring_damping: 0.91,
        natural_rate: 0.9,
        natural_force: 0.002
      };
      this.highLight = {
        speed_in: 0.08,
        speed_out: 0.01,
        alpha_scalar: 0.75
      };
      this.sound_long_playing = false;
      this.sound_on = true;
      this.sound_long_triggers = [];
      this.sound_short_triggers = [];
      for (i = _i = 0; _i <= 100; i = ++_i) {
        this.sound_short_triggers.push(Math.floor(Math.random() * this.plane.getNumTris()));
      }
      this.video_node.brew({
        position_buffer_access: GL.DYNAMIC_DRAW,
        texcoord_buffer_access: GL.DYNAMIC_DRAW
      });
      this.face_node.brew({
        position_buffer_access: GL.DYNAMIC_DRAW,
        colour_buffer_access: GL.DYNAMIC_DRAW
      });
      this.geomTrans(CoffeeGL.Context.width, CoffeeGL.Context.height);
      r0 = new CoffeeGL.Request('/basic_texture.glsl');
      r0.get(function(data) {
        return _this.shader = new CoffeeGL.Shader(data);
      });
      r1 = new CoffeeGL.Request('/face.glsl');
      r1.get(function(data) {
        _this.shader_face = new CoffeeGL.Shader(data);
        _this.shader_face.bind();
        return _this.shader_face.setUniform1f("uAlphaScalar", _this.highLight.alpha_scalar);
      });
      this.camera = new CoffeeGL.Camera.PerspCamera();
      this.camera.pos.z = 3.8;
      this.camera.near = 0.001;
      this.camera.far = 8.0;
      this.camera.setViewport(CoffeeGL.Context.width, CoffeeGL.Context.height);
      this.video_node.add(this.camera);
      this.face_node.add(this.camera);
      this.t = new CoffeeGL.TextureBase({
        width: 240,
        height: 134
      });
      GL.enable(GL.BLEND);
      GL.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
      this.video_ready = false;
      this.sounds_long = [];
      this.sounds_short = [];
      this.loadAssets();
      datg = new dat.GUI();
      datg.remember(this);
      datg.add(this.warp, 'exponent', 1.0, 5.0);
      datg.add(this.warp, 'force', 0.0001, 0.01);
      datg.add(this.warp, 'range', 0.1, 5.0);
      datg.add(this.warp, 'springiness', 0.0001, 0.01);
      datg.add(this.warp, 'spring_damping', 0.1, 1.0);
      datg.add(this.warp, 'rot_speed', 0.01, 10.0);
      datg.add(this.warp, 'natural_rate', 0.1, 1.0);
      datg.add(this.warp, 'natural_force', 0.0001, 0.01);
      datg.add(this, 'sound_on');
      datg.add(this.highLight, 'speed_in', 0.001, 0.1);
      datg.add(this.highLight, 'speed_out', 0.001, 0.1);
      datg.add(this.highLight, 'alpha_scalar', 0.1, 1.0);
      datg.add(this.dof_params, 'focal_range', 0.001, 1.0);
      datg.add(this.dof_params, 'focal_distance', 0.1, 10.0);
      CoffeeGL.Context.mouseMove.add(this.mouseMoved, this);
      CoffeeGL.Context.mouseOut.add(this.mouseOut, this);
      CoffeeGL.Context.mouseOver.add(this.mouseOver, this);
      CoffeeGL.Context.mouseDown.add(this.mouseDown, this);
      CoffeeGL.Context.mouseUp.add(this.mouseUp, this);
      CoffeeGL.Context.touchSwipe.add(this.touchSwipe, this);
      this.mouse_over = false;
      return this.mouse_pressed = false;
    };

    Kaliedoscope.prototype.updateFaceHighlight = function(idx) {
      var i, idc, j, k, _i, _ref, _results;
      idc = 0;
      _results = [];
      for (i = _i = 0, _ref = this.plane_yres - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        _results.push((function() {
          var _j, _k, _ref1, _results1;
          _results1 = [];
          for (j = _j = 0, _ref1 = this.plane_xres - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; j = 0 <= _ref1 ? ++_j : --_j) {
            for (k = _k = 0; _k <= 11; k = ++_k) {
              if (idx === idc) {
                this.plane_face.c[idc * 12 + k] += this.highLight.speed_in;
              } else {
                this.plane_face.c[idc * 12 + k] -= this.highLight.speed_out;
              }
              if (this.plane_face.c[idc * 12 + k] <= 0) {
                this.plane_face.c[idc * 12 + k] = 0;
              }
              if (this.plane_face.c[idc * 12 + k] >= 1.0) {
                this.plane_face.c[idc * 12 + k] = 1.0;
              }
            }
            _results1.push(idc++);
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    Kaliedoscope.prototype.updateFaceColour = function(idx, colour) {
      var i, idc, j, k, _i, _ref, _results;
      idc = 0;
      _results = [];
      for (i = _i = 0, _ref = this.plane_yres - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        _results.push((function() {
          var _j, _k, _ref1, _results1;
          _results1 = [];
          for (j = _j = 0, _ref1 = this.plane_xres - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; j = 0 <= _ref1 ? ++_j : --_j) {
            for (k = _k = 0; _k <= 2; k = ++_k) {
              if (idx === idc) {
                this.plane_face.c[idc * 12 + (k * 4)] = colour.r;
                this.plane_face.c[idc * 12 + (k * 4) + 1] = colour.g;
                this.plane_face.c[idc * 12 + (k * 4) + 2] = colour.b;
                this.plane_face.c[idc * 12 + (k * 4) + 3] = colour.a;
              }
            }
            _results1.push(idc++);
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    Kaliedoscope.prototype.updateLoading = function(dt) {
      var i, tc, tt, _i, _len, _ref;
      if (this.shader_face != null) {
        this.shader_face.bind();
        this.shader_face.setUniform1f("uClockTick", CoffeeGL.Context.contextTime);
        this.shader_face.setUniform1f("uAlphaScalar", 1.0);
      }
      _ref = this.loading_items;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        i = _ref[_i];
        tc = i.colour;
        tt = i.target;
        if (tc.r < tt.r) {
          tc.r += this.highLight.speed_in * tt.r;
        }
        if (tc.g < tt.g) {
          tc.g += this.highLight.speed_in * tt.g;
        }
        if (tc.b < tt.b) {
          tc.b += this.highLight.speed_in * tt.b;
        }
        if (tc.a < tt.a) {
          tc.a += this.highLight.speed_in * tt.a;
        }
        this.updateFaceColour(i.idx, tc);
      }
      this.naturalForce();
      this.copyToFace();
      this.springBack();
      return this.face_node.rebrew({
        position_buffer: 0,
        colour_buffer: 0
      });
    };

    Kaliedoscope.prototype.updateActual = function(dt) {
      if (this.video_ready) {
        this.t.update(this.video_element);
      }
      if (this.shader != null) {
        this.shader.bind();
        this.shader.setUniform1f("uClockTick", CoffeeGL.Context.contextTime);
        this.shader.setUniform1f("uMasterAlpha", this.ready_fade_in);
      }
      if (this.shader_face != null) {
        this.shader_face.bind();
        this.shader_face.setUniform1f("uClockTick", CoffeeGL.Context.contextTime);
        this.shader_face.setUniform1f("uAlphaScalar", this.highLight.alpha_scalar);
      }
      this.naturalForce();
      this.morphPlane();
      this.copyToFace();
      this.updateFaceHighlight(this.selected_tris);
      this.video_node.rebrew({
        position_buffer: 0,
        texcoord_buffer: 0
      });
      this.face_node.rebrew({
        position_buffer: 0,
        colour_buffer: 0
      });
      this.springBack();
      if (this.sound_on) {
        return this.playSound();
      }
    };

    Kaliedoscope.prototype.update = function(dt) {
      var credits;
      if (this.state_ready) {
        this.ready_fade_in += (dt / 1000) / this.ready_fade_time;
        if (this.ready_fade_in > 1.0) {
          this.ready_fade_in = 1.0;
        }
        this.updateActual();
      } else {
        this.updateLoading();
        this.loading_timeout += dt / 1000;
        if (this.state_loaded && this.loading_timeout > this.loading_time_limit) {
          this.state_ready = true;
          credits = document.getElementById('credits');
          credits.style.display = 'none';
        }
      }
      if (CoffeeGL.Context.ongoingTouches.length > 0) {
        return this.mouse_over = false;
      }
    };

    Kaliedoscope.prototype.drawActual = function() {
      GL.clearColor(0.15, 0.15, 0.15, 1.0);
      GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
      /*
      if @shader_depth?
        @fbo_depth.bind()
        @fbo_depth.clear(new CoffeeGL.Colour.RGBA.WHITE())
        @shader_depth.bind()
        @video_node.draw()
        @shader_depth.unbind()
        @fbo_depth.unbind()
      
       
      if @shader? and @shader_face?
        @fbo_colour.bind()
        @fbo_colour.clear(new CoffeeGL.Colour.RGBA.BLACK())
        @shader.bind()
        @video_node.draw()
        @shader_face.bind()
        @face_node.draw()
        @fbo_colour.unbind()
      
      if @shader_blur?
        @fbo_blur.bind()
        @fbo_blur.clear()
        @shader_blur.bind()
        @shader_blur.setUniform1i "uSampler",0
        @shader_blur.setUniform1f "uResolution", 512
        @shader_blur.setUniform1f "uRadius", 2
        @shader_blur.setUniform2fv "uDir", [1.0, 0.0]
      
        @fbo_colour.texture.bind()
        @screen_node.draw()
        @fbo_colour.texture.unbind()
        @fbo_blur.unbind()
      
      
      if @shader_dof?
        @shader_dof.bind()
        
        @fbo_colour.texture.bind()
        @fbo_depth.texture.bind()
        @fbo_blur.texture.bind()
      
        @shader_dof.setUniform1i "uSampler",0
        @shader_dof.setUniform1i "uSamplerDepth", 1
        @shader_dof.setUniform1i "uSamplerBlurred", 2
        @shader_dof.setUniform1f "uNearPlane", @camera.near
        @shader_dof.setUniform1f "uFarPlane", @camera.far
      
        @shader_dof.setUniform1f "uFocalRange", @dof_params.focal_range
        @shader_dof.setUniform1f "uFocalDistance", @dof_params.focal_distance
      
        @screen_node.draw()
      
        @fbo_depth.texture.unbind()
        @fbo_colour.texture.unbind()
        @fbo_blur.texture.unbind()
        @shader_dof.unbind()
      */

      this.shader.bind();
      this.video_node.draw();
      this.shader_face.bind();
      return this.face_node.draw();
    };

    Kaliedoscope.prototype.drawLoading = function() {
      GL.clearColor(0.15, 0.15, 0.15, 1.0);
      GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
      if (this.shader_face != null) {
        this.shader_face.bind();
        return this.face_node.draw();
      }
    };

    Kaliedoscope.prototype.draw = function() {
      if (this.state_ready) {
        return this.drawActual();
      } else {
        return this.drawLoading();
      }
    };

    Kaliedoscope.prototype.resize = function() {
      CoffeeGL.Context.resizeCanvas(window.innerWidth, window.innerHeight);
      this.camera.setViewport(CoffeeGL.Context.width, CoffeeGL.Context.height);
      return this.geomTrans(CoffeeGL.Context.width, CoffeeGL.Context.height);
    };

    Kaliedoscope.prototype.interact = function(x, y) {
      this.intersect_prev.copyFrom(this.intersect);
      this.rotateTexCoords();
      this.intersect.set(0, 0, 0);
      this.selected_tris_prev = this.selected_tris;
      this.selected_tris = CoffeeGL.Math.screenNodeHitTest(x, y, this.camera, this.video_node, this.intersect);
      if (this.shader != null) {
        this.shader.bind();
        if (this.selected_tris !== -1) {
          this.shader.setUniform1f("uHighLight", 1.0);
        } else {
          this.shader.setUniform1f("uHighLight", 0.0);
        }
        this.shader.setUniform3v("uMousePos", this.intersect);
      }
      if (this.shader_face != null) {
        this.shader_face.bind();
        if (this.selected_tris !== -1) {
          this.shader_face.setUniform1f("uHighLight", 1.0);
        } else {
          this.shader_face.setUniform1f("uHighLight", 0.0);
        }
        this.shader_face.setUniform3v("uMousePos", this.intersect);
        return this.shader_face.setUniform1i("uChosenIndex", this.selected_tris);
      }
    };

    Kaliedoscope.prototype.mouseMoved = function(event) {
      var x, y;
      x = event.mouseX;
      y = event.mouseY;
      this.interact(x, y);
      if (this.mouse_pressed && this.sound_on) {
        if (!this.sounds_long[0].playing) {
          this.sounds_long[0].play();
          return this.sounds_long[0].playing = true;
        }
      }
    };

    Kaliedoscope.prototype.touchSwipe = function(event) {
      var touch, _i, _len, _ref, _results;
      this.mouse_over = true;
      this.mouse_pressed = true;
      _ref = CoffeeGL.Context.ongoingTouches;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        touch = _ref[_i];
        _results.push(this.interact(touch.ppos.x, touch.ppos.y));
      }
      return _results;
    };

    Kaliedoscope.prototype.mouseOver = function(event) {
      return this.mouse_over = true;
    };

    Kaliedoscope.prototype.mouseOut = function(event) {
      this.mouse_over = false;
      return this.selected_tris_prev = this.selected_tris = -1;
    };

    Kaliedoscope.prototype.mouseDown = function(event) {
      return this.mouse_pressed = true;
    };

    Kaliedoscope.prototype.mouseUp = function(event) {
      this.mouse_pressed = false;
      this.intersect_prev.set(0, 0, 0);
      this.intersect.set(0, 0, 0);
      if (this.sound_on) {
        this.sounds_long[0].fadeOut(1.0);
        return this.sounds_long[0].playing = false;
      }
    };

    return Kaliedoscope;

  })();

  credits_resize = function() {
    var credits;
    credits = document.getElementById('credits');
    credits.style.left = (window.innerWidth / 2 - credits.clientWidth / 2) + 'px';
    return credits.style.top = (window.innerHeight / 2 - credits.clientHeight / 2) + 'px';
  };

  canvas = document.getElementById('webgl-canvas');

  canvas.width = window.innerWidth;

  canvas.height = window.innerHeight;

  kk = new Kaliedoscope();

  cgl = new CoffeeGL.App('webgl-canvas', kk, kk.init, kk.draw, kk.update);

  if (typeof window !== "undefined" && window !== null) {
    window.addEventListener('resize', kk.resize, false);
  }

  if (typeof window !== "undefined" && window !== null) {
    window.addEventListener('resize', credits_resize, false);
  }

  credits_resize();

}).call(this);
