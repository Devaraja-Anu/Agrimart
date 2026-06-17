package config

import (
	"fmt"
	"log/slog"
	"net"
	"os"
	"strings"
	"time"

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
	FrontendURL       string
	IPStrategy        IPStrategy
	TrustedProxyCIDRs []string
	ClientIPHeader    string

	TypesenseKey    string
	FirebaseProject string
	RedisURL        secret
	JWTSecret       secret
	JWTExpiry       time.Duration
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

	if envApp != "production" && envApp != "test" {
		if err := godotenv.Load(); err != nil {
			slog.Warn("no .env file found, relying on environment variables")
		}
	}

	cfg := Config{
		// uncomment as required

		AppEnv:      AppEnv(envApp),
		DatabaseURL: secret(os.Getenv("DATABASE_URL")),
		FrontendURL: getEnv("FRONTEND_URL", "http://localhost:3000"),
		RedisURL:    secret(os.Getenv("REDIS_URL")),
		// JWTSecret:         secret(os.Getenv("JWT_SECRET")),
		// TypesenseKey:      os.Getenv("TYPESENSE_API_KEY"),
		// FirebaseProject:   os.Getenv("FIREBASE_PROJECT_ID"),
		Port:              getEnv("PORT", "8080"),
		IPStrategy:        IPStrategy(getEnv("IP_STRATEGY", "remote_addr")),
		TrustedProxyCIDRs: splitNonEmpty(getEnv("TRUSTED_PROXY_CIDRS", "")),
		ClientIPHeader:    getEnv("CLIENT_IP_HEADER", ""),
	}

	expiry, err := time.ParseDuration(os.Getenv("JWT_EXPIRY"))
	if err != nil || cfg.JWTExpiry <= 0 {
		cfg.JWTExpiry = 168 * time.Hour // default: 7 days
	}

	cfg.JWTExpiry = expiry

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
		return fmt.Errorf("missing required env variables: %s", strings.Join(missing, ","))
	}

	switch c.IPStrategy {
	case IPStrategyRemoteAddr, IPStrategyCloudflare:
	case IPStrategyXFFTrusted:
		if len(c.TrustedProxyCIDRs) == 0 {
			return fmt.Errorf("IP_STRATEGY=%s requires TRUSTED_PROXY_CIDRS to be set", c.IPStrategy)
		}
		for _, cidr := range c.TrustedProxyCIDRs {
			if _, _, err := net.ParseCIDR(cidr); err != nil {
				return fmt.Errorf("invalid entry %q in TRUSTED_PROXY_CIDRS: %w", cidr, err)
			}
		}

	case IPStrategyCustomHeader:
		if c.ClientIPHeader == "" {
			return fmt.Errorf("IP_STRATEGY=%s requires CLIENT_IP_HEADER to be set", c.IPStrategy)
		}
	default:
		return fmt.Errorf("invalid IP_STRATEGY %q: must be one of remote_addr, xff_trusted, cloudflare, custom_header", c.IPStrategy)
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

	parts := strings.Split(s, ",")
	output := make([]string, 0, len(parts))

	for _, p := range parts {
		if t := strings.TrimSpace(p); t != "" {
			output = append(output, t)
		}
	}

	if len(output) == 0 {
		return nil
	}

	return output
}
