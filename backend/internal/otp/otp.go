package otp

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"math/big"
	"time"

	"github.com/redis/go-redis/v9"
)

const (
	Length          = 6
	TTL             = 5 * time.Minute
	MaxAttempts     = 5
	RateLimitWindow = 1 * time.Hour
	RateLimitMax    = 3
)

var (
	ErrOTPNotFound     = errors.New("otp not found or expired")
	ErrOTPMismatch     = errors.New("otp does not match")
	ErrTooManyAttempts = errors.New("too many attempts, request a new code")
	ErrRateLimited     = errors.New("too many otp requests, try again later")
)

func Generate() (string, error) {
	max := big.NewInt(1_000_000) // 10^6, exclusive upper bound

	number, err := rand.Int(rand.Reader, max)
	if err != nil {
		return "", fmt.Errorf("generating otp: %w", err)
	}

	return fmt.Sprintf("%06d", number.Int64()), nil
}

func hashOTP(otp string) string {
	sum := sha256.Sum256([]byte(otp))
	return hex.EncodeToString(sum[:])
}

func Store(ctx context.Context, rdb *redis.Client, phone, otpValue string) error {

	hashed := hashOTP(otpValue)

	pipe := rdb.TxPipeline()
	pipe.Set(ctx, otpKey(phone), hashed, TTL)
	pipe.Del(ctx, attemptsKey(phone))

	if _, err := pipe.Exec(ctx); err != nil {
		return fmt.Errorf("storing otp: %w", err)
	}

	return nil
}

func Verify(ctx context.Context, rdb *redis.Client, phone, candidate string) error {

	storedHash, err := rdb.Get(ctx, otpKey(phone)).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return ErrOTPNotFound
		}

		return fmt.Errorf("fetching OTP: %w", err)
	}

	if hashOTP(candidate) == storedHash {
		if err := rdb.Del(ctx, otpKey(phone), attemptsKey(phone)).Err(); err != nil {
			return fmt.Errorf("clearing OTP after success: %w", err)
		}
		return nil
	}

	attempts, err := rdb.Incr(ctx, attemptsKey(phone)).Result()
	if err != nil {
		return fmt.Errorf("incremeting attempts: %w", err)
	}

	if attempts == 1 {
		// first wrong attempt for this OTP — give the counter the same TTL as the OTP
		// so it doesn't outlive what it's counting attempts against
		if err := rdb.Expire(ctx, attemptsKey(phone), TTL).Err(); err != nil {
			return fmt.Errorf("settting attempts ttl: %w", err)
		}
	}

	if attempts >= MaxAttempts {
		if err := rdb.Del(ctx, otpKey(phone), attemptsKey(phone)).Err(); err != nil {
			return fmt.Errorf("clearing otp after max attempts reached: %w", err)
		}
		return ErrTooManyAttempts
	}

	return ErrOTPMismatch
}

func CheckRateLimit(ctx context.Context, rdb *redis.Client, phone string) error {

	key := rateLimitKey(phone)

	count, err := rdb.Incr(ctx, key).Result()
	if err != nil {
		return fmt.Errorf("checking rate limit: %w", err)
	}

	if count == 1 {
		if err := rdb.Expire(ctx, key, RateLimitWindow).Err(); err != nil {
			return fmt.Errorf("setting rate limit ttl: %w", err)
		}
	}

	if count > RateLimitMax {
		return ErrRateLimited
	}

	return nil
}

func otpKey(phone string) string {
	return fmt.Sprintf("otp:%s", phone)
}

func attemptsKey(phone string) string {
	return fmt.Sprintf("otp:attempts:%s", phone)
}

func rateLimitKey(phone string) string {
	return fmt.Sprintf("otp:ratelimit:%s", phone)
}
