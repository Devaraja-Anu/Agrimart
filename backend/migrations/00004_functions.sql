-- +goose Up
-- Shared trigger function. Defined once here, attached to every table that has
-- an updated_at column via CREATE TRIGGER in that table's own migration.
-- Do NOT redefine this function in any other migration file.
CREATE OR REPLACE FUNCTION set_updated_at()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- +goose Down
-- CASCADE drops all triggers that depend on this function across all tables.
DROP FUNCTION IF EXISTS set_updated_at() CASCADE;