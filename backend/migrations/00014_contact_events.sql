-- +goose Up
CREATE TYPE contact_event_type AS ENUM ('whatsapp_click', 'phone_click');

CREATE TABLE contact_events (
    id         UUID               NOT NULL DEFAULT uuid_generate_v4(),
    listing_id UUID               NOT NULL REFERENCES listings(id) ON DELETE RESTRICT,
    buyer_id   UUID               REFERENCES users(id) ON DELETE RESTRICT,
    event_type contact_event_type NOT NULL,
    ip_address INET,
    created_at TIMESTAMPTZ        NOT NULL DEFAULT NOW(),

    PRIMARY KEY (id)

    -- buyer_id is nullable — unauthenticated taps are valid and expected.
    -- Most early taps will be anonymous (buyer has not signed up yet).
    --
    -- ip_address is personal data under the Indian Digital Personal Data
    -- Protection Act 2023. Retention is capped at 12 months. A nightly
    -- background job in the Go application deletes rows WHERE
    -- created_at < NOW() - INTERVAL '12 months'.
    -- Do not extend retention without a privacy review.
    --
    -- Append-only: no updated_at, no deleted_at. Rows are never mutated.
    -- The nightly purge job hard-deletes expired rows — the only write
    -- operation on this table after insert.
    --
    -- last_activity_at on listings is NOT updated by a trigger on this table.
    -- The Go application layer handles it with a 10-minute debounce per
    -- listing_id to prevent write amplification.
    --
    -- Table records intent (button tap), not confirmed contact. Once the user
    -- leaves the platform the interaction is untrackable — expected and acceptable.
    --
    -- Partitioning by month is deferred until volume justifies it.
);

-- +goose Down
DROP TABLE contact_events;
DROP TYPE contact_event_type;