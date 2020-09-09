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
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "%s", o)
		log.Fatalf("exec error: %s", err.Error())
		return
	}
	fmt.Fprintf(w, "%s", o)

	time.Sleep(500 * time.Millisecond)

	var erri = camera.Init()
	if erri < 0 {
		log.Fatalf("error camera.Init() after config: %s (%d)", gphoto2go.CameraResultToString(erri), erri)
	}

	mux.Unlock()
}

func shot(w http.ResponseWriter, r *http.Request) {
	mux.Lock()

	cfp, err := camera.TriggerCaptureToFile()

	if err < 0 {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "capture error: %s (%d)", gphoto2go.CameraResultToString(err), err)
		log.Fatalf("capture error: %s (%d)", gphoto2go.CameraResultToString(err), err)
		return
	}

	cameraFileReader := camera.FileReader(cfp.Folder, cfp.Name)
	fb, e := filebuffer.NewFromReader(cameraFileReader)
	if e != nil {
		fmt.Fprintf(w, "read file error: %s", e.Error())
		w.WriteHeader(http.StatusInternalServerError)
		log.Fatalf("read file error: %s\n", e.Error())
		return
	}

	cameraFileReader.Close()

	http.ServeContent(w, r, cfp.Name, time.Now(), fb)
	err = camera.DeleteFile(cfp.Folder, cfp.Name)
	if err < 0 {
		log.Fatalf("file deletion error: %s (%d)", gphoto2go.CameraResultToString(err), err)
	}

	mux.Unlock()
}

func exit(w http.ResponseWriter, r *http.Request) {
	log.Printf("exiting by request")
	os.Exit(0)
}

func reboot(w http.ResponseWriter, r *http.Request) {
	exec.Command("sudo", "reboot").Run()
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
		log.Fatalf("error camera.Init(): %s (%d)", gphoto2go.CameraResultToString(err), err)
	}

	http.HandleFunc("/shot", shot)
	http.HandleFunc("/config", config)
	http.HandleFunc("/motion", motion)
	http.HandleFunc("/reboot", reboot)
	http.HandleFunc("/exit", exit)

	log.Fatal(http.ListenAndServe(":8080", nil))
}
