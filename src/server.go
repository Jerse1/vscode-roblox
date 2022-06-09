package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
)

const format = "%s_%s" // Script name, Oid
const dir_format = "temp\\%s.lua"

func main() {
	_, err := os.Stat("temp")
	if os.IsNotExist(err) {

		err := os.Mkdir("temp", 0755)
		if err != nil {
			log.Fatal(err)
		}
	}

	openScripts := make(map[string]bool)

	items, _ := ioutil.ReadDir("temp.")
	for _, item := range items {
		if !item.IsDir() {
			scriptName := strings.ReplaceAll(item.Name(), ".lua", "")
			_, ok := openScripts[scriptName]

			if !ok {
				openScripts[scriptName] = true
				fmt.Printf("Added in " + scriptName + " to openScripts map\n")
			}
		}
	}

	http.HandleFunc("/", handleRequest)

	//! OPENING A SCRIPT
	http.HandleFunc("/open/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/open/" {
			http.Error(w, "404 not found.", http.StatusNotFound)
			return
		}

		switch r.Method {
		case "POST":
			d := json.NewDecoder(r.Body)
			d.DisallowUnknownFields() // catch unwanted fields

			// anonymous struct type: handy for one-time use
			t := struct {
				Name   *string `json:"Name"`
				Oid    *string `json:"Oid"`
				Source *string `json:"Source"`
			}{}

			err := d.Decode(&t)
			if err != nil {
				// bad JSON or unrecognized json field
				http.Error(w, err.Error(), http.StatusBadRequest)
				return
			}

			if t.Name == nil {
				http.Error(w, "missing field 'Name' from JSON object", http.StatusBadRequest)
				return
			}
			if t.Oid == nil {
				http.Error(w, "missing field 'Oid' from JSON object", http.StatusBadRequest)
				return
			}

			// got the input we expected: no more, no less
			log.Println(*t.Name)

			Name := *t.Name
			Oid := *t.Oid
			Source := *t.Source

			filename := fmt.Sprintf(format, Name, Oid)

			_, ok := openScripts[filename]

			if ok {
				fmt.Printf("Script [" + filename + "] is already present\n")
			} else {
				fmt.Printf("Script [" + filename + "] is opening\n")
				openScripts[filename] = true
				dir := fmt.Sprintf(dir_format, filename)

				file, ok := os.Create(dir)
				if ok != nil {
					log.Panicln(ok)
				}

				fmt.Fprintln(file, Source)

				cmd := exec.Command("code", dir)

				_, err := cmd.CombinedOutput()
				if err != nil {
					log.Fatalf("cmd.Run() failed with %s\n", err)
				}
			}
		}
	})

	//! RETRIEVING OPEN SCRIPTS
	http.HandleFunc("/retrieve/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/retrieve/" {
			http.Error(w, "404 not found.", http.StatusNotFound)
			return
		}
		switch r.Method {
		case "GET":
			Data := map[string]map[string]string{}
			Data["Changes"] = make(map[string]string)
			for filename := range openScripts {
				_, err := os.Stat(fmt.Sprintf(dir_format, filename))

				if err != nil {
					if os.IsNotExist(err) {
						delete(openScripts, filename)
					}
				}

				data, err := ioutil.ReadFile(fmt.Sprintf(dir_format, filename))
				if err != nil {

					fmt.Println("File reading error", err)
					return
				}

				Data["Changes"][filename] = string(data)
			}

			jData, err := json.Marshal(Data)
			if err != nil {
				log.Panicln(err)
			}
			w.Header().Set("Content-Type", "application/json")
			w.Write(jData)
		}

	})

	//! CLOSING A SCRIPT
	http.HandleFunc("/close/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/close/" {
			http.Error(w, "404 not found.", http.StatusNotFound)
			return
		}

		switch r.Method {
		case "POST":
			d := json.NewDecoder(r.Body)
			d.DisallowUnknownFields() // catch unwanted fields

			// anonymous struct type: handy for one-time use
			t := struct {
				Name *string `json:"Name"`
				Oid  *string `json:"Oid"`
			}{}

			err := d.Decode(&t)
			if err != nil {
				// bad JSON or unrecognized json field
				http.Error(w, err.Error(), http.StatusBadRequest)
				return
			}

			if t.Name == nil {
				http.Error(w, "missing field 'Name' from JSON object", http.StatusBadRequest)
				return
			}
			if t.Oid == nil {
				http.Error(w, "missing field 'Oid' from JSON object", http.StatusBadRequest)
				return
			}

			// got the input we expected: no more, no less
			log.Println(*t.Name)

			Name := *t.Name
			Oid := *t.Oid

			filename := fmt.Sprintf(format, Name, Oid)

			_, ok := openScripts[filename]

			if ok {
				delete(openScripts, filename)

				err := os.Remove(fmt.Sprintf(dir_format, filename))

				if err != nil {
					fmt.Println(err)
					return
				}
			}
		}
	})

	//! CONNECTING
	http.HandleFunc("/connect", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/connect" {
			http.Error(w, "404 not found.", http.StatusNotFound)
			return
		}

		if r.Method == "CONNECT" {
			fmt.Printf("Connecting")
		}
	})

	fmt.Printf("Starting server for testing HTTP POST...\n")
	if err := http.ListenAndServe(":8000", nil); err != nil {
		log.Fatal(err)
	}
}

func handleRequest(w http.ResponseWriter, r *http.Request) {

	switch r.Method {
	case "GET":
		w.Write([]byte("hell"))

	}

}
