-- +goose Up

-- Attach set_updated_at trigger to users now that the function exists.
-- Defined here (not in 00003) because 00004_functions.sql must run first.
CREATE TRIGGER set_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- Junction table. A user can hold multiple roles simultaneously.
-- Valid values: farmer, buyer, service_provider, admin.
-- Validation is application-layer only — no CHECK constraint on role.
-- Adding new role values requires no migration, only application code changes.
-- admin is additive: an admin can also hold farmer or buyer to test real user flows.
CREATE TABLE user_roles (
    user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role       TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, role)
);

-- +goose Down
DROP TABLE user_roles;

DROP TRIGGER IF EXISTS set_users_updated_at ON users;