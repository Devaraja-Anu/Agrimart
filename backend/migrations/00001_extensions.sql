-- +goose Up

-- uuid_generate_v4() for all primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- GEOGRAPHY columns and ST_DWithin proximity search
CREATE EXTENSION IF NOT EXISTS postgis;
--  GIN trigram index for ILIKE fallback search 
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- +goose Down

-- Extensions are global to the database. They do not get "activated"
--  per table; they are simply installed. Keeping them installed is harmless.


-- DROP EXTENSION IF EXISTS pg_trgm;
-- DROP EXTENSION IF EXISTS postgis;
-- DROP EXTENSION IF EXISTS "uuid-ossp";