-- +goose Up
CREATE TYPE region_type AS ENUM ('country','state','district');

CREATE TABLE regions (
    id  UUID DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    region_type region_type NOT NULL,
    parent_id UUID REFERENCES regions(id) ON DELETE RESTRICT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    
    PRIMARY KEY(id)
);

-- Partial unique index rather than a table constraint because standard UNIQUE
-- constraints cannot be partial. Allows name reuse for inactive regions.
CREATE UNIQUE INDEX idx_regions_name_parent_active ON regions (name,parent_id) WHERE is_active = TRUE;

-- +goose Down
DROP TABLE IF EXISTS regions;
DROP TYPE IF EXISTS region_type;
