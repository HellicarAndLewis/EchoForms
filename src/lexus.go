package main

import (
  "fmt"
  "net"
  //"io/ioutil"
  "net/http"
  //"net/url"
  "net/http/fcgi"
  "os/exec"
  //"regexp"
  "os"
  "os/signal"
  "syscall"
  "log"
)

// Basic script that queries the external program youtube-dl for the real URL, given an ID

// Run like thus.
// sudo su - www-data -c "go run /srv/www/section9.co.uk/public_html/lexus/lexus.go"

var (
    abort bool
)

const (
    SOCK = "/tmp/lexus.sock"
)

type Server struct {
}

// youtube-dl calling function

func get_youtube_url (video_id string) (real_url string) {
  
  // Annoyingly this does have quite a delay
  cmd := exec.Command("youtube-dl", "-g", "https://www.youtube.com/watch?v=" + video_id)
  out, err := cmd.CombinedOutput()
  if err != nil {
    log.Fatal(err)
    real_url = "error"
    return
  }
  real_url = string(out)
  return

  /*base_url := "http://www.youtube.com/get_video_info?html5=1&video_id="
  resp, err := http.Get(base_url + video_id)
  re := regexp.MustCompile("url_encoded_fmt_stream_map=([^&]*)&")
  defer resp.Body.Close()
  body, err := ioutil.ReadAll(resp.Body)
  
  if err != nil {
    real_url = "error in read"
    return
  }

  real_url = string(body)

  segs2 := re.FindAllStringSubmatch(string(body), -1)
  if len(segs2) > 0 {

    data, err := url.QueryUnescape(segs2[0][0])

    if err != nil {
      real_url = "error in escape"
      return
    }

    real_url = data
  }


  return*/
}

// Addition to the server to serve http requests

func (s Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {

     // Try to keep the same amount of headers
    w.Header().Set("Server", "gophr")
    w.Header().Set("Connection", "keep-alive")
    w.Header().Set("Content-Type", "text/plain")

    body := "error"
  
    r.ParseForm()

    if r.Form.Get("id") != "" {
      real_url := get_youtube_url( string(r.Form.Get("id")))
      body = real_url
    }

    w.Header().Set("Content-Length", fmt.Sprint(len(body)))
    fmt.Fprint(w, body)
    
}

// Main Loop

func main() {
  
  sigchan := make(chan os.Signal, 1)
  signal.Notify(sigchan, os.Interrupt)
  signal.Notify(sigchan, syscall.SIGTERM)

  server := Server{}

  go func() {
    unix, err := net.Listen("unix", SOCK)
    if err != nil {
      log.Fatal(err)
    }
    fcgi.Serve(unix, server)
  }()

  <-sigchan

  if err := os.Remove(SOCK); err != nil {
    log.Fatal(err)
  }

}
