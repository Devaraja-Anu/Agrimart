-- name: GetRolesByUserID :many
-- Returns all roles for a user. Called after login to populate JWT claims.
SELECT role FROM user_roles
WHERE user_id = $1
ORDER BY role;

-- name: AddRole :exec
-- Adds a role to a user. ON CONFLICT DO NOTHING — safe to call even if the
-- role already exists (idempotent). No return needed.
INSERT INTO user_roles (user_id, role)
VALUES ($1, $2)
ON CONFLICT DO NOTHING;

-- name: HasRole :one
-- Returns TRUE if the user holds the given role. Used by middleware for
-- role-based access checks without fetching the full role list.
SELECT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = $1
      AND role = $2
) AS has_role;

-- name: RemoveRole :exec
-- Removes a single role from a user. Does not delete the user.
DELETE FROM user_roles
WHERE user_id = $1
  AND role = $2;