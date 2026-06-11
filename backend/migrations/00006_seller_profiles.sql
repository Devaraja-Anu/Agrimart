-- +goose Up
CREATE TABLE seller_profiles (
    id                 UUID        NOT NULL DEFAULT uuid_generate_v4(),
    user_id            UUID        NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    display_name       TEXT        NOT NULL,
    is_business        BOOLEAN     NOT NULL DEFAULT FALSE,
    business_name      TEXT,
    gst_number         TEXT,
    whatsapp_number    TEXT,
    has_whatsapp       BOOLEAN     NOT NULL DEFAULT FALSE,
    location           GEOGRAPHY(POINT, 4326),
    house_name         TEXT,
    landmark           TEXT,
    pincode            TEXT,
    district_id        UUID        REFERENCES regions(id) ON DELETE RESTRICT,
    state_id           UUID        REFERENCES regions(id) ON DELETE RESTRICT,
    is_verified        BOOLEAN     NOT NULL DEFAULT FALSE,
    verified_at        TIMESTAMPTZ,
    verified_by        UUID        REFERENCES users(id) ON DELETE SET NULL,
    is_available       BOOLEAN     NOT NULL DEFAULT TRUE,
    response_rate      NUMERIC(5,2),
    avg_response_hours NUMERIC(8,2),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at         TIMESTAMPTZ,

    PRIMARY KEY (id),

    -- One seller profile per user
    CONSTRAINT seller_profiles_user_id_unique UNIQUE (user_id),

    -- has_whatsapp TRUE requires whatsapp_number to be present, and vice versa.
    -- Format validation (10-digit etc.) is application-layer only — consistent
    -- with how users.phone is handled. Regex CHECKs are brittle for Indian
    -- number formats and belong in Go where they are testable and changeable
    -- without a migration.
    CONSTRAINT seller_profiles_whatsapp_consistent CHECK (
        (has_whatsapp = FALSE AND whatsapp_number IS NULL) OR
        (has_whatsapp = TRUE  AND whatsapp_number IS NOT NULL)
    ),

    -- is_business TRUE requires business_name to be present
    CONSTRAINT seller_profiles_business_name_required CHECK (
        (is_business = FALSE) OR
        (is_business = TRUE AND business_name IS NOT NULL)
    )
);

CREATE TRIGGER set_seller_profiles_updated_at
    BEFORE UPDATE ON seller_profiles
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- +goose Down
DROP TABLE seller_profiles;