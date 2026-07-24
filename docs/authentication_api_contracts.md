# Authentication — Backend API Contracts

**Audience:** Backend team
**Source:** Generated from an audit of the Flutter client's networking layer (`lib/core/network/`) as of this document's date. Reflects what the client already sends/expects today, plus what it needs but doesn't have yet.
**Client conventions used throughout this doc** (already fixed on the client side, not up for negotiation without a client change):
- All responses are wrapped as `{ "status": bool, "message": string?, "data": {...}? }`.
- Protected endpoints receive `Authorization: Bearer <access_token>`.
- Timeouts: 30s connect / 30s receive.

---

## Summary Table

| API | Exists (backend) | Needed | Backend Action |
|---|---|---|---|
| **Login** | ⚠️ Assumed / unverified | Yes — verify or build | Client has been built and is calling `POST /auth/login` against a placeholder base URL (`https://api.yourdomain.com`) in an as-yet-unconnected environment; the app has only ever run in mock mode. Confirm this endpoint exists, is reachable, and matches the contract in §1 — in particular, **add `refresh_token` to the response**, which it does not currently include anywhere in the client's assumptions. |
| **Refresh Token** | ❌ Does not exist | Yes — build | New endpoint. See §2. Required before Login can issue usable sessions long-term (currently, once the access token expires, the user is force-logged-out with no ability to silently renew). |
| **Logout** | ❌ Does not exist | Yes — build | New endpoint. See §3. Client currently only clears its local session; the server has no way to revoke a token before its natural expiry. |
| **Current User** | ❌ Does not exist | Yes — build | New endpoint. See §4. Nothing today lets the client re-fetch the logged-in user's profile without going through Login again — needed for profile screens and for keeping displayed user info fresh across sessions. |
| **Session Validation** | ❌ Does not exist | Recommended — build | New, lightweight endpoint. See §5. Today the client treats "a token is stored locally" as "the user is logged in" at app startup, with no cheap way to confirm that token is still valid before committing to the Home screen. |

---

## 1. Login

### Endpoint
`POST /auth/login`

### Headers
```
Content-Type: application/json
```
No `Authorization` header (this is a public/unauthenticated endpoint).

### Request
```json
{
  "organization_code": "string, required",
  "email": "string, required, valid email format",
  "password": "string, required"
}
```

### Response — success (200)
```json
{
  "status": true,
  "message": "Login successful",
  "data": {
    "token": "string — short-lived JWT access token",
    "refresh_token": "string — longer-lived refresh token",
    "user_name": "string — display name"
  }
}
```
> `refresh_token` is **not currently part of the client's assumed response** — it must be added for the Refresh Token flow (§2) to function at all. Without it, every session ends the instant the access token expires, with no silent renewal possible.

Recommended lifetimes: access token 15–60 minutes; refresh token days-to-weeks, rotated on every use (see §2 validation notes).

### Validation
- `organization_code`: required, non-empty; format/lookup rules are backend-specific (not enforced client-side beyond "not empty").
- `email`: required; must be a syntactically valid email address.
- `password`: required, non-empty. (Client does not enforce a minimum length on the *login* form — only on registration/reset flows.)
- Reject if `organization_code` + `email` combination doesn't resolve to an active account.

### Error Responses
| Status | Scenario | Body |
|---|---|---|
| 400 | Missing/malformed field | `{ "status": false, "message": "Email is required" }` (or field-specific equivalent) |
| 401 | Wrong email/password | `{ "status": false, "message": "Invalid credentials" }` |
| 404 | Unknown `organization_code` | `{ "status": false, "message": "Organization not found" }` |
| 403 | Account disabled/locked | `{ "status": false, "message": "Account is disabled. Contact your administrator." }` |
| 429 | Too many attempts | `{ "status": false, "message": "Too many attempts. Try again later." }` |
| 500 | Server error | `{ "status": false, "message": "Something went wrong. Please try again." }` |

### Flutter Model Mapping
Already implemented client-side as `LoginResult` (`lib/core/network/apis/login_api.dart`):

| JSON field (`data.*`) | Dart field | Type |
|---|---|---|
| `token` | `authToken` | `String` |
| `user_name` | `userName` | `String` |
| `refresh_token` *(not yet consumed)* | — | would need a client change to also read this |

---

## 2. Refresh Token

### Endpoint
`POST /auth/refresh`

### Headers
```
Content-Type: application/json
```
No `Authorization` header — the refresh token in the body is the credential (the access token is, by definition, potentially expired at this point).

### Request
```json
{
  "refresh_token": "string, required — the current refresh token"
}
```

### Response — success (200)
```json
{
  "status": true,
  "data": {
    "token": "string — new access token",
    "refresh_token": "string — new (rotated) refresh token"
  }
}
```

### Validation
- `refresh_token`: required, non-empty.
- Must correspond to a non-expired, non-revoked, not-already-rotated-away refresh token.
- **Rotation:** issue a brand-new refresh token on every successful use and invalidate the one just consumed. This lets reuse of an already-rotated token be detected as a strong signal of theft — treat that as cause to revoke the entire token family for that user/session.
- Should not require/accept the (possibly expired) access token in any header — refreshing an expired token must not depend on that same token still being valid.

### Error Responses
| Status | Scenario | Body |
|---|---|---|
| 400 | Missing `refresh_token` | `{ "status": false, "message": "refresh_token is required" }` |
| 401 | Expired, revoked, unknown, or already-rotated-away refresh token | `{ "status": false, "message": "Refresh token invalid or expired" }` |
| 429 | Rate-limited (per token / per user) | `{ "status": false, "message": "Too many refresh attempts. Try again later." }` |
| 500 | Server error | `{ "status": false, "message": "Something went wrong. Please try again." }` |

Client behavior on any failure here: clear the local session entirely and navigate to Login — it does not retry or attempt a second refresh.

### Flutter Model Mapping
Already implemented client-side as `RefreshTokenResult` (`lib/core/network/apis/refresh_token_api.dart`):

| JSON field (`data.*`) | Dart field | Type |
|---|---|---|
| `token` | `authToken` | `String` |
| `refresh_token` | `refreshToken` | `String?` |

Full existing client-side design notes: `docs/refresh_token_backend_contract.md`.

---

## 3. Logout

### Endpoint
`POST /auth/logout`

### Headers
```
Authorization: Bearer <current access token>
Content-Type: application/json
```
Protected endpoint — no request body needed; the access token identifies which session to invalidate.

### Request
_None._

### Response — success (200)
```json
{
  "status": true,
  "data": {
    "message": "Logged out successfully"
  }
}
```

### Validation
- Requires a syntactically valid `Authorization` header. An already-expired/invalid token should still be treated as "fine, effectively already logged out" rather than a hard failure — see Error Responses below.

### Error Responses
| Status | Scenario | Body |
|---|---|---|
| 401 | Missing/invalid/expired token | `{ "status": false, "message": "Invalid or expired token" }` |
| 500 | Server error | `{ "status": false, "message": "Something went wrong. Please try again." }` |

Client behavior: treats **any** response here (including failures) as non-fatal — it clears the local session and navigates to Login regardless. So a 401 here is not a client-facing problem, but the backend should still correctly revoke whatever it can when the token *is* valid.

### Server-side expectations
- Invalidate/revoke the access token's underlying session (blacklist until natural expiry, or delete the session record).
- Also revoke the associated refresh token so it can't mint a new access token post-logout.

### Flutter Model Mapping
Already implemented client-side as `LogoutResult` (`lib/core/network/apis/logout_api.dart`):

| JSON field (`data.*`) | Dart field | Type |
|---|---|---|
| `message` | `message` | `String` |

Full existing client-side design notes: `docs/logout_backend_contract.md`.

---

## 4. Current User

### Endpoint
`GET /auth/me`

### Headers
```
Authorization: Bearer <access token>
```
Protected endpoint.

### Request
_None (no body, no query params)._

### Response — success (200)
```json
{
  "status": true,
  "data": {
    "id": "string — stable user id",
    "user_name": "string",
    "email": "string",
    "organization_code": "string",
    "role": "string — optional, if the app has role-based UI",
    "created_at": "string (ISO 8601) — optional"
  }
}
```
> Field list above is a reasonable starting point inferred from what Login already returns (`user_name`) plus what a typical account/profile screen needs (`email`, `organization_code` — both already collected at Login time client-side). Adjust to match whatever the actual user record contains; the client has no existing profile screen wired to real data yet; today the "Account" screen is fully static.

### Validation
- Valid, non-expired access token required.

### Error Responses
| Status | Scenario | Body |
|---|---|---|
| 401 | Missing/invalid/expired token | `{ "status": false, "message": "Invalid or expired token" }` |
| 404 | Token valid but user no longer exists (deleted account) | `{ "status": false, "message": "User not found" }` |
| 500 | Server error | `{ "status": false, "message": "Something went wrong. Please try again." }` |

A 401 here should go through the same refresh-then-retry flow the client already has for every other protected call (§2) — no special-casing needed on the client once the endpoint exists.

### Flutter Model Mapping
**Not yet implemented client-side** (per this task's scope, no Flutter code was written). Proposed, following the existing `*_api.dart` / `*Result` naming convention used by Login/Refresh/Logout:

| JSON field (`data.*`) | Proposed Dart field | Type |
|---|---|---|
| `id` | `userId` | `String` |
| `user_name` | `userName` | `String` |
| `email` | `email` | `String` |
| `organization_code` | `organizationCode` | `String` |
| `role` | `role` | `String?` |
| `created_at` | `createdAt` | `String?` (or `DateTime?` if parsed) |

Suggested file: `lib/core/network/apis/current_user_api.dart`, response class `CurrentUserResult`, called `GET /auth/me` via the existing `DioClient` — same pattern as every other `*_api.dart` file, not a new architecture.

---

## 5. Session Validation

### Endpoint
`GET /auth/validate`

### Headers
```
Authorization: Bearer <access token>
```
Protected endpoint.

### Request
_None._

### Response — success (200)
```json
{
  "status": true,
  "data": {
    "valid": true
  }
}
```

### Response — invalid session (401)
```json
{
  "status": false,
  "message": "Session is invalid or expired"
}
```

### Validation
- Purely checks whether the provided access token currently maps to an active, non-revoked session — no other business logic. Deliberately minimal payload (no user data) so it's cheap to call on every app startup.

### Error Responses
| Status | Scenario | Body |
|---|---|---|
| 401 | Token missing, malformed, expired, or revoked | `{ "status": false, "message": "Session is invalid or expired" }` |
| 500 | Server error | `{ "status": false, "message": "Something went wrong. Please try again." }` |

### Why this is separate from Current User (§4)
Both a 200 from `/auth/me` and a 200 from `/auth/validate` mean "the session is good," so on paper `/auth/validate` is optional. It's recommended anyway because:
- It's cheaper — no profile lookup/serialization on every app launch.
- It decouples "is my token still good" (startup gate) from "what does this user's profile look like" (account screen), so either can be cached, throttled, or changed independently.

If the backend team prefers not to build a separate endpoint, `/auth/me` (§4) can serve both purposes — a 200 response validates the session *and* returns the profile in one round trip; the client's Splash flow would then use `/auth/me` instead. This is a backend-side call to make; the client's App Startup Flow (Splash → check token → validate → Home/Login) can point at whichever the backend prefers.

### Flutter Model Mapping
**Not yet implemented client-side.** Proposed:

| JSON field (`data.*`) | Proposed Dart field | Type |
|---|---|---|
| `valid` | `isValid` | `bool` |

Suggested file: `lib/core/network/apis/session_validation_api.dart`, response class `SessionValidationResult` — same pattern as every other `*_api.dart` file.

---

## Notes for implementation planning

- §1 (Login) is the only one of these five that might already exist server-side in some form — everything else (§2–§5) is confirmed absent from the client's assumptions and needs to be built from scratch.
- §2 and §3 already have client-side implementations built against these exact contracts, running in mock mode (`Env.isMock = true` in `lib/core/network/env.dart`) — flipping that flag once these endpoints are live is the only client-side step required to connect them.
- §4 and §5 have no client-side implementation yet, by design (out of scope for this document, which is contracts-only, not code).
