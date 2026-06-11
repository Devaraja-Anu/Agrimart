-- name: GetUserByPhone :one
-- Returns the user row regardless of deleted_at.
-- The caller decides how to handle a soft-deleted result (reactivation flow,
-- duplicate account protection etc.). Do not add AND deleted_at IS NULL here.
SELECT * FROM users
WHERE phone = $1
LIMIT 1;

-- name: GetUserByID :one
-- Active users only. Used by auth middleware on every authenticated request.
SELECT * FROM users
WHERE id = $1
  AND deleted_at IS NULL;

-- name: CreateUser :one
INSERT INTO users (phone)
VALUES ($1)
RETURNING *;

-- name: UpdateLastSeen :exec
-- Called on every authenticated request. No return needed.
UPDATE users
SET last_seen_at = NOW()
WHERE id = $1
  AND deleted_at IS NULL;

-- name: DeleteUser :one
-- Soft delete. Returns the updated row so the handler can confirm deletion
-- and clear the session.
UPDATE users
SET deleted_at = NOW()
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: ReactivateUser :one
-- Clears deleted_at and reactivates a soft-deleted account.
-- Called by the recovery flow when a user re-registers with a phone number
-- that belongs to a soft-deleted row.
UPDATE users
SET deleted_at  = NULL,
    is_active   = TRUE,
    last_seen_at = NOW()
WHERE id = $1
  AND deleted_at IS NOT NULL
RETURNING *;