package store

import (
	_ "embed"
	"fmt"
	"log"
	"strings"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

//go:embed schema.sql
var schemaSQL string

//go:embed data.sql
var dataSQL string

// Open connects to the given Postgres URL, retrying for a short window so the
// server can start alongside a freshly launched database container.
func Open(dsn string) (*gorm.DB, error) {
	var db *gorm.DB
	var err error
	cfg := &gorm.Config{
		Logger: logger.Default.LogMode(logger.Error),
	}
	for i := 0; i < 30; i++ {
		db, err = gorm.Open(postgres.Open(dsn), cfg)
		if err == nil {
			sqlDB, derr := db.DB()
			if derr == nil {
				if perr := sqlDB.Ping(); perr == nil {
					return db, nil
				}
			}
		}
		log.Printf("waiting for postgres (%d/30): %v", i+1, err)
		time.Sleep(time.Second)
	}
	return nil, fmt.Errorf("connect postgres: %w", err)
}

// Migrate executes the embedded Postgres schema script.
func Migrate(db *gorm.DB) error {
	return execScript(db, schemaSQL)
}

// Seed executes the embedded Postgres seed script.
func Seed(db *gorm.DB) error {
	return execScript(db, dataSQL)
}

func execScript(db *gorm.DB, script string) error {
	for _, stmt := range splitStatements(script) {
		if stmt == "" {
			continue
		}
		if err := db.Exec(stmt).Error; err != nil {
			return fmt.Errorf("exec %q: %w", truncate(stmt, 80), err)
		}
	}
	return nil
}

func splitStatements(script string) []string {
	parts := strings.Split(script, ";")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p == "" {
			continue
		}
		out = append(out, p)
	}
	return out
}

func truncate(s string, n int) string {
	s = strings.ReplaceAll(s, "\n", " ")
	if len(s) <= n {
		return s
	}
	return s[:n] + "..."
}
