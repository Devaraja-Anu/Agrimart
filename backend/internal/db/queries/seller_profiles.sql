-- name: CreateSellerProfile :one
INSERT INTO seller_profiles (
    user_id,
    display_name,
    is_business,
    business_name,
    gst_number,
    whatsapp_number,
    has_whatsapp,
    house_name,
    landmark,
    pincode,
    district_id,
    state_id,
    location
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12,
    ST_GeogFromText('SRID=4326;POINT(' || $13::float8 || ' ' || $14::float8 || ')')
)
RETURNING *;

-- name: GetSellerProfileByUserID :one
-- Active profiles only. Primary lookup — most handlers know the user_id
-- from the JWT and need the seller profile from it.
SELECT * FROM seller_profiles
WHERE user_id = $1
  AND deleted_at IS NULL;

-- name: GetSellerProfileByID :one
-- Active profiles only. Used when a buyer views a seller's profile page
-- and the lookup is by profile ID rather than user ID.
SELECT * FROM seller_profiles
WHERE id = $1
  AND deleted_at IS NULL;

-- name: GetSellerProfileByIDAdmin :one
-- Bypasses soft delete. Admin panel only — do not use in public handlers.
SELECT * FROM seller_profiles
WHERE id = $1;

-- name: UpdateSellerProfile :one
-- Full profile update. Caller sends every field. Used for the seller's
-- own profile edit flow where all fields are present in the form submission.
UPDATE seller_profiles
SET display_name     = $2,
    is_business      = $3,
    business_name    = $4,
    gst_number       = $5,
    whatsapp_number  = $6,
    has_whatsapp     = $7,
    house_name       = $8,
    landmark         = $9,
    pincode          = $10,
    district_id      = $11,
    state_id         = $12,
    location         = ST_GeogFromText('SRID=4326;POINT(' || $13::float8 || ' ' || $14::float8 || ')')
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: SetSellerAvailability :one
-- Surgical update. Seller toggles their availability status — happens
-- frequently and independently of any other profile change.
UPDATE seller_profiles
SET is_available = $2
WHERE id = $1
  AND deleted_at IS NULL
RETURNING id, is_available, updated_at;

-- name: VerifySellerProfile :one
-- Surgical update. Admin action — sets verified state, timestamp, and
-- the admin who performed the verification.
UPDATE seller_profiles
SET is_verified = TRUE,
    verified_at = NOW(),
    verified_by = $2
WHERE id = $1
  AND deleted_at IS NULL
RETURNING id, is_verified, verified_at, verified_by;

-- name: DeleteSellerProfile :one
-- Soft delete. Returns updated row for confirmation.
UPDATE seller_profiles
SET deleted_at = NOW()
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;