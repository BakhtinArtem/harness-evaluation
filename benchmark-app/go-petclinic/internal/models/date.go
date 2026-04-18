package models

import (
	"database/sql/driver"
	"fmt"
	"strings"
	"time"
)

// LocalDate is an ISO-8601 (YYYY-MM-DD) date that round-trips through JSON and
// SQL as a date-only value, matching Spring's LocalDate serialization.
type LocalDate struct {
	time.Time
}

const localDateLayout = "2006-01-02"

// MarshalJSON renders the date as a quoted "YYYY-MM-DD" string.
func (d LocalDate) MarshalJSON() ([]byte, error) {
	if d.Time.IsZero() {
		return []byte("null"), nil
	}
	return []byte(fmt.Sprintf("%q", d.Time.Format(localDateLayout))), nil
}

// UnmarshalJSON accepts a quoted "YYYY-MM-DD" string or null.
func (d *LocalDate) UnmarshalJSON(b []byte) error {
	s := strings.Trim(string(b), "\"")
	if s == "" || s == "null" {
		d.Time = time.Time{}
		return nil
	}
	t, err := time.Parse(localDateLayout, s)
	if err != nil {
		return err
	}
	d.Time = t
	return nil
}

// Value implements driver.Valuer so GORM can insert date values.
func (d LocalDate) Value() (driver.Value, error) {
	if d.Time.IsZero() {
		return nil, nil
	}
	return d.Time.Format(localDateLayout), nil
}

// Scan implements sql.Scanner for date columns read back from Postgres.
func (d *LocalDate) Scan(src any) error {
	if src == nil {
		d.Time = time.Time{}
		return nil
	}
	switch v := src.(type) {
	case time.Time:
		d.Time = v
		return nil
	case []byte:
		t, err := time.Parse(localDateLayout, string(v))
		if err != nil {
			return err
		}
		d.Time = t
		return nil
	case string:
		t, err := time.Parse(localDateLayout, v)
		if err != nil {
			return err
		}
		d.Time = t
		return nil
	}
	return fmt.Errorf("LocalDate.Scan: unsupported type %T", src)
}
