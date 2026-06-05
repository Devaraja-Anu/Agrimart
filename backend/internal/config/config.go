package config

import (
	"fmt"
	"log/slog"
	"os"
	"strings"

	"github.com/joho/godotenv"
)

type IPStrategy string
type AppEnv string
type secret string

const (
	IPStrategyRemoteAddr   IPStrategy = "remote_addr"   // no proxy, direct / local dev
	IPStrategyXFFTrusted   IPStrategy = "xff_trusted"   // nginx / cloud LB with known CIDR
	IPStrategyCloudflare   IPStrategy = "cloudflare"    // CF-Connecting-IP header
	IPStrategyCustomHeader IPStrategy = "custom_header" // any single trusted header
)

type Config struct {
	DatabaseURL       secret
	Port              string
	AppEnv            AppEnv
	IPStrategy        IPStrategy
	TrustedProxyCIDRs []string
	ClientIPHeader    string

	TypesenseKey    string
	FirebaseProject string
	RedisURL        string
	JWTSecret       secret
}

func (s secret) LogValue() slog.Value {
	return slog.StringValue("********")
}

func (s secret) String() string {
	return "********"
}

// config.go
func Load() (Config, error) {

    // APP_ENV is read before godotenv.Load() intentionally —
// it must come from the real environment, never from a .env file.
	envApp := getEnv("APP_ENV", "development")

	if envApp != "production" {
		if err := godotenv.Load(); err != nil {
			slog.Warn("no .env file found, relying on environment variables")
		}
	}

	cfg := Config{
		AppEnv:      AppEnv(envApp),
		DatabaseURL: secret(os.Getenv("DATABASE_URL")),
		// RedisURL:          os.Getenv("REDIS_URL"),
		// JWTSecret:         secret(os.Getenv("JWT_SECRET")),
		// TypesenseKey:      os.Getenv("TYPESENSE_API_KEY"),
		// FirebaseProject:   os.Getenv("FIREBASE_PROJECT_ID"),
		Port:              getEnv("PORT", "8080"),
		IPStrategy:        IPStrategy(getEnv("IP_STRATEGY", "remote_addr")),
		TrustedProxyCIDRs: splitNonEmpty(getEnv("TRUSTED_PROXY_CIDRS", "")),
		ClientIPHeader:    getEnv("CLIENT_IP_HEADER", ""),
	}

	if err := cfg.validate(); err != nil {
		return Config{}, err
	}

	return cfg, nil
}

func (s secret) Reveal() string {
    return string(s)
}

func (c Config) validate() error {
	var missing []string

	if c.DatabaseURL == "" {
		missing = append(missing, "DATABASE_URL")
	}
	// if c.RedisURL == "" {
	//     missing = append(missing, "REDIS_URL")
	// }

	if len(missing) > 0 {
		return fmt.Errorf("missing required environment variables: %s", strings.Join(missing, ", "))
	}

	return nil
}

// getEnv reads an environment variable, returning fallback if it's unset or empty.
func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func splitNonEmpty(s string) []string {
	if s == "" {
		return nil
	}
	return strings.Split(s, ",")
}
