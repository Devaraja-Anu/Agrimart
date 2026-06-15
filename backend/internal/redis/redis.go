package redis

import (
	"context"

	"github.com/redis/go-redis/v9"
)

func NewClient(ctx context.Context, url string) (*redis.Client, error) {
	opts, err := redis.ParseURL(url)
	if err != nil {
		return nil, err
	}

	client := redis.NewClient(opts)

	err = client.Ping(ctx).Err()
	if err != nil {
		client.Close()
		return nil, err
	}

	return client, nil
}
