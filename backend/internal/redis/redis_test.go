package redis_test

import (
	"context"
	"testing"

	redisutil "github.com/devaraja-anu/agrilib/internal/redis"
	tcRedis "github.com/testcontainers/testcontainers-go/modules/redis"
	"github.com/stretchr/testify/require"
)

func TestNewClient_InvalidURL(t *testing.T) {
	ctx := context.Background()

	client, err := redisutil.NewClient(ctx, "://invalid-url")

	require.Error(t, err)
	require.Nil(t, client)
}

func TestNewClient_UnreachableServer(t *testing.T) {
	ctx := context.Background()

	client, err := redisutil.NewClient(ctx, "redis://localhost:6399")

	require.Error(t, err)
	require.Nil(t, client)
}

func TestNewClient_Success(t *testing.T) {
	ctx := context.Background()

	container, err := tcRedis.Run(ctx, "redis:7-alpine")
	require.NoError(t, err)

	t.Cleanup(func() {
		require.NoError(t, container.Terminate(ctx))
	})

	connStr, err := container.ConnectionString(ctx)
	require.NoError(t, err)

	client, err := redisutil.NewClient(ctx, connStr)
	require.NoError(t, err)
	require.NotNil(t, client)

	t.Cleanup(func() {
		require.NoError(t, client.Close())
	})

	require.NoError(t, client.Ping(ctx).Err())
}