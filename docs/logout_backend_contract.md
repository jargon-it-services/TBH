# Logout — Backend Contract

Status: **not yet implemented server-side.** The client (`LogoutApi`) is
fully built against this contract and works today in mock mode. It will
start working against the real backend the moment this endpoint exists,
with no further client changes required.

## `POST /auth/logout` — new endpoint

**Request:**
```
POST /auth/logout
Authorization: Bearer <current access token>
```
No request body required. The access token in the header identifies which
session to invalidate.

**Response — success (200):**
```json
{
  "status": true,
  "data": {
    "message": "Logged out successfully"
  }
}
```

**Response — failure (401):**
```json
{
  "status": false,
  "message": "Invalid or expired token"
}
```
The client treats any non-success response here as non-fatal: it still
clears the local session and navigates to Login regardless (see
"Client-side behavior" below) — an already-invalid/expired token is, from
the user's perspective, already logged out.

## Server-side expectations

- Invalidate/revoke the access token's underlying session server-side
  (e.g. blacklist the token until natural expiry, or delete the session
  record it maps to).
- Also revoke the associated refresh token (see
  `docs/refresh_token_backend_contract.md`) so it can't be used to mint a
  new access token after logout.
- This endpoint is protected — it must require a valid `Authorization`
  header like any other protected route, not be added to a public-path
  allowlist.

## Client-side behavior already implemented (for reference)

- Logout is only triggered after the user confirms in a dialog (Profile →
  Logout → Confirmation Dialog).
- On confirm: calls `POST /auth/logout` (best-effort), then unconditionally
  clears the local JWT, refresh token, and session state, regardless of
  whether the API call succeeded — a network failure here shouldn't trap
  the user in a logged-in-looking state.
- `onboarding_completed` is untouched by this — it lives in a completely
  separate storage key that logout never reads or writes.
- Navigation clears the entire stack (`pushNamedAndRemoveUntil`) to
  Login, so the Back button cannot return to any authenticated screen.
