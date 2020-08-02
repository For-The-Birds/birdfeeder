package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"sync"
	"time"

	"github.com/mattetti/filebuffer"
	"github.com/micahwedemeyer/gphoto2go"
)

var camera *gphoto2go.Camera
var mux sync.Mutex

func config(w http.ResponseWriter, r *http.Request) {
	mux.Lock()

	camera.Exit()

	arg := r.FormValue("arg")
	log.Printf("Executing gphoto2 --set-config-index %s", arg)

	cmd := exec.Command("gphoto2", "--set-config-index", arg)
	o, err := cmd.CombinedOutput()
	log.Printf("CombinedOutput: %s", o)
	if err != nil {
		log.Printf("exec error: %s", err.Error())
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "%s", o)
		return
	}
	fmt.Fprintf(w, "%s", o)

	var erri = camera.Init()
	if erri < 0 {
		log.Printf("error camera.Init(): %s (%d)", gphoto2go.CameraResultToString(erri), erri)
	}

	mux.Unlock()
}

func shot(w http.ResponseWriter, r *http.Request) {
	mux.Lock()

	cfp, err := camera.TriggerCaptureToFile()

	if err < 0 {
		log.Printf("capture error: %s (%d)", gphoto2go.CameraResultToString(err), err)
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "capture error: %s (%d)", gphoto2go.CameraResultToString(err), err)
		return
	}

	cameraFileReader := camera.FileReader(cfp.Folder, cfp.Name)
	fb, e := filebuffer.NewFromReader(cameraFileReader)
	if e != nil {
		log.Printf("read file error: %s\n", e.Error())
		fmt.Fprintf(w, "read file error: %s", e.Error())
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	cameraFileReader.Close()

	http.ServeContent(w, r, cfp.Name, time.Now(), fb)
	err = camera.DeleteFile(cfp.Folder, cfp.Name)
	if err < 0 {
		log.Printf("file deletion error: %s (%d)", gphoto2go.CameraResultToString(err), err)
	}

	mux.Unlock()
}

func motion(w http.ResponseWriter, r *http.Request) {
	fi, err := os.Stat("/tmp/motion-detected")
	if os.IsNotExist(err) {
		w.WriteHeader(http.StatusNotFound)
		return
	}
	fmt.Fprintf(w, "%d\n", fi.ModTime().Unix())
}

func main() {
	camera = new(gphoto2go.Camera)

	var err = camera.Init() // this takes about 3 seconds
	if err < 0 {
		log.Printf("error camera.Init(): %s (%d)", gphoto2go.CameraResultToString(err), err)
	}

	http.HandleFunc("/shot", shot)
	http.HandleFunc("/config", config)
	http.HandleFunc("/motion", motion)

	log.Fatal(http.ListenAndServe(":8080", nil))
}
