;(function(e,t,n){function r(n,i){if(!t[n]){if(!e[n]){var s=typeof require=="function"&&require;if(!i&&s)return s(n,!0);throw new Error("Cannot find module '"+n+"'")}var o=t[n]={exports:{}};e[n][0](function(t){var i=e[n][1][t];return r(i?i:t)},o,o.exports)}return t[n].exports}for(var i=0;i<n.length;i++)r(n[i]);return r})({1:[function(require,module,exports){
// Generated by CoffeeScript 1.6.3
/*
Echo Forms - Hellicar & Lewis
Coding - Benjamin Blundell @ section9.co.uk


http://stackoverflow.com/questions/13739901/vertex-kaleidoscope-shader
*/


(function() {
  var Kaliedoscope, canvas, credits_resize, kaliedoscopeWebGL, kk, loadAssets, params,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  loadAssets = require('./assets').loadAssets;

  Kaliedoscope = (function() {
    function Kaliedoscope() {
      this.resize = __bind(this.resize, this);
    }

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
      if (!this.mouse_pressed) {
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
      var i, r2, r3, _i,
        _this = this;
      if (this.state_ready == null) {
        this.state_ready = false;
      }
      if (this.state_loaded == null) {
        this.state_loaded = false;
        this.loading_items = [];
        this.loading_timeout = 0;
        this.ready_fade_in = 0;
        this.loading_time_limit = 3;
        this.ready_fade_time = 3;
      }
      this.noise = new CoffeeGL.Noise.Noise();
      this.noise.setSeed(Math.random());
      if (this.colour_palette == null) {
        this.colour_palette = [new CoffeeGL.Colour.RGBA(31, 169, 225), new CoffeeGL.Colour.RGBA(34, 54, 107), new CoffeeGL.Colour.RGBA(240, 77, 35), new CoffeeGL.Colour.RGBA(228, 198, 158), new CoffeeGL.Colour.RGBA(195, 206, 207)];
      }
      this.plane_yres = 7;
      this.plane_xres = 15;
      this.setupPlane();
      this.video_node = new CoffeeGL.Node(this.plane);
      this.face_node = new CoffeeGL.Node(this.plane_face);
      this.video_node.brew({
        position_buffer_access: GL.DYNAMIC_DRAW,
        texcoord_buffer_access: GL.DYNAMIC_DRAW
      });
      this.face_node.brew({
        position_buffer_access: GL.DYNAMIC_DRAW,
        colour_buffer_access: GL.DYNAMIC_DRAW
      });
      this.geomTrans(CoffeeGL.Context.width, CoffeeGL.Context.height);
      r2 = new CoffeeGL.Request('/basic_texture.glsl');
      r2.get(function(data) {
        return _this.shader = new CoffeeGL.Shader(data);
      });
      r3 = new CoffeeGL.Request('/face.glsl');
      r3.get(function(data) {
        _this.shader_face = new CoffeeGL.Shader(data);
        _this.shader_face.bind();
        return _this.shader_face.setUniform1f("uAlphaScalar", _this.highLight.alpha_scalar);
      });
      this.ray = new CoffeeGL.Vec3(0, 0, 0);
      this.intersect_prev = new CoffeeGL.Vec3(0, 0, 0);
      this.intersect = new CoffeeGL.Vec3(0, 0, 0);
      this.selected_tris = this.selected_tris_prev = -1;
      this.warp = {
        exponent: 2,
        force: 0.004 + (Math.random() * 0.001),
        range: 2.0 + (Math.random() * 0.5),
        falloff_factor: 1.0,
        springiness: 0.0019 + (Math.random() * 0.01),
        springiness_exponent: 2.0,
        rot_speed: 4.0,
        spring_damping: 0.26 + (Math.random() * 0.5),
        natural_rate: 0.9,
        natural_force: 0.002
      };
      this.highLight = {
        speed_in: 0.1 + (-0.01 + Math.random() * 0.02),
        speed_out: 0.009 + (Math.random() * 0.01),
        alpha_scalar: 0.24 + (Math.random() * 0.01)
      };
      this.sound_long_playing = false;
      this.sound_on = true;
      this.sound_short_triggers = [];
      if (!this.state_loaded) {
        this.sounds_long = [];
        this.sounds_short = [];
      }
      for (i = _i = 0; _i <= 100; i = ++_i) {
        this.sound_short_triggers.push(Math.floor(Math.random() * this.plane.getNumTris()));
      }
      this.camera = new CoffeeGL.Camera.PerspCamera();
      this.camera.pos.z = 3.8;
      this.camera.near = 0.001;
      this.camera.far = 8.0;
      this.camera.setViewport(CoffeeGL.Context.width, CoffeeGL.Context.height);
      this.video_node.add(this.camera);
      this.face_node.add(this.camera);
      this.t = new CoffeeGL.TextureBase({
        width: 256,
        height: 256
      });
      GL.enable(GL.BLEND);
      GL.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
      if (this.video_ready == null) {
        this.video_ready = false;
      } else {
        this.video_element.play();
        this.video_node.add(this.t);
      }
      if (this.webcam_ready == null) {
        this.webcam_ready = false;
      } else {
        this.webcam_node.add(this.wt);
      }
      if (!this.state_loaded) {
        loadAssets(this);
      }
      /*
      datg = new dat.GUI()
      datg.remember(@)
      
      datg.add(@warp,'exponent',1.0,5.0)
      datg.add(@warp,'force',0.0001,0.01)
      datg.add(@warp,'range',0.1,5.0)
      datg.add(@warp,'springiness', 0.0001, 0.01)
      datg.add(@warp,'spring_damping', 0.1, 1.0)
      datg.add(@warp,'rot_speed', 0.01, 10.0)
      datg.add(@warp,'natural_rate', 0.1, 1.0)
      datg.add(@warp,'natural_force', 0.0001, 0.01)
      datg.add(@,'sound_on')
      datg.add(@highLight,'speed_in', 0.001, 0.1)
      datg.add(@highLight,'speed_out', 0.001, 0.1)
      datg.add(@highLight, 'alpha_scalar',0.1,1.0)
      
      datg.add(@dof_params,'focal_range', 0.001, 1.0)
      datg.add(@dof_params, 'focal_distance',0.1,10.0)
      */

      CoffeeGL.Context.mouseMove.add(this.mouseMoved, this);
      CoffeeGL.Context.mouseOut.add(this.mouseOut, this);
      CoffeeGL.Context.mouseOver.add(this.mouseOver, this);
      CoffeeGL.Context.mouseDown.add(this.mouseDown, this);
      CoffeeGL.Context.mouseUp.add(this.mouseUp, this);
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
      if (this.webcam_ready) {
        this.wt.update(this.webcam.dom_object);
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
        return this.updateActual();
      } else {
        this.updateLoading();
        this.loading_timeout += dt / 1000;
        if (this.state_loaded && this.loading_timeout > this.loading_time_limit) {
          this.state_ready = true;
          credits = document.getElementById('credits');
          return credits.style.display = 'none';
        }
      }
    };

    Kaliedoscope.prototype.drawActual = function() {
      GL.clearColor(0.15, 0.15, 0.15, 1.0);
      GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
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

    /*
    touchSwipe : (event) ->
      @mouse_over = true
      @mouse_pressed = true
    
      for touch in CoffeeGL.Context.ongoingTouches
        @interact touch.ppos.x, touch.ppos.y
    */


    Kaliedoscope.prototype.mouseOver = function(event) {};

    Kaliedoscope.prototype.mouseOut = function(event) {
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

    Kaliedoscope.prototype.shutdown = function() {
      var sound_short_triggers, video;
      sound_short_triggers = [];
      video = document.getElementById("video");
      video.pause();
      video.currentTime = 0;
      this.video_node.washup();
      this.face_node.washup();
      delete this.video_node;
      delete this.face_node;
      this.t.washup();
      return delete this.t;
    };

    return Kaliedoscope;

  })();

  credits_resize = function() {
    var credits;
    credits = document.getElementById('credits');
    credits.style.left = (window.innerWidth / 2 - credits.clientWidth / 2) + 'px';
    return credits.style.top = (window.innerHeight / 2 - credits.clientHeight / 2) + 'px';
  };

  window.notSupported = function() {
    $('#webgl-canvas').remove();
    return $('#credits').append('<h3>Your browser does not support WebGL</h3><p>Visit <a href="http://get.webgl.org">get.webgl.org</a> to learn more.</p>');
  };

  canvas = document.getElementById('webgl-canvas');

  canvas.width = window.innerWidth;

  canvas.height = window.innerHeight;

  kk = new Kaliedoscope();

  params = {
    canvas: 'webgl-canvas',
    context: kk,
    init: kk.init,
    draw: kk.draw,
    update: kk.update,
    error: window.notSupported,
    delay_start: false,
    shutdown: kk.shutdown
  };

  kaliedoscopeWebGL = new CoffeeGL.App(params);

  /*
  keypressed = (event) ->
    if event.keyCode == 115
      kaliedoscopeWebGL.shutdown()
    else if event.keyCode == 103
      kaliedoscopeWebGL.startup()
  */


  if (typeof window !== "undefined" && window !== null) {
    window.addEventListener('resize', kk.resize, false);
  }

  if (typeof window !== "undefined" && window !== null) {
    window.addEventListener('resize', credits_resize, false);
  }

  credits_resize();

}).call(this);

},{"./assets":2}],2:[function(require,module,exports){
// Generated by CoffeeScript 1.6.3
/*
Echo Forms - Hellicar & Lewis
Coding - Benjamin Blundell obj. section9.co.uk
*/


(function() {
  var loadAssets;

  loadAssets = function(obj) {
    var a, b, i, _genLoadAudio, _i, _loadVideo, _loadWebcam,
      _this = this;
    a = function() {
      var i, item, tt, _i;
      for (i = _i = 0; _i <= 10; i = ++_i) {
        tt = Math.floor(Math.random() * obj.colour_palette.length);
        item = {
          target: obj.colour_palette[tt],
          colour: new CoffeeGL.Colour.RGBA.BLACK(),
          idx: Math.floor(Math.random() * obj.plane.getNumTris())
        };
        obj.loading_items.push(item);
      }
      return console.log("Loaded: " + obj.lq.completed_items.length / obj.lq.items.length);
    };
    b = function() {
      console.log("Loaded All");
      return obj.state_loaded = true;
    };
    obj.lq = new CoffeeGL.Loader.LoadQueue(obj, a, b);
    _loadVideo = new CoffeeGL.Loader.LoadItem(function() {
      var _this = this;
      obj.video_element = document.getElementById("video");
      obj.video_element.preload = "auto";
      obj.video_element.src = "/H&L-Lexus-Edit01-final01.mp4";
      obj.video_element.addEventListener("ended", function() {
        obj.video_element.currentTime = 0;
        return obj.video_element.play();
      }, false);
      obj.video_element.addEventListener("timeupdate", function() {
        if (obj.video_element.currentTime > 53) {
          obj.video_element.pause();
          obj.video_element.currentTime = 0;
          obj.video_element.play();
        }
      }, false);
      return obj.video_element.oncanplay = function(event) {
        if (!obj.video_ready) {
          obj.video_element.play();
          obj.t.update(obj.video_element);
          obj.video_node.add(obj.t);
          obj.video_ready = true;
          _this.loaded();
          return console.log("Video Loaded");
        }
      };
    });
    _loadWebcam = new CoffeeGL.Loader.LoadItem(function() {
      var _this = this;
      self.webcam_element = document.getElementById("video_webcam");
      self.webcam = CoffeeGL.WebCamRTC("video_webcam");
      return self.webcam_element.oncanplay = function(event) {
        if (!self.webcam_ready) {
          self.webcam_element.play();
          self.webcam_ready = true;
          obj.loaded();
          return console.log("Webcam Loaded");
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
            obj.playing = true;
            if (long) {
              return self.sound_long_playing = true;
            }
          },
          onend: function() {
            obj.playing = false;
            if (long) {
              return self.sound_long_playing = false;
            }
          }
        });
        return _loadAudioSample;
      });
    };
    obj.lq.add(_loadVideo);
    obj.lq.add(_genLoadAudio('/sound/long/Lexus.mp3', obj.sounds_long, true));
    for (i = _i = 0; _i <= 5; i = ++_i) {
      obj.lq.add(_genLoadAudio('/sound/short/sound00' + i + '.mp3', obj.sounds_short, false));
    }
    obj.lq.start();
    return obj;
  };

  module.exports = {
    loadAssets: loadAssets
  };

}).call(this);

},{}]},{},[1])
;