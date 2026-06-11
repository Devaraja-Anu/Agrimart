-- +goose Up
CREATE TYPE buyer_type AS ENUM (
    'individual',
    'trader',
    'processor',
    'retailer',
    'exporter'
);

CREATE TABLE buyer_profiles (
    id           UUID        NOT NULL DEFAULT uuid_generate_v4(),
    user_id      UUID        NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    display_name TEXT,
    buyer_type   buyer_type,
    gst_number   TEXT,
    district_id  UUID        REFERENCES regions(id) ON DELETE RESTRICT,
    state_id     UUID        REFERENCES regions(id) ON DELETE RESTRICT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at   TIMESTAMPTZ,

    PRIMARY KEY (id),

    -- One buyer profile per user
    CONSTRAINT buyer_profiles_user_id_unique UNIQUE (user_id)

    -- All fields except user_id are intentionally nullable.
    -- buyer_type is forward-looking for V2 trader/processor flows.
    -- Do not add NOT NULL constraints here without a product decision —
    -- every required field is a drop-off risk for rural farmer onboarding.
);

CREATE TRIGGER set_buyer_profiles_updated_at
    BEFORE UPDATE ON buyer_profiles
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- +goose Down
DROP TABLE buyer_profiles;
DROP TYPE buyer_type;