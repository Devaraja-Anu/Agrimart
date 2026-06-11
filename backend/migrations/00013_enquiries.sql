-- +goose Up
CREATE TYPE enquiry_status AS ENUM ('pending', 'read', 'replied', 'closed');

CREATE TABLE enquiries (
    id         UUID           NOT NULL DEFAULT uuid_generate_v4(),
    listing_id UUID           NOT NULL REFERENCES listings(id) ON DELETE RESTRICT,
    sender_id  UUID           NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    message    TEXT           NOT NULL,
    status     enquiry_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    PRIMARY KEY (id)

    -- sender_id is named sender_id not buyer_id — a farmer enquiring about a
    -- service is not a "buyer" in the product sense.
    --
    -- ON DELETE RESTRICT on both listing_id and sender_id — enquiry history
    -- must be preserved. Do not allow deletion of users or listings that have
    -- enquiry history.
    --
    -- The seller is reachable via listing_id → listings.seller_profile_id.
    -- A denormalised seller_profile_id column on this table would avoid that
    -- join for seller inbox queries. Deferred — the join is acceptable at V1
    -- volume. Add seller_profile_id here in a future migration if either
    -- enquiry volume justifies it or direct messaging (inbox without listing
    -- context) gets built.
    --
    -- Future: LISTEN/NOTIFY trigger for real-time updates via Go → SSE/WebSocket.
    -- Deferred until notification infrastructure is built.
);

CREATE TRIGGER set_enquiries_updated_at
    BEFORE UPDATE ON enquiries
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- +goose Down
DROP TABLE enquiries;
DROP TYPE enquiry_status;