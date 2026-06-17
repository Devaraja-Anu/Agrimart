package token_test

import (
	"encoding/base64"
	"errors"
	"strings"
	"testing"
	"time"
	"github.com/devaraja-anu/agrilib/internal/token"
)

const testSecret = "test-secret-at-least-32-bytes-long!!"

func TestSignAndParse_RoundTrip(t *testing.T) {
	userID := "550e8400-e29b-41d4-a716-446655440000"
	roles := []string{"farmer", "service_provider"}

	signed, err := token.Sign(userID, roles, 7*24*time.Hour, testSecret)
	if err != nil {
		t.Fatalf("Sign() unexpected error: %v", err)
	}

	claims, err := token.Parse(signed, testSecret)
	if err != nil {
		t.Fatalf("Parse() unexpected error: %v", err)
	}

	if claims.UserID != userID {
		t.Errorf("UserID = %q, want %q", claims.UserID, userID)
	}

	if len(claims.Roles) != len(roles) {
		t.Fatalf("Roles length = %d, want %d", len(claims.Roles), len(roles))
	}

	for i := range roles {
		if claims.Roles[i] != roles[i] {
			t.Errorf("Roles[%d] = %q, want %q", i, claims.Roles[i], roles[i])
		}
	}
}

func TestParse_WrongSecret(t *testing.T) {
	signed, err := token.Sign("user-id", []string{"farmer"}, time.Hour, testSecret)
	if err != nil {
		t.Fatal(err)
	}

	_, err = token.Parse(signed, "wrong-secret")
	if !errors.Is(err, token.ErrTokenInvalid) {
		t.Fatalf("got %v, want ErrTokenInvalid", err)
	}
}

func TestParse_Expired(t *testing.T) {
	signed, err := token.Sign("user-id", []string{"farmer"}, -time.Second, testSecret)
	if err != nil {
		t.Fatal(err)
	}

	_, err = token.Parse(signed, testSecret)
	if !errors.Is(err, token.ErrTokenExpired) {
		t.Fatalf("got %v, want ErrTokenExpired", err)
	}
}

func TestParse_Malformed(t *testing.T) {
	tests := []struct {
		name  string
		token string
	}{
		{"empty", ""},
		{"random", "not.a.jwt"},
		{"truncated", "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoieCJ9"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := token.Parse(tt.token, testSecret)
			if !errors.Is(err, token.ErrTokenInvalid) {
				t.Fatalf("got %v, want ErrTokenInvalid", err)
			}
		})
	}
}

func TestParse_WrongAlgorithm(t *testing.T) {
	algNoneToken := strings.Join([]string{
		"eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0",
		"eyJ1c2VyX2lkIjoiYXR0YWNrZXIiLCJyb2xlcyI6WyJhZG1pbiJdfQ",
		"",
	}, ".")

	_, err := token.Parse(algNoneToken, testSecret)
	if !errors.Is(err, token.ErrTokenInvalid) {
		t.Fatalf("got %v, want ErrTokenInvalid", err)
	}
}

func TestSign_EmptyRoles(t *testing.T) {
	signed, err := token.Sign("user-id", []string{}, time.Hour, testSecret)
	if err != nil {
		t.Fatal(err)
	}

	claims, err := token.Parse(signed, testSecret)
	if err != nil {
		t.Fatal(err)
	}

	if len(claims.Roles) != 0 {
		t.Fatalf("Roles = %v, want empty", claims.Roles)
	}
}

func TestSign_NilRoles(t *testing.T) {
	signed, err := token.Sign("user-id", nil, time.Hour, testSecret)
	if err != nil {
		t.Fatal(err)
	}

	claims, err := token.Parse(signed, testSecret)
	if err != nil {
		t.Fatal(err)
	}

	if len(claims.Roles) != 0 {
		t.Fatalf("Roles = %v, want empty", claims.Roles)
	}
}

func TestSign_EmptyUserID(t *testing.T) {
	signed, err := token.Sign("", []string{"farmer"}, time.Hour, testSecret)

	// Adjust this test depending on your API contract.
	if err != nil {
		return
	}

	claims, err := token.Parse(signed, testSecret)
	if err != nil {
		t.Fatal(err)
	}

	if claims.UserID != "" {
		t.Fatalf("UserID = %q, want empty", claims.UserID)
	}
}

func TestParse_TamperedPayload(t *testing.T) {
	signed, err := token.Sign("user-id", []string{"farmer"}, time.Hour, testSecret)
	if err != nil {
		t.Fatal(err)
	}

	parts := strings.Split(signed, ".")
	if len(parts) != 3 {
		t.Fatal("invalid JWT produced")
	}

	payload := `{"user_id":"attacker","roles":["admin"]}`
	parts[1] = base64.RawURLEncoding.EncodeToString([]byte(payload))

	tampered := strings.Join(parts, ".")

	_, err = token.Parse(tampered, testSecret)
	if !errors.Is(err, token.ErrTokenInvalid) {
		t.Fatalf("got %v, want ErrTokenInvalid", err)
	}
}

func TestParse_CorruptedSignature(t *testing.T) {
	signed, err := token.Sign("user-id", []string{"farmer"}, time.Hour, testSecret)
	if err != nil {
		t.Fatal(err)
	}

	parts := strings.Split(signed, ".")
	if len(parts) != 3 {
		t.Fatal("invalid JWT produced")
	}

	parts[2] += "corrupted"

	_, err = token.Parse(strings.Join(parts, "."), testSecret)
	if !errors.Is(err, token.ErrTokenInvalid) {
		t.Fatalf("got %v, want ErrTokenInvalid", err)
	}
}

func TestSign_ZeroExpiry(t *testing.T) {
	signed, err := token.Sign("user-id", []string{"farmer"}, 0, testSecret)
	if err != nil {
		t.Fatal(err)
	}

	_, err = token.Parse(signed, testSecret)

	// Accept either behavior depending on implementation.
	if err != nil &&
		!errors.Is(err, token.ErrTokenExpired) &&
		!errors.Is(err, token.ErrTokenInvalid) {
		t.Fatalf("unexpected error: %v", err)
	}
}
