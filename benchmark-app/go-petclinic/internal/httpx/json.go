package httpx

import (
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
)

// WriteJSON serializes payload as JSON with an optional weak ETag.
func WriteJSON(w http.ResponseWriter, status int, payload any) {
	body, err := json.Marshal(payload)
	if err != nil {
		ServerError(w, err.Error())
		return
	}
	sum := md5.Sum(body)
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("ETag", fmt.Sprintf("W/%q", hex.EncodeToString(sum[:])))
	w.WriteHeader(status)
	_, _ = w.Write(body)
}

// DecodeJSON parses a JSON body into dst or writes a 400 problem and returns false.
func DecodeJSON(w http.ResponseWriter, r *http.Request, dst any) bool {
	dec := json.NewDecoder(r.Body)
	if err := dec.Decode(dst); err != nil {
		BadRequest(w, "invalid JSON body: "+err.Error())
		return false
	}
	return true
}
