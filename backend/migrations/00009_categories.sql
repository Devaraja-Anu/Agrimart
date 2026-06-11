-- +goose Up
CREATE TABLE categories (
    id         UUID        NOT NULL DEFAULT uuid_generate_v4(),
    parent_id  UUID        REFERENCES categories(id) ON DELETE RESTRICT,
    name       TEXT        NOT NULL,
    slug       TEXT        NOT NULL,
    is_active  BOOLEAN     NOT NULL DEFAULT TRUE,
    sort_order INTEGER     NOT NULL DEFAULT 10,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (id),

    CONSTRAINT categories_slug_unique UNIQUE (slug),

    -- Prevents duplicate child names under the same parent.
    -- NOTE: Postgres treats NULL != NULL in unique indexes, so two top-level
    -- categories (parent_id IS NULL) with the same name would not conflict here.
    -- This is a known and accepted limitation — top-level categories are
    -- admin-seeded and never user-created, so duplicate top-level names are an
    -- admin discipline problem rather than a user-facing risk.
    CONSTRAINT categories_name_parent_unique UNIQUE (name, parent_id)
);

-- Service categories (V1) seeded as is_active = TRUE.
-- Produce categories (V2) seeded as is_active = FALSE — activated in a future
-- migration with no structural changes required.

-- +goose Down
DROP TABLE categories;