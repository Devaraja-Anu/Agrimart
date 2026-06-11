-- +goose Up
CREATE TABLE users (
    id           UUID        NOT NULL DEFAULT uuid_generate_v4(),
    phone        TEXT        NOT NULL,
    is_active    BOOLEAN     NOT NULL DEFAULT TRUE,
    last_seen_at TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at   TIMESTAMPTZ,

    PRIMARY KEY (id),

    -- Phone stored as raw 10-digit TEXT — no country code, no +91 prefix.
    -- UNIQUE applies across all rows including soft-deleted; a deleted user's
    -- phone cannot be re-registered without a deliberate recovery flow.
    CONSTRAINT users_phone_unique UNIQUE (phone)
);

-- +goose Down
DROP TABLE users;