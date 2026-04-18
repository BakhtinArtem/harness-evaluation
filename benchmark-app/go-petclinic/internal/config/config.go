package config

import (
	"os"
	"strconv"
	"strings"
)

// Config holds runtime configuration sourced from environment variables.
type Config struct {
	Port        int
	APIBase     string
	DatabaseURL string
}

// Load reads environment variables and returns a populated Config.
func Load() Config {
	return Config{
		Port:        getEnvInt("PORT", 9966),
		APIBase:     normalizeBase(getEnv("API_BASE", "/petclinic/api")),
		DatabaseURL: getEnv("DATABASE_URL", "postgres://developer:developer@localhost:5432/mydb?sslmode=disable"),
	}
}

func getEnv(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return fallback
}

func getEnvInt(key string, fallback int) int {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		if i, err := strconv.Atoi(v); err == nil {
			return i
		}
	}
	return fallback
}

func normalizeBase(base string) string {
	if base == "" || base == "/" {
		return ""
	}
	if !strings.HasPrefix(base, "/") {
		base = "/" + base
	}
	return strings.TrimRight(base, "/")
}
