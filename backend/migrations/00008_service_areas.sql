-- +goose Up
CREATE TABLE service_areas(
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    seller_profile_id UUID REFERENCES seller_profiles(id) ON DELETE CASCADE,
    region_id UUID NOT NULL REFERENCES regions(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    PRIMARY KEY (id),

    CONSTRAINT service_areas_seller_region_unique UNIQUE (
        seller_profile_id, region_id
    )

    -- region_id is not fixed to district-level regions at the DB level.
    -- In practice the Go handler always expands a state selection into one row
    -- per child district, so region_id will point to district rows. This
    --  is intentional — if taluk-level or national coverage is added
    -- later, the schema does not need to change. The business rule lives in Go.
);

-- The UNIQUE constraint above already indexes (seller_profile_id, region_id).
-- A separate index on region_id alone is needed for the reverse lookup:

-- +goose Down
DROP TABLE service_areas;