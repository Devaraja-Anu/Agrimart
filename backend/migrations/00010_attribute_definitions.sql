-- +goose Up
CREATE TYPE attribute_input_type AS ENUM (
    'select',
    'multiselect',
    'boolean',
    'number',
    'text'
);

CREATE TABLE attribute_definitions (
    id          UUID                 NOT NULL DEFAULT uuid_generate_v4(),
    category_id UUID                 REFERENCES categories(id) ON DELETE RESTRICT,
    name        TEXT                 NOT NULL,
    slug        TEXT                 NOT NULL,
    input_type  attribute_input_type NOT NULL,
    options     JSONB,
    unit        TEXT,
    is_required BOOLEAN              NOT NULL DEFAULT FALSE,
    sort_order  INTEGER              NOT NULL DEFAULT 10,
    is_active   BOOLEAN              NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ          NOT NULL DEFAULT NOW(),

    PRIMARY KEY (id),

    CONSTRAINT attribute_definitions_slug_unique UNIQUE (slug),

    -- options must be present for select and multiselect types
    CONSTRAINT attribute_definitions_options_required CHECK (
        (input_type IN ('select', 'multiselect') AND options IS NOT NULL) OR
        (input_type NOT IN ('select', 'multiselect'))
    )

    -- is_required is a frontend hint only — not enforced at the DB level.
    -- Business logic (which attributes are required for submission) lives in Go.
    -- category_id NULL means the attribute applies globally to all listings
    -- (e.g. "Languages Spoken", "Payment Accepted").
);

-- Two partial unique indexes to handle the NULL category_id (global) case.


-- Uniqueness among category-specific attributes
-- for example, In "Electronics," you cannot have two attributes named "Screen Size."
--  But you can have "Screen Size" in "Electronics" and also 
--  have "Screen Size" in "Laptops" (assuming they are different categories).
CREATE UNIQUE INDEX idx_attr_def_name_category
    ON attribute_definitions (name, category_id)
    WHERE category_id IS NOT NULL;

-- Uniqueness among global attributes
-- This ensures you cannot accidentally create two different global attributes 
-- with the same name (e.g., creating "Payment Accepted" or "delivery radius" twice).
CREATE UNIQUE INDEX idx_attr_def_name_global
    ON attribute_definitions (name)
    WHERE category_id IS NULL;

-- if we used a single UNIQUE(name, category_id), it would fail to 
-- enforce global uniqueness because SQL treats NULL as a unique value
-- so we might have a ton of the same category with the same name.

-- +goose Down
DROP TABLE attribute_definitions;
DROP TYPE attribute_input_type;