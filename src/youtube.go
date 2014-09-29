package main

import (
  //"fmt"
  "net"
  "io"
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
  "crypto/tls"
  "strings"
)

// Basic script that queries the external program youtube-dl for the real URL, given an ID

// Run like thus.
// sudo su - www-data -c "go run /srv/www/dejima.section9.co.uk/public_html/youtube_proxy/youtube_proxy.go"

var (
    abort bool
)

const (
    SOCK = "/tmp/youtube_proxy.sock"
)

type Server struct {
}

// youtube-dl calling function

func get_youtube_url (video_id string) (real_url string, err error) {
  
  // Annoyingly this does have quite a delay
  cmd := exec.Command("youtube-dl", "-g", video_id)
  out, err := cmd.CombinedOutput()
  if err != nil {
    log.Print("Youtube-dl failure", video_id)
    real_url = "error"
    return
  }
  ss := string(out)
  ss = strings.Replace(ss,"\n","",-1)
  real_url = ss
  return

}

// Addition to the server to serve http requests

func (s Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
  
    r.ParseForm()

    if r.Form.Get("id") != "" {
      real_url, err := get_youtube_url( string(r.Form.Get("id")))
      if err != nil{
        log.Print("FATAL!")
        log.Print(err)
      }

      log.Print(real_url)
      
      // Now we need to grab and stream back

      tr := &http.Transport{
        TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
      }
 
      client := &http.Client{Transport: tr}
  
      // Tweak the request as appropriate:
      /*
      u, err := url.Parse(real_url)
      if err != nil {
        log.Fatal(err)
      }
      log.Print("Parsed URL: ", u)
      */
      
      // There appears to be an error with the string returned from get_youtube_url - no idea what :S
      // Could be \n?

      // And proxy
      //resp, err := client.Get("https://r2---sn-aiglln67.googlevideo.com/videoplayback?itag=22&mv=u&mt=1411571402&sparams=id%2Cip%2Cipbits%2Citag%2Cmm%2Cms%2Cmv%2Cnh%2Cratebypass%2Crequiressl%2Csource%2Cupn%2Cexpire&ms=au&id=o-ALH-6sg67PSlCMPcxr9hciDKCbwI7IgSRH69Zqq_VnlS&fexp=907257%2C912104%2C915516%2C916637%2C927622%2C930666%2C931983%2C932404%2C934030%2C934929%2C936214%2C945035%2C946011%2C947209%2C951812%2C952302%2C953801&source=youtube&expire=1411593099&sver=3&key=yt5&ip=2001%3Aba8%3A1f1%3Af1db%3A%3A2&nh=IgpwcjAxLmxocjE0KgkxMjcuMC4wLjE&requiressl=yes&upn=Wur0ei8UFUU&signature=D92320866758C6184698B2249F6FF0E3620E0978.BB7340C9A23D265DF500FAE7B87C2AA7787529C9&mm=31&ipbits=0&ratebypass=yes")   
     
      //Res http.ResponseWriter
      //Rc io.ReadCloser
      //ytbody := http.MaxBytesReader(http.ResponseWriter(), io.ReadCloser() , 1024)  
      //ytreq,err := http.NewRequest("GET", real_url, ytbody)
      //resp, err := client.Do(ytreq)

      w.Header().Set("Server", "gophr")
      

      resp, err := client.Get(real_url)
      defer resp.Body.Close()

      if err != nil {
        log.Print("FATAL!")
        log.Print(err)
        w.Header().Set("StatusCode", "404")
        return

      }
      
      log.Print("Response:", resp)

      //body, err := ioutil.ReadAll(resp.Body)
      
      if err != nil {
        log.Print("FATAL!")
        log.Print(err)
        w.Header().Set("StatusCode","404")
        return
        
      }

      w.Header().Set("Connection", "keep-alive")
      w.Header().Set("Content-Type", "video/mp4")
      //w.Header().Set("Content-Type", "text/html")
      //w.Header().Set("Content-Length", fmt.Sprint(len(body)))

      //log.Print("Body Size:", fmt.Sprint(len(body)))
      //w.Write(body)
      //w.Write(resp.Body)
      io.Copy(w, resp.Body)
    } else {
      w.Header().Set("StatusCode", "404")
    }
    
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
      log.Print("Fatal Error in Listening Socket.")
      log.Fatal(err)
    }
    fcgi.Serve(unix, server)
  }()


  <-sigchan

  if err := os.Remove(SOCK); err != nil {
    log.Fatal(err)
  }

}
