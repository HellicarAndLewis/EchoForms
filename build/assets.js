// Generated by CoffeeScript 1.6.3
/*
Echo Forms - Hellicar & Lewis
Coding - Benjamin Blundell obj. section9.co.uk
*/


(function() {
  var OpticalFlow, loadAssets;

  OpticalFlow = require('./flow').OpticalFlow;

  loadAssets = function(obj) {
    var a, b, _genLoadAudio, _loadVideo, _loadWebcam,
      _this = this;
    a = function() {
      var i, item, tt, _i, _results;
      _results = [];
      for (i = _i = 0; _i <= 10; i = ++_i) {
        tt = Math.floor(Math.random() * obj.colour_palette.length);
        item = {
          target: obj.colour_palette[tt],
          colour: new CoffeeGL.Colour.RGBA.BLACK(),
          idx: Math.floor(Math.random() * obj.plane.getNumTris())
        };
        _results.push(obj.loading_items.push(item));
      }
      return _results;
    };
    b = function() {
      return obj.state["loaded"] = true;
    };
    obj.lq = new CoffeeGL.Loader.LoadQueue(obj, a, b);
    _loadVideo = new CoffeeGL.Loader.LoadItem(function() {
      var _this = this;
      obj.video_element = document.getElementById("video_default");
      obj.video_element.preload = "auto";
      if (CoffeeGL.Context.profile.browser === "Firefox") {
        obj.video_element.src = "/video_default.ogv";
      } else {
        obj.video_element.src = "/video_default.mp4";
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
        if (!obj.state["video"]) {
          obj.video_element.play();
          obj.t.update(obj.video_element);
          obj.video_node.add(obj.t);
          obj.state["video"] = true;
          _this.loaded();
          return console.log("Video Loaded");
        }
      };
    });
    _loadWebcam = new CoffeeGL.Loader.LoadItem(function() {
      var webcamError,
        _this = this;
      webcamError = function() {
        obj.state["webcam"] = false;
        return _this.loaded();
      };
      obj.webcam_element = document.getElementById("video_webcam");
      obj.webcam_canvas = document.getElementById("webcam_canvas");
      obj.webcam = new CoffeeGL.WebCamRTC("video_webcam", 640, 480, false, webcamError);
      return obj.webcam_element.oncanplay = function(event) {
        if (!obj.state["webcam"]) {
          obj.wt = new CoffeeGL.TextureBase({
            width: obj.webcam_element.videoWidth,
            height: obj.webcam_element.videoHeight,
            unit: 1
          });
          obj.webcam_node.add(obj.wt);
          obj.webcam_element.play();
          obj.video_node.add(obj.wt);
          obj.optical_flow = new OpticalFlow(obj.webcam_element, obj.webcam_canvas, obj.flow_xres, obj.flow_yres);
          obj.state["webcam"] = true;
          return _this.loaded();
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
    if (CoffeeGL.Context.profile.browser === "Chrome") {
      obj.lq.add(_loadWebcam);
    }
    obj.lq.add(_loadVideo);
    obj.lq.start();
    return obj;
  };

  module.exports = {
    loadAssets: loadAssets
  };

}).call(this);
