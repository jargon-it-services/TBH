# Refresh Token — Backend Contract

Status: **not yet implemented server-side.** The client (`RefreshTokenApi` +
`DioClient`) is fully built against this contract and works today in mock
mode. It will start working against the real backend the moment these two
endpoints exist, with no further client changes required.

## 1. `POST /auth/login` — needs to additionally return a refresh token

The client can't refresh a token it was never given. Today's login
response only contains `token`. Add `refresh_token` alongside it:

**Response (200):**
```json
{
  "status": true,
  "message": "Login successful",
  "data": {
    "token": "<short-lived JWT access token>",
    "refresh_token": "<longer-lived opaque or JWT refresh token>",
    "user_name": "Jordan Lee"
  }
}
```

Recommended lifetimes: access token 15–60 minutes, refresh token days-to-weeks,
rotated on every use (see §2).

## 2. `POST /auth/refresh` — new endpoint

**Request:**
```
POST /auth/refresh
Content-Type: application/json
```
```json
{
  "refresh_token": "<current refresh token>"
}
```
No `Authorization` header is sent on this call — the refresh token in the
body is the credential.

**Response — success (200):**
```json
{
  "status": true,
  "data": {
    "token": "<new access token>",
    "refresh_token": "<new refresh token>"
  }
}
```
`refresh_token` in the response should be a **rotated** value (issue a new
one, invalidate the old one) — this lets the backend detect refresh-token
reuse (a strong signal of a stolen token) and revoke the whole session.

**Response — failure (401):**
```json
{
  "status": false,
  "message": "Refresh token invalid or expired"
}
```
Any 401 here is treated by the client as "refresh failed" → it clears the
local session and sends the user to Login. It does **not** retry or attempt
another refresh.

## 3. Server-side expectations

- Reject expired, revoked, or already-rotated-away refresh tokens with `401`.
- Rotate the refresh token on every successful use (§2). If reuse of an
  already-rotated token is detected, revoke the entire refresh-token family
  for that user as a compromise signal.
- Rate-limit `/auth/refresh` per refresh token / per user to blunt brute-force
  attempts.
- `/auth/refresh` itself must not require the (expired) access token —
  otherwise refreshing an expired token becomes impossible.

## 4. Client-side behavior already implemented (for reference)

- Every protected request that gets a `401` triggers at most **one** refresh
  attempt, shared across any other requests that 401 at the same time
  (single-flight — no duplicate simultaneous `/auth/refresh` calls).
- On refresh success: new token (and rotated refresh token) is stored via
  `SessionManager`, then the original request is retried exactly once with
  the new token.
- If that retried request also 401s, the client does **not** attempt another
  refresh (loop guard) — it logs out immediately.
- On refresh failure: local session is cleared and the user is navigated to
  Login.
- `/auth/login`, `/auth/refresh`, `/register`, and `/forgot-password/*` never
  get an `Authorization` header attached, and a `401` from any of them is
  treated as a normal request failure, not a session event.
