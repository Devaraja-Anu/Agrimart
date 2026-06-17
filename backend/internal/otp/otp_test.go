package otp_test

import (
	"context"
	"testing"

	"github.com/devaraja-anu/agrilib/internal/otp"
	"github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/require"
	tcRedis "github.com/testcontainers/testcontainers-go/modules/redis"
)

func newTestRedis(t *testing.T) *redis.Client {
	t.Helper()

	ctx := context.Background()

	container, err := tcRedis.Run(ctx,
		"redis:7-alpine",
	)

	require.NoError(t, err)

	t.Cleanup(func() {
		require.NoError(t, container.Terminate(ctx))
	})

	connStr, err := container.ConnectionString(ctx)
	require.NoError(t, err)

	opts, err := redis.ParseURL(connStr)
	require.NoError(t, err)

	rdb := redis.NewClient(opts)

	require.NoError(t, rdb.Ping(ctx).Err())

	t.Cleanup(func() {
		_ = rdb.Close()
	})

	return rdb
}

func TestGenerate(t *testing.T) {
	code, err := otp.Generate()

	require.NoError(t, err)
	require.Len(t, code, otp.Length)

	for _, c := range code {
		require.GreaterOrEqual(t, c, '0')
		require.LessOrEqual(t, c, '9')
	}
}

func TestStoreAndVerify_Success(t *testing.T) {
	ctx := context.Background()
	rdb := newTestRedis(t)

	require.NoError(t,
		otp.Store(ctx, rdb, "9876543210", "123456"),
	)

	require.NoError(t,
		otp.Verify(ctx, rdb, "9876543210", "123456"),
	)
}

func TestVerify_NotFound(t *testing.T) {
	ctx := context.Background()
	rdb := newTestRedis(t)

	err := otp.Verify(ctx, rdb, "9876543210", "123456")

	require.ErrorIs(t, err, otp.ErrOTPNotFound)
}

func TestVerify_WrongOTP(t *testing.T) {
	ctx := context.Background()
	rdb := newTestRedis(t)

	require.NoError(t,
		otp.Store(ctx, rdb, "9876543210", "123456"),
	)

	err := otp.Verify(ctx, rdb, "9876543210", "654321")

	require.ErrorIs(t, err, otp.ErrOTPMismatch)
}

func TestVerify_TooManyAttempts(t *testing.T) {
	ctx := context.Background()
	rdb := newTestRedis(t)

	require.NoError(t,
		otp.Store(ctx, rdb, "9876543210", "123456"),
	)

	for i := 0; i < otp.MaxAttempts-1; i++ {
		err := otp.Verify(ctx, rdb, "9876543210", "000000")
		require.ErrorIs(t, err, otp.ErrOTPMismatch)
	}

	err := otp.Verify(ctx, rdb, "9876543210", "000000")
	require.ErrorIs(t, err, otp.ErrTooManyAttempts)
}

func TestVerify_DeletesOTPOnSuccess(t *testing.T) {
	ctx := context.Background()
	rdb := newTestRedis(t)

	require.NoError(t,
		otp.Store(ctx, rdb, "9876543210", "123456"),
	)

	require.NoError(t,
		otp.Verify(ctx, rdb, "9876543210", "123456"),
	)

	err := otp.Verify(ctx, rdb, "9876543210", "123456")
	require.ErrorIs(t, err, otp.ErrOTPNotFound)
}

func TestCheckRateLimit(t *testing.T) {
	ctx := context.Background()
	rdb := newTestRedis(t)

	for i := 0; i < otp.RateLimitMax; i++ {
		require.NoError(t,
			otp.CheckRateLimit(ctx, rdb, "9876543210"),
		)
	}

	err := otp.CheckRateLimit(ctx, rdb, "9876543210")
	require.ErrorIs(t, err, otp.ErrRateLimited)
}
