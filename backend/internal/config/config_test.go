package config

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestSecretMasking(t *testing.T) {
	tests := []struct {
		name  string
		input string
	}{
		{"standard", "super-secret"},
		{"empty", ""},
		{"special chars", "!@#$%^"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			s := secret(tt.input)

			require.Equal(t, "********", s.String())
			require.Equal(t, "********", s.LogValue().String())
		})
	}
}

func TestSecretReveal(t *testing.T) {
	s := secret("super-secret")

	require.Equal(t, "super-secret", s.Reveal())
}

func TestGetEnv(t *testing.T) {
	t.Setenv("TEST_ENV", "value")

	require.Equal(t, "value", getEnv("TEST_ENV", "fallback"))
	require.Equal(t, "fallback", getEnv("DOES_NOT_EXIST", "fallback"))
}

func TestSplitNonEmpty(t *testing.T) {
	tests := []struct {
		name string
		in   string
		want []string
	}{
		{"empty", "", nil},
		{"single", "abc", []string{"abc"}},
		{"multiple", "a,b,c", []string{"a", "b", "c"}},
		{"spaces", " a , b , c ", []string{"a", "b", "c"}},
		{"empty elements", "a,,b,", []string{"a", "b"}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			require.Equal(t, tt.want, splitNonEmpty(tt.in))
		})
	}
}

func TestValidateSuccess(t *testing.T) {
	cfg := Config{
		DatabaseURL: "postgres://localhost/db",
		IPStrategy:  IPStrategyRemoteAddr,
	}

	require.NoError(t, cfg.validate())
}

func TestValidateMissingDatabaseURL(t *testing.T) {
	cfg := Config{
		IPStrategy: IPStrategyRemoteAddr,
	}

	err := cfg.validate()

	require.Error(t, err)
	require.Contains(t, err.Error(), "DATABASE_URL")
}

func TestValidateInvalidIPStrategy(t *testing.T) {
	cfg := Config{
		DatabaseURL: "postgres://localhost/db",
		IPStrategy:  IPStrategy("banana"),
	}

	require.Error(t, cfg.validate())
}

func TestValidateXFFTrusted(t *testing.T) {
	t.Run("missing CIDRs", func(t *testing.T) {
		cfg := Config{
			DatabaseURL: "postgres://localhost/db",
			IPStrategy:  IPStrategyXFFTrusted,
		}

		require.Error(t, cfg.validate())
	})

	t.Run("invalid CIDR", func(t *testing.T) {
		cfg := Config{
			DatabaseURL:       "postgres://localhost/db",
			IPStrategy:        IPStrategyXFFTrusted,
			TrustedProxyCIDRs: []string{"banana"},
		}

		require.Error(t, cfg.validate())
	})

	t.Run("valid CIDRs", func(t *testing.T) {
		cfg := Config{
			DatabaseURL: "postgres://localhost/db",
			IPStrategy:  IPStrategyXFFTrusted,
			TrustedProxyCIDRs: []string{
				"10.0.0.0/8",
				"192.168.0.0/16",
			},
		}

		require.NoError(t, cfg.validate())
	})
}

func TestValidateCustomHeader(t *testing.T) {
	t.Run("missing header", func(t *testing.T) {
		cfg := Config{
			DatabaseURL: "postgres://localhost/db",
			IPStrategy:  IPStrategyCustomHeader,
		}

		require.Error(t, cfg.validate())
	})

	t.Run("valid header", func(t *testing.T) {
		cfg := Config{
			DatabaseURL:   "postgres://localhost/db",
			IPStrategy:    IPStrategyCustomHeader,
			ClientIPHeader: "X-Forwarded-For",
		}

		require.NoError(t, cfg.validate())
	})
}

func TestLoad(t *testing.T) {
	t.Setenv("APP_ENV", "test")
	t.Setenv("DATABASE_URL", "postgres://localhost/testdb")
	t.Setenv("PORT", "9000")
	t.Setenv("FRONTEND_URL", "http://localhost:3000")
	t.Setenv("IP_STRATEGY", "remote_addr")

	cfg, err := Load()

	require.NoError(t, err)

	require.Equal(t, AppEnv("test"), cfg.AppEnv)
	require.Equal(t, "9000", cfg.Port)
	require.Equal(t, "http://localhost:3000", cfg.FrontendURL)
	require.Equal(t, "postgres://localhost/testdb", cfg.DatabaseURL.Reveal())
	require.Equal(t, IPStrategyRemoteAddr, cfg.IPStrategy)
}

func TestLoadMissingDatabaseURL(t *testing.T) {
	t.Setenv("APP_ENV", "test")
	t.Setenv("DATABASE_URL", "")
	t.Setenv("IP_STRATEGY", "remote_addr")

	_, err := Load()

	require.Error(t, err)
	require.Contains(t, err.Error(), "DATABASE_URL")
}