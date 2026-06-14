-- +goose Up
-- Note: both CREATE FUNCTION blocks below use goose StatementBegin/StatementEnd
-- markers (the goose directive comments, not shown in this sentence to avoid
-- confusing the migration parser). See 00004_functions.sql for why these are
-- required — goose's default statement splitter does not understand $$
-- dollar-quoted function bodies and mangles them without these markers.
CREATE TYPE listing_type AS ENUM ('product', 'service');

CREATE TYPE listing_status AS ENUM (
    'draft',
    'active',
    'suspended',
    'expired',
    'hidden'
    -- 'sold' intentionally absent. No V1 listing type has a terminal "sold"
    -- state — services and rentals don't get sold, and produce listings don't
    -- exist until V2. Add 'sold' back in a V2 migration when produce listings
    -- are activated. Adding a value to an enum requires ALTER TYPE ... ADD VALUE
    -- which cannot run inside a transaction — plan accordingly.
);

-- Availability state for rental and equipment listings only.
-- NULL on all other listing types (soil testing, advisory, certification etc.)
-- where availability is a seller-level concern, not a listing-level one.
-- The application only renders the availability UI when this field IS NOT NULL,
-- driven by the listing's category type.
--
-- Intentionally separate from listing_status — lifecycle (is this listing
-- published?) and availability (is this asset obtainable right now?) are
-- independent concerns. A listing can be active but booked, or active and
-- available. Collapsing them into one enum loses that expressiveness.
--
-- Deferred: a full availability calendar / booking flow is V2. This enum
-- is the V1 approximation — seller-managed, manual, good enough for
-- "farmers willing to wait a day or two."
CREATE TYPE listing_availability AS ENUM (
    'available',      -- free now, can be booked immediately
    'booked',         -- taken until available_from date; set available_from when using this
    'contact_seller'  -- availability is complex or variable; buyer should WhatsApp to confirm
);

CREATE TYPE price_unit AS ENUM (
    'per_kg',
    'per_quintal',
    'per_tonne',
    'per_piece',
    'per_dozen',
    'per_litre',
    'per_acre',
    'per_visit',
    'per_hour',
    'per_day',       -- equipment and vehicle hire (tractors, lorries, excavators etc.)
    'per_sample'
);

CREATE TABLE listings (
    id                   UUID                 NOT NULL DEFAULT uuid_generate_v4(),
    seller_profile_id    UUID                 NOT NULL REFERENCES seller_profiles(id) ON DELETE RESTRICT,
    category_id          UUID                 NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    listing_type         listing_type         NOT NULL DEFAULT 'service',
    title                TEXT                 NOT NULL,
    description          TEXT,
    price                NUMERIC(12,2)        NOT NULL,
    price_unit           price_unit           NOT NULL,
    photos               TEXT[],
    location             GEOGRAPHY(POINT, 4326),
    status               listing_status       NOT NULL DEFAULT 'draft',
    availability         listing_availability,
    available_from       DATE,
    search_vector        TSVECTOR,
    view_count           INTEGER              NOT NULL DEFAULT 0,
    renewal_count        INTEGER              NOT NULL DEFAULT 0,
    report_count         INTEGER              NOT NULL DEFAULT 0,
    price_updated_at     TIMESTAMPTZ,
    last_activity_at     TIMESTAMPTZ,
    expires_at           TIMESTAMPTZ,
    created_at           TIMESTAMPTZ          NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ          NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    PRIMARY KEY (id),

    -- Max 5 photos per listing. array_length returns NULL for empty arrays and
    -- NULL columns, so NULL and {} both pass — photos are not required at
    -- listing creation (e.g. saving a draft).
    CONSTRAINT listings_photos_max CHECK (array_length(photos, 1) <= 5),

    -- available_from is only meaningful when availability = 'booked'.
    -- Prevent it being set when availability is NULL or not 'booked' —
    -- a future date on an 'available' listing would be confusing.
    CONSTRAINT listings_available_from_requires_booked CHECK (
        available_from IS NULL OR availability = 'booked'
    )

    -- report_count threshold logic (currently 3 → hidden) lives in Go config,
    -- not here. Easy to change without a migration.
    --
    -- expires_at is nullable. NULL means the listing is evergreen — no expiry.
    -- This is the correct model for equipment hire, vehicle listings, and
    -- permanent service offerings (a tractor rental service does not expire).
    -- When set, the application sets it explicitly:
    --   time-bound service listings → NOW() + 90 days
    --   produce listings            → NOW() + 30 days  (V2)
    --   dried goods                 → NOW() + 60 days  (V2)
    -- The background expiry goroutine only processes rows WHERE
    -- expires_at IS NOT NULL AND expires_at < NOW(). Evergreen listings
    -- are never touched by the expiry job.
    -- The renewal banner in the UX only shows when expires_at IS NOT NULL
    -- and is approaching — NULL listings skip it entirely.
    --
    -- availability and available_from are NULL for service listings where
    -- availability is not a listing-level concept (soil testing, advisory etc.).
    -- The application sets these only for rental and equipment categories.
    -- When a seller marks their listing as 'booked', they set available_from
    -- so buyers can see "Available from 14 July" rather than a dead listing.
    -- Deferred: full availability calendar / booking flow is V2.
    --
    -- last_activity_at is updated by the Go application layer with a 10-minute
    -- debounce per listing_id to prevent write amplification on high-traffic
    -- listings. It is NOT updated by a trigger.
    --
    -- Status lifecycle:
    --   draft → active → expired    (auto, background goroutine, only if expires_at IS NOT NULL)
    --                  → hidden     (report_count threshold, Go logic)
    --                  → suspended  (admin action)
    --   active → deleted_at set     (seller-initiated removal)
    -- A soft-deleted listing may have status = 'active'. The idx_listings_active
    -- partial index (00015) and all sqlc queries (AND deleted_at IS NULL) handle
    -- this correctly — soft-deleted listings never appear in public results.
);

-- Trigger 1: updated_at maintenance
CREATE TRIGGER set_listings_updated_at
    BEFORE UPDATE ON listings
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- Trigger 2: full-text search vector maintenance.
-- Custom function required (not tsvector_update_trigger) because we need
-- weighted columns: title at weight A, description at weight B.
-- Fires only on INSERT or changes to title/description — not on status updates,
-- view_count increments, or other field changes.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION listings_search_vector_update()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('english', coalesce(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(NEW.description, '')), 'B');
    RETURN NEW;
END;
$$;
-- +goose StatementEnd

CREATE TRIGGER listings_search_vector_update
    BEFORE INSERT OR UPDATE OF title, description ON listings
    FOR EACH ROW
    EXECUTE FUNCTION listings_search_vector_update();

-- Trigger 3: price freshness signal.
-- Sets price_updated_at = NOW() when price or price_unit changes.
-- Column renamed from quantity_updated_at (SCHEMA.md error) — it tracks when
-- price was last confirmed, which is the buyer-facing freshness signal.
-- When a quantity column is added in V2, it gets its own column and trigger
-- in a new migration — do not add it here.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION listings_price_updated_at()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
BEGIN
    NEW.price_updated_at = NOW();
    RETURN NEW;
END;
$$;
-- +goose StatementEnd

CREATE TRIGGER listings_price_updated_at
    BEFORE UPDATE OF price, price_unit ON listings
    FOR EACH ROW
    EXECUTE FUNCTION listings_price_updated_at();

-- +goose Down
DROP TRIGGER IF EXISTS listings_price_updated_at ON listings;
DROP FUNCTION IF EXISTS listings_price_updated_at();

DROP TRIGGER IF EXISTS listings_search_vector_update ON listings;
DROP FUNCTION IF EXISTS listings_search_vector_update();

DROP TRIGGER IF EXISTS set_listings_updated_at ON listings;

DROP TABLE listings;

DROP TYPE price_unit;
DROP TYPE listing_availability;
DROP TYPE listing_status;
DROP TYPE listing_type;