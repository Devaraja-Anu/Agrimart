-- +goose Up
CREATE TABLE listing_attributes (
    id                      UUID        NOT NULL DEFAULT uuid_generate_v4(),
    listing_id              UUID        NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    attribute_definition_id UUID        NOT NULL REFERENCES attribute_definitions(id) ON DELETE RESTRICT,
    value                   TEXT        NOT NULL,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (id),

    CONSTRAINT listing_attributes_listing_attr_unique UNIQUE (listing_id, attribute_definition_id)

    -- No deleted_at — rows are hard-deleted and recreated when a listing is
    -- edited. No history is needed for attribute values.

    -- ON DELETE CASCADE fires on hard DELETE of the parent listing row only.
    -- Soft delete (setting deleted_at) does not DELETE the row, so CASCADE
    -- does not fire. listing_attributes rows persist alongside soft-deleted
    -- listings — correct behaviour, needed if a listing is ever restored.
    -- A future purge job that hard-deletes old soft-deleted listings will
    -- trigger CASCADE cleanup automatically at that point.
);

-- +goose Down
DROP TABLE listing_attributes;