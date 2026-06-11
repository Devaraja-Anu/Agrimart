-- +goose NO TRANSACTION

-- All indexes use CREATE INDEX CONCURRENTLY to avoid acquiring a SHARE lock
-- on live tables. Standard CREATE INDEX holds a SHARE lock for the duration of
-- the build — unacceptable on a production table with active traffic.
--
-- CONCURRENTLY is used here even in local development. This is intentional.
-- Dev and prod must run identical SQL. A migration that skips CONCURRENTLY
-- locally but would lock a prod table is a latent incident waiting to happen.
-- The minor extra time on an empty dev database is not a reason to diverge.
--
-- goose NO TRANSACTION is required because CREATE INDEX CONCURRENTLY cannot
-- run inside a transaction block.
--
-- Down scripts use DROP INDEX CONCURRENTLY IF EXISTS for the same reason.

-- +goose Up

-- regions
CREATE INDEX CONCURRENTLY idx_regions_parent_id
    ON regions (parent_id);

CREATE INDEX CONCURRENTLY idx_regions_type
    ON regions (region_type);

-- users
-- idx_users_role_deleted removed — role no longer lives on users (see user_roles).
CREATE INDEX CONCURRENTLY idx_users_deleted
    ON users (deleted_at)
    WHERE deleted_at IS NULL;

-- user_roles
CREATE INDEX CONCURRENTLY idx_user_roles_user_id
    ON user_roles (user_id);

-- Supports queries like "all service_providers", "all admins"
CREATE INDEX CONCURRENTLY idx_user_roles_role
    ON user_roles (role);

-- seller_profiles
CREATE INDEX CONCURRENTLY idx_seller_profiles_user_id
    ON seller_profiles (user_id);

CREATE INDEX CONCURRENTLY idx_seller_profiles_district_id
    ON seller_profiles (district_id);

CREATE INDEX CONCURRENTLY idx_seller_profiles_state_id
    ON seller_profiles (state_id);

CREATE INDEX CONCURRENTLY idx_seller_profiles_available
    ON seller_profiles (is_available)
    WHERE deleted_at IS NULL AND is_available = TRUE;

CREATE INDEX CONCURRENTLY idx_seller_profiles_verified
    ON seller_profiles (is_verified)
    WHERE deleted_at IS NULL AND is_verified = TRUE;

-- GIST index for proximity search via ST_DWithin
CREATE INDEX CONCURRENTLY idx_seller_profiles_location
    ON seller_profiles USING GIST (location);

CREATE INDEX CONCURRENTLY idx_seller_profiles_deleted
    ON seller_profiles (deleted_at)
    WHERE deleted_at IS NULL;

-- buyer_profiles
CREATE INDEX CONCURRENTLY idx_buyer_profiles_user_id
    ON buyer_profiles (user_id);

CREATE INDEX CONCURRENTLY idx_buyer_profiles_deleted
    ON buyer_profiles (deleted_at)
    WHERE deleted_at IS NULL;

-- service_areas
-- (seller_profile_id, region_id) is already indexed by the UNIQUE constraint.
-- Separate index on region_id alone for the reverse lookup: "all sellers who
-- cover this region".
CREATE INDEX CONCURRENTLY idx_service_areas_region_id
    ON service_areas (region_id);

-- categories
CREATE INDEX CONCURRENTLY idx_categories_parent_id
    ON categories (parent_id);

CREATE INDEX CONCURRENTLY idx_categories_slug
    ON categories (slug);

CREATE INDEX CONCURRENTLY idx_categories_active
    ON categories (is_active)
    WHERE is_active = TRUE;

-- attribute_definitions
-- idx_attr_def_name_category and idx_attr_def_name_global are created in
-- 00010_attribute_definitions.sql because they enforce uniqueness constraints
-- and must exist before any data is written. Operational indexes are here.
CREATE INDEX CONCURRENTLY idx_attribute_definitions_category_id
    ON attribute_definitions (category_id);

CREATE INDEX CONCURRENTLY idx_attribute_definitions_slug
    ON attribute_definitions (slug);

-- listings
CREATE INDEX CONCURRENTLY idx_listings_seller_profile_id
    ON listings (seller_profile_id);

CREATE INDEX CONCURRENTLY idx_listings_category_id
    ON listings (category_id);

CREATE INDEX CONCURRENTLY idx_listings_listing_type
    ON listings (listing_type);

CREATE INDEX CONCURRENTLY idx_listings_status
    ON listings (status);

-- Core public search filter. Partial index: only active, non-soft-deleted
-- listings. A soft-deleted listing may have status = 'active' (seller removed
-- it without a status change) — deleted_at IS NULL ensures it never appears
-- in public results at the index level.
-- expires_at is intentionally excluded from the index condition — it is a
-- runtime filter in the query, not a condition for index inclusion. Evergreen
-- listings (expires_at IS NULL) must also appear in public search results.
-- The background expiry goroutine handles flipping status to 'expired' for
-- rows WHERE expires_at IS NOT NULL AND expires_at < NOW().
CREATE INDEX CONCURRENTLY idx_listings_active
    ON listings (status)
    WHERE status = 'active' AND deleted_at IS NULL;

-- Partial index on availability for rental/equipment browsing queries.
-- Only indexes rows where availability IS NOT NULL — service listings
-- (soil testing, advisory etc.) never set this field and are excluded.
CREATE INDEX CONCURRENTLY idx_listings_availability
    ON listings (availability)
    WHERE availability IS NOT NULL AND deleted_at IS NULL;

-- GIST index for proximity search via ST_DWithin
CREATE INDEX CONCURRENTLY idx_listings_location
    ON listings USING GIST (location);

-- GIN index for full-text search fallback (Typesense is primary)
CREATE INDEX CONCURRENTLY idx_listings_search_vector
    ON listings USING GIN (search_vector);

-- GIN trigram index for ILIKE fallback during Typesense sync lag window
CREATE INDEX CONCURRENTLY idx_listings_title_trgm
    ON listings USING GIN (title gin_trgm_ops);

CREATE INDEX CONCURRENTLY idx_listings_last_activity_at
    ON listings (last_activity_at);

CREATE INDEX CONCURRENTLY idx_listings_deleted
    ON listings (deleted_at)
    WHERE deleted_at IS NULL;

-- listing_attributes
CREATE INDEX CONCURRENTLY idx_listing_attributes_listing_id
    ON listing_attributes (listing_id);

CREATE INDEX CONCURRENTLY idx_listing_attributes_definition_id
    ON listing_attributes (attribute_definition_id);

-- enquiries
CREATE INDEX CONCURRENTLY idx_enquiries_listing_id
    ON enquiries (listing_id);

CREATE INDEX CONCURRENTLY idx_enquiries_sender_id
    ON enquiries (sender_id);

CREATE INDEX CONCURRENTLY idx_enquiries_status
    ON enquiries (status);

CREATE INDEX CONCURRENTLY idx_enquiries_deleted
    ON enquiries (deleted_at)
    WHERE deleted_at IS NULL;

-- contact_events
CREATE INDEX CONCURRENTLY idx_contact_events_listing_id
    ON contact_events (listing_id);

-- Composite index for analytics queries: contact events per listing over time
CREATE INDEX CONCURRENTLY idx_contact_events_listing_created
    ON contact_events (listing_id, created_at);

-- Partial — most taps are anonymous so most buyer_id values are NULL.
-- Index only authenticated taps.
CREATE INDEX CONCURRENTLY idx_contact_events_buyer_id
    ON contact_events (buyer_id)
    WHERE buyer_id IS NOT NULL;

CREATE INDEX CONCURRENTLY idx_contact_events_event_type
    ON contact_events (event_type);

-- +goose Down

DROP INDEX CONCURRENTLY IF EXISTS idx_contact_events_event_type;
DROP INDEX CONCURRENTLY IF EXISTS idx_contact_events_buyer_id;
DROP INDEX CONCURRENTLY IF EXISTS idx_contact_events_listing_created;
DROP INDEX CONCURRENTLY IF EXISTS idx_contact_events_listing_id;

DROP INDEX CONCURRENTLY IF EXISTS idx_enquiries_deleted;
DROP INDEX CONCURRENTLY IF EXISTS idx_enquiries_status;
DROP INDEX CONCURRENTLY IF EXISTS idx_enquiries_sender_id;
DROP INDEX CONCURRENTLY IF EXISTS idx_enquiries_listing_id;

DROP INDEX CONCURRENTLY IF EXISTS idx_listing_attributes_definition_id;
DROP INDEX CONCURRENTLY IF EXISTS idx_listing_attributes_listing_id;

DROP INDEX CONCURRENTLY IF EXISTS idx_listings_deleted;
DROP INDEX CONCURRENTLY IF EXISTS idx_listings_last_activity_at;
DROP INDEX CONCURRENTLY IF EXISTS idx_listings_title_trgm;
DROP INDEX CONCURRENTLY IF EXISTS idx_listings_search_vector;
DROP INDEX CONCURRENTLY IF EXISTS idx_listings_location;
DROP INDEX CONCURRENTLY IF EXISTS idx_listings_availability;
DROP INDEX CONCURRENTLY IF EXISTS idx_listings_active;
DROP INDEX CONCURRENTLY IF EXISTS idx_listings_status;
DROP INDEX CONCURRENTLY IF EXISTS idx_listings_listing_type;
DROP INDEX CONCURRENTLY IF EXISTS idx_listings_category_id;
DROP INDEX CONCURRENTLY IF EXISTS idx_listings_seller_profile_id;

DROP INDEX CONCURRENTLY IF EXISTS idx_attribute_definitions_slug;
DROP INDEX CONCURRENTLY IF EXISTS idx_attribute_definitions_category_id;

DROP INDEX CONCURRENTLY IF EXISTS idx_categories_active;
DROP INDEX CONCURRENTLY IF EXISTS idx_categories_slug;
DROP INDEX CONCURRENTLY IF EXISTS idx_categories_parent_id;

DROP INDEX CONCURRENTLY IF EXISTS idx_service_areas_region_id;

DROP INDEX CONCURRENTLY IF EXISTS idx_buyer_profiles_deleted;
DROP INDEX CONCURRENTLY IF EXISTS idx_buyer_profiles_user_id;

DROP INDEX CONCURRENTLY IF EXISTS idx_seller_profiles_deleted;
DROP INDEX CONCURRENTLY IF EXISTS idx_seller_profiles_location;
DROP INDEX CONCURRENTLY IF EXISTS idx_seller_profiles_verified;
DROP INDEX CONCURRENTLY IF EXISTS idx_seller_profiles_available;
DROP INDEX CONCURRENTLY IF EXISTS idx_seller_profiles_state_id;
DROP INDEX CONCURRENTLY IF EXISTS idx_seller_profiles_district_id;
DROP INDEX CONCURRENTLY IF EXISTS idx_seller_profiles_user_id;

DROP INDEX CONCURRENTLY IF EXISTS idx_user_roles_role;
DROP INDEX CONCURRENTLY IF EXISTS idx_user_roles_user_id;

DROP INDEX CONCURRENTLY IF EXISTS idx_users_deleted;

DROP INDEX CONCURRENTLY IF EXISTS idx_regions_type;
DROP INDEX CONCURRENTLY IF EXISTS idx_regions_parent_id;