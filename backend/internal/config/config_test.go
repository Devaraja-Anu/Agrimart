package config

import (
	"testing"
)
func TestSecretMasking(t *testing.T) {
    tests := []struct {
        name   string
        input  string
        expect string
    }{
        {"standard secret", "super-secret-value", "********"},
        {"empty secret", "", "********"},
        {"special chars", "!@#$%^&*", "********"},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            s := secret(tt.input)
            if s.LogValue().String() != tt.expect {
                t.Errorf("LogValue() = %q; want %q", s.LogValue().String(), tt.expect)
            }
            if s.String() != tt.expect {
                t.Errorf("fmt.Sprintf = %q; want %q", s.String(), tt.expect)
            }
        })
    }
}

func TestSecretReveal(t *testing.T){
	val := "super-secret-value"
	s := secret(val)
	
	if s.Reveal() != val {
		t.Errorf("Reveal() = %q, want %q",s.Reveal(),val)
	}
}