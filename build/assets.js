// Generated by CoffeeScript 1.6.3
/*
Echo Forms - Hellicar & Lewis
Coding - Benjamin Blundell obj. section9.co.uk
*/


(function() {
  var OpticalFlow, loadAssets;

  OpticalFlow = require('./flow').OpticalFlow;

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
      obj.video_element = document.getElementById("video_lexus");
      obj.video_element.preload = "auto";
      if (CoffeeGL.Context.profile.browser === "Firefox") {
        obj.video_element.src = "/H&L-Lexus-Edit01-final01.ogv";
      } else {
        obj.video_element.src = "/H&L-Lexus-Edit01-final01.mp4";
      }
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
      obj.webcam_element = document.getElementById("video_webcam");
      obj.webcam_canvas = document.getElementById("webcam-canvas");
      obj.webcam = new CoffeeGL.WebCamRTC("video_webcam", 640, 480, false);
      return obj.webcam_element.oncanplay = function(event) {
        if (!obj.webcam_ready) {
          obj.wt = new CoffeeGL.TextureBase({
            width: obj.webcam_element.videoWidth,
            height: obj.webcam_element.videoHeight,
            unit: 1
          });
          obj.webcam_node.add(obj.wt);
          obj.webcam_element.play();
          obj.webcam_ready = true;
          obj.video_node.add(obj.wt);
          obj.optical_flow = new OpticalFlow(obj.webcam_element, obj.webcam_canvas, obj.plane_xres, obj.plane_yres);
          obj.datg.add(obj.optical_flow.options, 'win_size', 7, 30).step(1);
          obj.datg.add(obj.optical_flow.options, 'max_iterations', 3, 30).step(1);
          obj.datg.add(obj.optical_flow.options, 'epsilon', 0.001, 0.1).step(0.0025);
          obj.datg.add(obj.optical_flow.options, 'min_eigen', 0.001, 0.01).step(0.0001);
          _this.loaded();
          return console.log("Webcam Loaded", obj.webcam_element.videoWidth, obj.webcam_element.videoHeight);
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
    obj.lq.add(_loadWebcam);
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
