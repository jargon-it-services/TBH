# Backend API Documentation

**Project:** TBH  
**Scope:** Every backend API call made by the client, reverse-engineered from `lib/core/network/apis/` (28 files, 75 individual endpoint calls across our own backend and 2 third-party public services).  
## Table of Contents

**Auth & Session**
- [API_001 — Login](#api_001--login)
- [API_002 — Refresh Token](#api_002--refresh-token)
- [API_003 — Logout](#api_003--logout)

**Registration & Forgot Password**
- [API_004 — Register Business](#api_004--register-business)
- [API_005 — Verify Organization](#api_005--verify-organization)
- [API_006 — Send OTP](#api_006--send-otp)
- [API_007 — Verify OTP](#api_007--verify-otp)
- [API_008 — Reset Password](#api_008--reset-password)

**App / Profile / Account**
- [API_009 — Check App Version](#api_009--check-app-version)
- [API_010 — Fetch Profile](#api_010--fetch-profile)
- [API_011 — Fetch Account Info](#api_011--fetch-account-info)
- [API_012 — Update Account Info](#api_012--update-account-info)
- [API_013 — Delete Account](#api_013--delete-account)
- [API_014 — Get Referral Invite Link](#api_014--get-referral-invite-link)

**Dashboard**
- [API_015 — Fetch Admin Dashboard](#api_015--fetch-admin-dashboard)
- [API_016 — Fetch Revenue Trend](#api_016--fetch-revenue-trend)
- [API_017 — Fetch Dashboard Header](#api_017--fetch-dashboard-header)

**Firms**
- [API_018 — Create Firm](#api_018--create-firm)
- [API_019 — Fetch Firms](#api_019--fetch-firms)
- [API_020 — Fetch Firm Detail](#api_020--fetch-firm-detail)

**Branches**
- [API_021 — Fetch Branches](#api_021--fetch-branches)
- [API_022 — Fetch Branch Detail](#api_022--fetch-branch-detail)
- [API_023 — Create Branch](#api_023--create-branch)
- [API_024 — Update Branch](#api_024--update-branch)

**Services**
- [API_025 — Fetch Services Catalog](#api_025--fetch-services-catalog)
- [API_026 — Fetch Service List](#api_026--fetch-service-list)
- [API_027 — Fetch Service Detail](#api_027--fetch-service-detail)
- [API_028 — Create Service](#api_028--create-service)
- [API_029 — Update Service](#api_029--update-service)
- [API_030 — Delete Service](#api_030--delete-service)

**Staff**
- [API_031 — Fetch Staff Form Config](#api_031--fetch-staff-form-config)
- [API_032 — Fetch Staff List](#api_032--fetch-staff-list)
- [API_033 — Fetch Staff Detail](#api_033--fetch-staff-detail)
- [API_034 — Fetch Next Employee Code](#api_034--fetch-next-employee-code)
- [API_035 — Create Staff](#api_035--create-staff)
- [API_036 — Update Staff](#api_036--update-staff)
- [API_037 — Delete Staff](#api_037--delete-staff)

**Salary Rules**
- [API_038 — Fetch Salary Rules Catalog](#api_038--fetch-salary-rules-catalog)
- [API_039 — Fetch Salary Rule List](#api_039--fetch-salary-rule-list)
- [API_040 — Fetch Salary Rule Detail](#api_040--fetch-salary-rule-detail)
- [API_041 — Create Salary Rule](#api_041--create-salary-rule)
- [API_042 — Update Salary Rule](#api_042--update-salary-rule)
- [API_043 — Delete Salary Rule](#api_043--delete-salary-rule)

**Expenses**
- [API_044 — Fetch Expense List](#api_044--fetch-expense-list)
- [API_045 — Fetch Expense Detail](#api_045--fetch-expense-detail)
- [API_046 — Create Expense](#api_046--create-expense)
- [API_047 — Update Expense](#api_047--update-expense)
- [API_048 — Delete Expense](#api_048--delete-expense)

**Transactions**
- [API_049 — Fetch Transaction Bootstrap](#api_049--fetch-transaction-bootstrap)
- [API_050 — Create Transaction](#api_050--create-transaction)
- [API_051 — Update Transaction](#api_051--update-transaction)
- [API_052 — Mark Transaction Paid](#api_052--mark-transaction-paid)
- [API_053 — Fetch Transactions List](#api_053--fetch-transactions-list)
- [API_054 — Fetch Transaction Details](#api_054--fetch-transaction-details)

**Reports**
- [API_055 — Fetch P&L Report](#api_055--fetch-pl-report)
- [API_056 — Export P&L Report](#api_056--export-pl-report)
- [API_057 — Fetch Revenue & Expense Report](#api_057--fetch-revenue--expense-report)
- [API_058 — Export Revenue & Expense Report](#api_058--export-revenue--expense-report)
- [API_059 — Fetch Payment Mode Report](#api_059--fetch-payment-mode-report)

**Payments & Subscription**
- [API_060 — Fetch Payment History](#api_060--fetch-payment-history)
- [API_061 — Fetch Payment Details](#api_061--fetch-payment-details)
- [API_062 — Create Razorpay Order](#api_062--create-razorpay-order)
- [API_063 — Save Razorpay Payment Result](#api_063--save-razorpay-payment-result)
- [API_064 — Fetch Plan Catalog](#api_064--fetch-plan-catalog)
- [API_065 — Fetch Subscription Status](#api_065--fetch-subscription-status)
- [API_066 — Activate Free Trial](#api_066--activate-free-trial)

**Notifications**
- [API_067 — Fetch Notifications](#api_067--fetch-notifications)
- [API_068 — Fetch Notification By Id](#api_068--fetch-notification-by-id)
- [API_069 — Mark Notification Read](#api_069--mark-notification-read)
- [API_070 — Mark All Notifications Read](#api_070--mark-all-notifications-read)
- [API_071 — Delete Notification](#api_071--delete-notification)
- [API_072 — Delete All Read Notifications](#api_072--delete-all-read-notifications)

**Third-Party APIs (Not Our Backend)**
- [API_073 — Fetch Indian States (3rd-Party)](#api_073--fetch-indian-states-3rd-party)
- [API_074 — Fetch Cities For State (3rd-Party)](#api_074--fetch-cities-for-state-3rd-party)
- [API_075 — Verify Pincode (3rd-Party)](#api_075--verify-pincode-3rd-party)

---

# Module: Auth & Session

## API_001 — Login

| Field | Detail |
|---|---|
| **1. API Name** | Login |
| **2. Purpose** | Authenticates a user with organization code, email, and password; issues an access token, refresh token, and the user's session bootstrap data (profile, account, current plan, management counters, feature locks). |
| **3. Endpoint** | `/auth/login` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Not required. This endpoint is in `DioClient`'s `_publicPaths` allow-list, so no `Authorization` header is sent and a `401` response is treated as a normal credential/validation failure, not a session expiry. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

| Field | Type | Required |
|---|---|---|
| `organization_code` | string | Yes |
| `email` | string | Yes |
| `password` | string | Yes |

**10. Validation Rules**

- All three fields required (non-empty), enforced client-side before the call is made.
- `email` expected to be a valid email format (client-side only; server-side rule not documented).
- Server is the source of truth for credential correctness; client places no length/format constraint on `password`.

**11. Success Response**

`200` — `status: true`, `data` contains `token`, `refresh_token`, `expires_in` (seconds), `user_info` (id, user_name, email, mobile, role, profile_image, status), `account` (name, code, branch_name), `recent_plan` (name, valid_until, status, date_format), `management` (total_firms, total_staff, total_services, total_expenses, total_salary_rules), `feature_lock` (array of locked feature keys).

**12. Error Responses**

`401` — invalid organization code, email, or password. `400` — missing/malformed fields.

**13. Sample Request**

```
POST /auth/login
Content-Type: application/json

{
  "organization_code": "JAR-1233",
  "email": "krusna.satbhai@gmail.com",
  "password": "••••••••"
}
```

**14. Sample Success Response**

```json
{
  "status": true,
  "message": "Login successful",
  "data": {
    "token": "mock_auth_token_7c21f9ab",
    "refresh_token": "mock_refresh_token_7c21f9ab",
    "expires_in": 86400,
    "user_info": {
      "id": 101,
      "user_name": "Krushna Satbhai",
      "email": "krusna.satbhai@gmail.com",
      "mobile": "8793052520",
      "role": "account_admin",
      "profile_image": null,
      "status": "active"
    },
    "account": { "name": "Jargon pvt lts", "code": "JAR-1233", "branch_name": "Pune" },
    "recent_plan": { "name": "Pro", "valid_until": "2027-07-14", "status": "active", "date_format": "dd MMM yyyy" },
    "management": { "total_firms": 14, "total_staff": 520, "total_services": 200, "total_expenses": 18, "total_salary_rules": 6 },
    "feature_lock": []
  }
}
```

**15. Sample Error Response**

```json
{
  "status": false,
  "message": "Invalid credentials"
}
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- `role` returned in `user_info.role` drives which dashboard/header variant the client renders (Super Admin / Account Admin / Branch Admin / Manager / Employee — see API_017).
- `feature_lock` gates client-side visibility of paid features (e.g. `report`, `payment_slip`, `pnl`) based on the account's current plan.
- Response shape changed from a flat `{token, refresh_token, user_name, role}` to the nested `user_info`/`account`/`recent_plan`/`management` shape documented here; the client keeps `userName`/`role` convenience getters for backward compatibility.

**18. Notes**

- `token` and `refresh_token` are persisted client-side (secure storage) via `SessionManager` immediately after a successful call.
- This is the only endpoint (besides Register) that establishes a session; every other protected call depends on the token issued here.
- `expires_in` is optional in the payload; the client tolerates its absence.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_002 — Refresh Token

| Field | Detail |
|---|---|
| **1. API Name** | Refresh Token |
| **2. Purpose** | Exchanges a valid refresh token for a new access token (and optionally a rotated refresh token), used transparently by the client when a protected call returns 401. |
| **3. Endpoint** | `/auth/refresh` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Not required. This endpoint is in `DioClient`'s `_publicPaths` allow-list, so no `Authorization` header is sent and a `401` response is treated as a normal credential/validation failure, not a session expiry. (Not in the sense of being user-facing — this call itself carries no bearer token; the refresh token is the credential, sent in the body.) |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

| Field | Type | Required |
|---|---|---|
| `refresh_token` | string | Yes |

**10. Validation Rules**

- `refresh_token` required, non-empty.
- Server must reject an expired/revoked/unknown refresh token with `401` specifically — this is the one status code the client treats as "session is truly over"; any other failure (timeout, 5xx, malformed response) is treated as transient and does **not** log the user out.

**11. Success Response**

`200` — `status: true`, `data.token` (new access token), `data.refresh_token` (new refresh token, optional — omit to keep the old one valid, per backend's rotation policy).

**12. Error Responses**

`401` — refresh token invalid, expired, or revoked. Any other error is treated by the client as network/transient, not a rejection.

**13. Sample Request**

```
POST /auth/refresh
Content-Type: application/json

{ "refresh_token": "mock_refresh_token_7c21f9ab" }
```

**14. Sample Success Response**

```json
{
  "status": true,
  "message": "Token refreshed",
  "data": {
    "token": "mock_auth_token_refreshed_9f31ab",
    "refresh_token": "mock_refresh_token_9f31ab"
  }
}
```

**15. Sample Error Response**

```json
{
  "status": false,
  "message": "Refresh token invalid or expired"
}
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |
| 409 | Not expected, but if returned is treated as a non-fatal transient failure, not a session rejection. |

**17. Business Rules**

- Concurrent 401s from multiple simultaneous requests are coalesced client-side into a single in-flight refresh call — the backend should not expect a refresh storm even if several requests fail at once.
- On success, the retried original request is re-issued once with the new token; a second 401 after that retry is treated as a hard session failure (auto-logout) with no further refresh attempt (loop guard).

**18. Notes**

**Backend status: not yet implemented at time of writing** (per in-code contract comment `docs/refresh_token_backend_contract.md`). The client is fully wired against this contract and currently resolves from a local mock JSON in mock mode.

**19. Change Log**

v1.0 — Documented against the client's implemented contract; endpoint pending backend implementation.

---

## API_003 — Logout

| Field | Detail |
|---|---|
| **1. API Name** | Logout |
| **2. Purpose** | Invalidates the current session/tokens on the server side. |
| **3. Endpoint** | `/auth/logout` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. **Exception:** a 401 from this specific call is deliberately NOT routed through the refresh/auto-logout interceptor — the caller already runs its own "clear session, go to Login" sequence regardless of this call's outcome, to avoid two logout flows racing each other. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

None beyond a valid Authorization header.

**11. Success Response**

`200` — `status: true`, `data.message`.

**12. Error Responses**

`401` — invalid/expired token (handled locally by the caller, not the global interceptor).

**13. Sample Request**

```
POST /auth/logout
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{
  "status": true,
  "message": "Logged out successfully",
  "data": { "message": "Logged out successfully" }
}
```

**15. Sample Error Response**

```json
{
  "status": false,
  "message": "Invalid or expired token"
}
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Client clears local session state and navigates to Login regardless of whether this call ultimately succeeds — this is fire-and-forget from a UX standpoint.

**18. Notes**

**Backend status: not yet implemented at time of writing** (contract documented in-code, resolves from local mock JSON in mock mode).

**19. Change Log**

v1.0 — Documented against the client's implemented contract; endpoint pending backend implementation.

---

# Module: Registration & Forgot Password

## API_004 — Register Business

| Field | Detail |
|---|---|
| **1. API Name** | Register Business |
| **2. Purpose** | Creates a new business account (organization) along with its owner/admin user, including identity document upload, and returns an access token for immediate sign-in. |
| **3. Endpoint** | `/register` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Not required. This endpoint is in `DioClient`'s `_publicPaths` allow-list, so no `Authorization` header is sent and a `401` response is treated as a normal credential/validation failure, not a session expiry. |
| **6. Headers** | `Content-Type: multipart/form-data` (set automatically by Dio when the request body is a `FormData` instance, i.e. whenever a file is attached). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

Multipart form fields:

| Field | Type | Required |
|---|---|---|
| `address` | string | Yes |
| `city` | string | Yes |
| `state` | string | Yes |
| `zip` | string | Yes |
| `phone` | string | Yes |
| `business_email` | string | Yes |
| `gstin` | string | No |
| `account_photo` | file | No |
| `owner_name` | string | Yes |
| `designation` | string | Yes |
| `id_proof_type` | string | Yes |
| `id_proof_number` | string | Yes |
| `id_proof_document` | file | Yes |
| `login_email` | string | Yes |
| `password` | string | Yes |
| `platform` | string | Yes (auto-attached, not user-entered) |
| `invite_token` | string | No (auto-attached from a stored deep-link invite, if present) |

**10. Validation Rules**

- All fields marked Required must be non-empty; `gstin` and `account_photo` are optional.
- `id_proof_document` is mandatory (unlike `account_photo`).
- `platform` is resolved internally (device/platform identifier) and never shown to or editable by the user.
- `invite_token`, if a prior deep link stored one, is attached silently without any UI field for it.

**11. Success Response**

`200` — `status: true`, `data` contains `token`, `business_name`, `business_id`, `verification_status`, `gstin`, `account_photo_url`.

**12. Error Responses**

`400`/`422` — validation failure on any required field. Backend may also return a machine-readable `error_code` (e.g. `invite_invalid`, `invite_expired`, `invite_revoked`) specifically for a dead invite token.

**13. Sample Request**

```
POST /register
Content-Type: multipart/form-data; boundary=...

address=221B, Residency Road
city=Bengaluru
state=Karnataka
zip=560025
phone=9876500000
business_email=accounts@glowandco.example
owner_name=Ananya Rao
designation=Founder
id_proof_type=PAN Card
id_proof_number=ABCDE1234F
id_proof_document=<binary>
login_email=ananya.rao@glowandco.example
password=••••••••
platform=android
```

**14. Sample Success Response**

```json
{
  "status": true,
  "message": "Business registered successfully",
  "data": {
    "token": "mock_auth_token_9f83a2c1",
    "business_name": "Meridian Trading Co.",
    "business_id": "BIZ-100234",
    "verification_status": "pending_review",
    "gstin": "27ABCDE1234F1Z5",
    "account_photo_url": null
  }
}
```

**15. Sample Error Response**

```json
{
  "status": false,
  "message": "Registration failed",
  "error_code": "invite_expired"
}
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- If an `invite_token` was attached: on registration success, or if the backend's `error_code` identifies the invite as dead (`invite_invalid` / `invite_expired` / `invite_revoked`), the client deletes its locally stored invite token. For any other failure (validation, network), the token is kept so the user can retry.
- `verification_status` in the response (e.g. `pending_review`) implies the backend may run manual/async verification after registration — not surfaced elsewhere in the client beyond this initial value.

**18. Notes**

- The client issues a session token (`token`) directly from this call, i.e. registration doubles as login — no separate login call is made right after successful registration.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_005 — Verify Organization

| Field | Detail |
|---|---|
| **1. API Name** | Verify Organization |
| **2. Purpose** | First step of the Forgot Password flow — confirms an organization code exists and returns its display name for user confirmation before proceeding to OTP. |
| **3. Endpoint** | `/forgot-password/verify-organization` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Not required. This endpoint is in `DioClient`'s `_publicPaths` allow-list, so no `Authorization` header is sent and a `401` response is treated as a normal credential/validation failure, not a session expiry. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

| Field | Type | Required |
|---|---|---|
| `organization_code` | string | Yes |

**10. Validation Rules**

- `organization_code` required, non-empty.

**11. Success Response**

`200` — `status: true`, `data.organization_name`.

**12. Error Responses**

`404`/`400` — organization code not found.

**13. Sample Request**

```
POST /forgot-password/verify-organization
Content-Type: application/json

{ "organization_code": "JAR-1233" }
```

**14. Sample Success Response**

```json
{
  "status": true,
  "message": "Organization verified successfully",
  "data": { "organization_name": "Meridian Trading Co." }
}
```

**15. Sample Error Response**

```json
{
  "status": false,
  "message": "Organization code not found"
}
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Purely a lookup/confirmation step; does not itself advance any server-side reset-flow state machine beyond what Send OTP (API_006) requires.

**18. Notes**

Part of a 4-step Forgot Password sequence: Verify Organization → Send OTP → Verify OTP → Reset Password (API_005–API_008), each step's output feeding the next.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_006 — Send OTP

| Field | Detail |
|---|---|
| **1. API Name** | Send OTP |
| **2. Purpose** | Sends a one-time password to the account's registered email address as the second step of Forgot Password. |
| **3. Endpoint** | `/forgot-password/send-otp` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Not required. This endpoint is in `DioClient`'s `_publicPaths` allow-list, so no `Authorization` header is sent and a `401` response is treated as a normal credential/validation failure, not a session expiry. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

| Field | Type | Required |
|---|---|---|
| `organization_code` | string | Yes |
| `email` | string | Yes |

**10. Validation Rules**

- Both fields required.
- `email` should match the account on file for `organization_code` (server-enforced).

**11. Success Response**

`200` — `status: true`, `data.message`, `data.expiry_seconds` (OTP validity window, e.g. 300).

**12. Error Responses**

`404`/`400` — organization/email combination not found, or rate-limited.

**13. Sample Request**

```
POST /forgot-password/send-otp
Content-Type: application/json

{ "organization_code": "JAR-1233", "email": "krusna.satbhai@gmail.com" }
```

**14. Sample Success Response**

```json
{
  "status": true,
  "message": "OTP sent to your registered email address",
  "data": { "message": "OTP sent to your registered email address", "expiry_seconds": 300 }
}
```

**15. Sample Error Response**

```json
{
  "status": false,
  "message": "Could not send OTP"
}
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |
| 429 | Too many OTP requests in a short window (recommended; not confirmed against a live backend). |

**17. Business Rules**

- `expiry_seconds` returned by the server drives the client's OTP countdown/resend-enable timer.

**18. Notes**

Second step of the 4-step Forgot Password sequence (API_005–API_008).

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_007 — Verify OTP

| Field | Detail |
|---|---|
| **1. API Name** | Verify OTP |
| **2. Purpose** | Validates the OTP entered by the user and issues a short-lived reset token used to authorize the final password change. |
| **3. Endpoint** | `/forgot-password/verify-otp` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Not required. This endpoint is in `DioClient`'s `_publicPaths` allow-list, so no `Authorization` header is sent and a `401` response is treated as a normal credential/validation failure, not a session expiry. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

| Field | Type | Required |
|---|---|---|
| `organization_code` | string | Yes |
| `email` | string | Yes |
| `otp` | string | Yes |

**10. Validation Rules**

- All three fields required.
- `otp` must match the one most recently sent for this `organization_code`/`email` pair and not be expired.

**11. Success Response**

`200` — `status: true`, `data.reset_token`.

**12. Error Responses**

`400`/`401` — invalid or expired OTP.

**13. Sample Request**

```
POST /forgot-password/verify-otp
Content-Type: application/json

{ "organization_code": "JAR-1233", "email": "krusna.satbhai@gmail.com", "otp": "482913" }
```

**14. Sample Success Response**

```json
{
  "status": true,
  "message": "OTP verified successfully",
  "data": { "reset_token": "mock_reset_token_7f2ab9" }
}
```

**15. Sample Error Response**

```json
{
  "status": false,
  "message": "Invalid or expired OTP"
}
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- `reset_token` returned here must be presented (implicitly — see Notes) to authorize the final Reset Password call; treat it as a single-use, short-lived credential.

**18. Notes**

Third step of the 4-step Forgot Password sequence. **Contract inconsistency to flag for backend alignment:** the client's current `resetPassword` call (API_008) does not actually send `reset_token` in its request body — only `organization_code`/`email`/`otp`/`password`. Backend should confirm whether `reset_token` or the repeated `otp` is the intended authorization mechanism for the final step, and the client updated accordingly.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_008 — Reset Password

| Field | Detail |
|---|---|
| **1. API Name** | Reset Password |
| **2. Purpose** | Final step of Forgot Password — sets a new password for the account. |
| **3. Endpoint** | `/forgot-password/reset` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Not required. This endpoint is in `DioClient`'s `_publicPaths` allow-list, so no `Authorization` header is sent and a `401` response is treated as a normal credential/validation failure, not a session expiry. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

| Field | Type | Required |
|---|---|---|
| `organization_code` | string | Yes |
| `email` | string | Yes |
| `otp` | string | Yes |
| `password` | string | Yes (new password) |

**10. Validation Rules**

- All fields required.
- `password` should meet whatever complexity policy the backend enforces (not encoded client-side beyond non-empty).

**11. Success Response**

`200` — `status: true`, `data.message`.

**12. Error Responses**

`400`/`401` — OTP no longer valid for this step, or password fails policy.

**13. Sample Request**

```
POST /forgot-password/reset
Content-Type: application/json

{
  "organization_code": "JAR-1233",
  "email": "krusna.satbhai@gmail.com",
  "otp": "482913",
  "password": "••••••••"
}
```

**14. Sample Success Response**

```json
{
  "status": true,
  "message": "Password changed successfully",
  "data": { "message": "Password changed successfully" }
}
```

**15. Sample Error Response**

```json
{
  "status": false,
  "message": "Failed to change password"
}
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- On success the user is expected to log in again via API_001 with the new password; this call does not itself issue a session token.

**18. Notes**

See API_007's Notes regarding the `reset_token` vs. `otp` inconsistency between the documented 3-step contract and the client's actual request payload — recommend backend and client teams confirm the intended field before this goes live.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

# Module: App / Profile / Account

## API_009 — Check App Version

| Field | Detail |
|---|---|
| **1. API Name** | Check App Version |
| **2. Purpose** | Backend-driven version gate — tells the client whether the current build is blocked (maintenance mode), force-update-required, optionally-update-available, or up to date. |
| **3. Endpoint** | `/app/version` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Not required. This endpoint is in `DioClient`'s `_publicPaths` allow-list, so no `Authorization` header is sent and a `401` response is treated as a normal credential/validation failure, not a session expiry. Called from the Splash screen before any session necessarily exists. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None (see Notes for how the client's own build number is used). |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only, no input).

**11. Success Response**

`200` — `status: true`, `data.maintenance` (bool), `data.minimum_build` (int), `data.latest_build` (int), `data.store_url`, `data.message`.

**12. Error Responses**

Any non-200/`status:false` is treated as "could not check version" and the client fails open (does not block the user).

**13. Sample Request**

```
GET /app/version
```

**14. Sample Success Response**

```json
{
  "status": true,
  "message": "OK",
  "data": {
    "maintenance": false,
    "minimum_build": 120,
    "latest_build": 125,
    "store_url": "https://play.google.com/store/apps/details?id=com.example.app",
    "message": "Please update the application."
  }
}
```

**15. Sample Error Response**

```json
{
  "status": false,
  "message": "Could not check app version"
}
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- `maintenance: true` → app shows a blocking maintenance screen; `minimum_build`/`latest_build`/`store_url` are irrelevant in this state.
- `maintenance: false` and client build `< minimum_build` → force update (blocking).
- `maintenance: false`, client build `>= minimum_build` and `< latest_build` → optional update (dismissible).
- `maintenance: false`, client build `>= latest_build` → up to date, no prompt.

**18. Notes**

The client compares the response against its own compiled build number (`AppBuildInfo`) locally — the backend does not need to know the caller's build number in the request; it always returns the same current gate values, and the client does the comparison.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_010 — Fetch Profile

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Profile |
| **2. Purpose** | Returns the signed-in user's own profile, current account/branch context, plan, management counters, and feature locks — the same payload shape as Login's `data`, minus the auth-issuing fields. |
| **3. Endpoint** | `/user/profile` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true`, `data.user_info`, `data.account`, `data.recent_plan`, `data.management`, `data.feature_lock` — identical shape to Login's `data` minus `token`/`refresh_token`/`expires_in`.

**12. Error Responses**

`401` — expired/invalid token (triggers refresh flow before surfacing to the user).

**13. Sample Request**

```
GET /user/profile
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{
  "status": true,
  "message": "Profile fetched successfully",
  "data": {
    "user_info": { "id": 101, "user_name": "Krushna Satbhai", "email": "krusna.satbhai@gmail.com", "mobile": "8793052520", "role": "account_admin", "profile_image": null, "status": "active" },
    "account": { "name": "Jargon Pvt Ltd", "code": "JAR-1234", "branch_name": "Pune" },
    "recent_plan": { "name": "Pro", "valid_until": "2026-08-01", "status": "active", "date_format": "dd MMM yyyy" },
    "management": { "total_firms": 22, "total_staff": 220, "total_services": 224, "total_expenses": 12, "total_salary_rules": 5 },
    "feature_lock": []
  }
}
```

**15. Sample Error Response**

```json
{
  "status": false,
  "message": "We couldn't load your profile right now."
}
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Response contract is intentionally identical to Login's `data` object (minus auth fields) so the client can reuse the same parsing model (`user_info`/`account`/`recent_plan`/`management`/`feature_lock`) for both.

**18. Notes**

Distinct from Account Info (API_011) — Profile is the logged-in user's session/role context; Account Info is the editable business/registration record.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_011 — Fetch Account Info

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Account Info |
| **2. Purpose** | Returns the full registration/business record for the signed-in account (contact details, GSTIN, owner/ID-proof info, login email). |
| **3. Endpoint** | `/account/info` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true`, `data` with `account_code`, `account_name`, `account_email`, `phone`, `address`, `city`, `state`, `zip`, `gstin`, `account_photo_url`, `owner_name`, `designation`, `id_proof_type`, `id_proof_number`, `id_proof_document_url`, `login_email`.

**12. Error Responses**

`401` — expired/invalid token.

**13. Sample Request**

```
GET /account/info
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{
  "status": true,
  "message": "Account info fetched successfully",
  "data": {
    "account_code": "ACC-100234",
    "account_name": "Glow & Co Salon",
    "account_email": "accounts@glowandco.example",
    "phone": "9876500000",
    "address": "221B, Residency Road",
    "city": "Bengaluru",
    "state": "Karnataka",
    "zip": "560025",
    "gstin": "29ABCDE1234F1Z5",
    "account_photo_url": "https://.../photo.jpg",
    "owner_name": "Ananya Rao",
    "designation": "Founder",
    "id_proof_type": "PAN Card",
    "id_proof_number": "ABCDE1234F",
    "id_proof_document_url": "https://.../id.jpg",
    "login_email": "ananya.rao@glowandco.example"
  }
}
```

**15. Sample Error Response**

```json
{
  "status": false,
  "message": "We couldn't load your account info right now."
}
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- This is a single record per account (created at Registration, API_004) — there is no create/delete for it, only fetch (this) and update (API_012).

**18. Notes**

`account_code`, `account_email`, `id_proof_type`, `id_proof_number`, `id_proof_document_url`, `login_email` are returned but are **read-only** — see API_012 for exactly which subset of these fields can be changed by the user.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_012 — Update Account Info

| Field | Detail |
|---|---|
| **1. API Name** | Update Account Info |
| **2. Purpose** | Updates the small subset of Account Info fields the user is allowed to edit, optionally replacing or removing the account photo/logo. |
| **3. Endpoint** | `/account/info` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` when no photo is attached and `remove_account_photo` is false; `Content-Type: multipart/form-data` when a photo is attached or being removed (non-string fields are JSON-encoded per multipart part). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

| Field | Type | Required | Editable? |
|---|---|---|---|
| `phone` | string | conditionally | Yes |
| `address` | string | conditionally | Yes |
| `pincode` (ZIP) | string | conditionally | Yes (city/state auto-derived from it) |
| `full_name` | string | conditionally | Yes |
| `designation` | string | conditionally | Yes |
| `gstin` | string | conditionally | Yes |
| `account_photo` | file | No | Yes (upload) |
| `remove_account_photo` | "true"/omitted | No | N/A — flag to clear the photo without uploading a new one |
| `platform` | string | Yes (auto-attached) | N/A |

Every other Account Info field (account code, login email, owner name, ID proof type/number/document) is **read-only** and must never be included in this payload.

**10. Validation Rules**

- Only the editable fields listed above may be sent; the client never includes read-only fields in the payload.
- `account_photo` and `remove_account_photo` are mutually exclusive in intent (uploading a new photo supersedes removal).
- `platform` is resolved automatically, not user-entered.

**11. Success Response**

`200` — `status: true`, `data.saved` (bool, defaults to `true` if the field is absent).

**12. Error Responses**

`400`/`422` — invalid field value (e.g. malformed pincode/GSTIN).

**13. Sample Request**

```
POST /account/info
Content-Type: multipart/form-data; boundary=...

phone=9876500000
address=221B, Residency Road
pincode=560025
full_name=Ananya Rao
designation=Founder
gstin=29ABCDE1234F1Z5
platform=android
account_photo=<binary>
```

**14. Sample Success Response**

```json
{
  "status": true,
  "message": "Account info updated successfully",
  "data": { "saved": true }
}
```

**15. Sample Error Response**

```json
{
  "status": false,
  "message": "Failed to update account info"
}
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- City/State are never sent directly by the client — they travel along with (are derived from) `pincode` server-side.

**18. Notes**

Uses `POST` for an update (not `PUT`) — consistent with every other mutation endpoint in this app, since `DioClient` does not expose `PATCH`.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_013 — Delete Account

| Field | Detail |
|---|---|
| **1. API Name** | Delete Account |
| **2. Purpose** | Permanently deletes the signed-in user's account. |
| **3. Endpoint** | `/user/delete-account` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

None documented — client sends no body.

**10. Validation Rules**

None beyond a valid Authorization header. (Recommend backend require a confirmation step, e.g. password re-entry, not currently modeled in the client request.)

**11. Success Response**

`200` — `status: true`, `data.message`.

**12. Error Responses**

`4xx` — `status: false`, `message: "<reason>"`.

**13. Sample Request**

```
POST /user/delete-account
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{
  "status": true,
  "message": "Account deleted successfully",
  "data": { "message": "Account deleted successfully" }
}
```

**15. Sample Error Response**

```json
{
  "status": false,
  "message": "<reason>"
}
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Irreversible — the client immediately clears the local session on success and returns to Login.

**18. Notes**

**Backend status: not yet implemented at time of writing.** Written against the same contract shape as Logout (API_003); resolves from local mock JSON in mock mode until the real endpoint ships.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_014 — Get Referral Invite Link

| Field | Detail |
|---|---|
| **1. API Name** | Get Referral Invite Link |
| **2. Purpose** | Generates/returns the current account's referral invite link for sharing. |
| **3. Endpoint** | `/referrals/invite-link` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true`, `data.invite_url`.

**12. Error Responses**

`401` — invalid/expired token.

**13. Sample Request**

```
GET /referrals/invite-link
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{
  "status": true,
  "message": "OK",
  "data": { "invite_url": "https://app.tbh.com/i/X7Kd92PmLq" }
}
```

**15. Sample Error Response**

```json
{
  "status": false,
  "message": "Could not generate invite link"
}
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- The client never generates or guesses this URL itself — it is entirely backend-owned and opaque.

**18. Notes**

Consumed on the Registration side by `invite_token` handling in API_004 — the two are the entry/exit points of the same referral loop.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

# Module: Dashboard

## API_015 — Fetch Admin Dashboard

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Admin Dashboard |
| **2. Purpose** | Returns the full Admin Dashboard payload (summary metrics, breakdowns) for the signed-in account. |
| **3. Endpoint** | `/dashboard` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None currently sent by the client (dashboard is account-scoped via the auth token). |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true` with the full `DashboardResponse` payload (see `dashboard_models.dart` for the nested schema — revenue/expense summaries, top performers, etc.).

**12. Error Responses**

Any non-200 or `status:false` — client shows a generic "failed to load" state.

**13. Sample Request**

```
GET /dashboard
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { /* dashboard summary payload — see dashboard_admin_response.json fixture */ } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "<reason>" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Scoped implicitly to the caller's account/branch via the auth token — no explicit org/branch parameter is sent.

**18. Notes**

**Implementation inconsistency to flag:** this method uses a hand-rolled `try/catch` + manual `Env.isMock` branch rather than the shared `callApi` helper every newer endpoint in this app uses — behavior is equivalent, but it's the older pattern (see API_016's sibling method in the same file, which shares this style).

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_016 — Fetch Revenue Trend

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Revenue Trend |
| **2. Purpose** | Returns a cursor-paginated revenue trend series (for the dashboard's trend chart), one page at a time in either direction. |
| **3. Endpoint** | `/dashboard/revenue-trend` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | | Param | Type | Required | Notes |
|---|---|---|---|
| `period` | string | Yes | Lower-cased before sending, e.g. `monthly`, `weekly`. |
| `cursor` | string | No | Pagination cursor from a previous page's `nextCursor`/`prevCursor`. | |

**9. Request Body**

None.

**10. Validation Rules**

- `period` required.
- `cursor` optional — omitted entirely from the query string when null (not sent as an empty value).

**11. Success Response**

`200` — `status: true`, `data.overviewTrend` containing `period`, `limit`, `hasMoreData`, `range`, `points[]` (`key`, `label`, `value`), `prevCursor`, `nextCursor`.

**12. Error Responses**

Non-200 or `status:false` → client surfaces "Failed to load revenue trend".

**13. Sample Request**

```
GET /dashboard/revenue-trend?period=monthly&cursor=2025-08
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{
  "status": true,
  "data": {
    "overviewTrend": {
      "period": "Monthly",
      "limit": 6,
      "hasMoreData": true,
      "range": "Apr 2024 – Mar 2025",
      "points": [
        { "key": "2025-08", "label": "Aug'25", "value": 2000 },
        { "key": "2025-09", "label": "Sep'25", "value": 3000 }
      ],
      "prevCursor": "2024-03",
      "nextCursor": null
    }
  }
}
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to load revenue trend" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- `nextCursor`/`prevCursor` being `null` signals the respective end of the series to the client.

**18. Notes**

Same older hand-rolled try/catch pattern as API_015 (not the shared `callApi` helper).

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_017 — Fetch Dashboard Header

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Dashboard Header |
| **2. Purpose** | Returns the data the sticky Dashboard header needs — org identity, notification count, and a role-appropriate switchable-scope list (Organizations for Super Admin, Branches for Account Admin, a single assigned Branch for Branch Admin/Manager/Employee). |
| **3. Endpoint** | `/dashboard/header` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None — role is inferred server-side from the auth token. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true`, `data` shaped per the caller's role (see Notes).

**12. Error Responses**

Non-200/`status:false` → "We couldn't load your dashboard header right now."

**13. Sample Request**

```
GET /dashboard/header
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { /* fields vary by role — see dashboard_header_*_response.json fixtures per role */ } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load your dashboard header right now." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Single endpoint for all five roles (Super Admin, Account Admin, Branch Admin, Manager, Employee) — the backend must return only the fields relevant to the caller's role, inferred from the auth token, rather than requiring five separate endpoints.

**18. Notes**

Client-side, the mock fixture varies by role for local testing (`dashboard_header_super_admin_response.json`, `..._account_admin_...`, `..._branch_admin_...`, `..._manager_...`, `..._employee_...`); the live endpoint is a single fixed path regardless of role.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

# Module: Firms

## API_018 — Create Firm

| Field | Detail |
|---|---|
| **1. API Name** | Create Firm |
| **2. Purpose** | Creates a new Firm under the account, with logo and photo uploads. |
| **3. Endpoint** | `/create-firm` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: multipart/form-data` (set automatically by Dio when the request body is a `FormData` instance, i.e. whenever a file is attached). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

| Field | Type | Required |
|---|---|---|
| `firm_name` | string | Yes |
| `address` | string | Yes |
| `gstin` | string | Yes |
| `registration_number` | string | Yes |
| `owner_name` | string | Yes |
| `contact` | string | Yes |
| `email` | string | Yes |
| `company_type` | string | Yes |
| `firm_logo` | file | Yes |
| `firm_photo` | file | Yes |

**10. Validation Rules**

- Every field listed is required by the client — both `firm_logo` and `firm_photo` are mandatory file uploads (unlike Branch/Service/Staff logos/photos elsewhere in the app, which are optional).

**11. Success Response**

`200` — `status: true` (boolean success signal; no structured `data` payload beyond the envelope).

**12. Error Responses**

Non-200 or `status:false` → `message` surfaced as-is to the user.

**13. Sample Request**

```
POST /create-firm
Content-Type: multipart/form-data; boundary=...

firm_name=Beauty Hub Downtown
address=123 Main St
gstin=27ABCDE1234F1Z5
registration_number=REG123456
owner_name=Jane Doe
contact=+91 9876543210
email=firm@email.com
company_type=Partnership
firm_logo=<binary>
firm_photo=<binary>
```

**14. Sample Success Response**

```json
{ "status": true, "message": "Firm created successfully" }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "<reason>" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- A Firm is a top-level entity distinct from a Branch (API_021–024) — Firm-level dashboards (API_019/020) aggregate revenue/transactions/staff/services across the firm.

**18. Notes**

**Implementation inconsistency to flag:** this method still uses a hand-rolled `try/catch` and is **not** routed through the shared `callApi` helper — i.e. it never goes through the mock branch other endpoints use, meaning in mock mode this call attempts a real network request. This is the same class of gap that was fixed for `BranchesApi.createBranch`/`updateBranch` (see API_023/024's Notes) but not yet applied here.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_019 — Fetch Firms

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Firms |
| **2. Purpose** | Returns the list of Firms under the account with summary metrics (revenue, transaction count, percent change) plus report metadata (currency, available periods, counts). |
| **3. Endpoint** | `/firms` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None currently sent. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true`, `data.meta` (`currency`, `periods[]`, `counts.totalFirms`), `data.firms[]` (`id`, `name`, `description`, `revenue`, `transactions`, `percent`).

**12. Error Responses**

Non-200/`status:false` → client surfaces "Failed to load firms".

**13. Sample Request**

```
GET /firms
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{
  "status": true,
  "data": {
    "meta": { "currency": "INR", "periods": ["Daily", "Weekly", "Monthly", "Yearly"], "counts": { "totalFirms": 4 } },
    "firms": [
      { "id": 1, "name": "Beauty Hub Downtown", "description": "BH-Downtown", "revenue": 2850, "transactions": 23, "percent": 12.5 }
    ]
  }
}
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to load firms" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- `percent` can be negative (period-over-period decline) — client renders it as-is, no clamping.

**18. Notes**

Same hand-rolled try/catch pattern as API_018/020 (not the shared `callApi` helper) — flagged as a candidate for future refactor to match the newer API classes' pattern.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_020 — Fetch Firm Detail

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Firm Detail |
| **2. Purpose** | Returns a single Firm's full detail: firm info, a revenue trend series, and its Staff and Services breakdowns. |
| **3. Endpoint** | `/firms/{firmId}/details` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `firmId` (integer, path) — the Firm's id, from API_019's list. |
| **8. Query Parameters** | None currently sent. |

**9. Request Body**

None.

**10. Validation Rules**

- `firmId` must reference an existing Firm belonging to the caller's account.

**11. Success Response**

`200` — `status: true`, `data.meta.firmInfo` (id, name, description, revenue, transactions, percent, gstin, regNo, email, contact), `data.overviewTrend` (period, limit, hasMoreData, range, points[], prevCursor, nextCursor), `data.firms[]` (sibling firms for comparison), `data.staff[]`, `data.services[]`.

**12. Error Responses**

`404` — firm id not found / not owned by the caller's account.

**13. Sample Request**

```
GET /firms/1/details
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{
  "status": true,
  "data": {
    "meta": {
      "currency": "INR",
      "periods": ["Daily", "Weekly", "Monthly", "Yearly"],
      "firmInfo": { "id": 1, "name": "Beauty Hub Downtown", "revenue": 2850, "transactions": 23, "percent": 12.5, "gstin": "27ABCDE1234F1Z5", "regNo": "REG123456", "email": "firm@email.com", "contact": "+91 9876543210" }
    },
    "overviewTrend": { "period": "Monthly", "points": [ { "key": "2025-08", "label": "Aug'25", "value": 2000 } ] },
    "firms": [ { "id": 2, "name": "Beauty Hub Uptown", "revenue": 3200, "transactions": 28, "percent": 8.3 } ],
    "staff": [ { "id": 101, "name": "Krushna Satbhai", "firmId": 3, "firmName": "Beauty Hub Westside", "revenue": 2850, "transactions": 23, "percent": 12.5 } ],
    "services": [ { "id": 101, "name": "Hair Cut", "firmId": 3, "firmName": "Beauty Hub Westside", "revenue": 2850, "transactions": 23, "percent": 12.5 } ]
  }
}
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to load firm details" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- `data.firms[]` here appears to be a broader/sibling-firm comparison list rather than a subset of this one firm — backend should confirm the intended scope of this array within the detail response.

**18. Notes**

Same hand-rolled try/catch pattern as API_018/019.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

# Module: Branches

## API_021 — Fetch Branches

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Branches |
| **2. Purpose** | Returns the list of Branches under the account for the Branches list screen. |
| **3. Endpoint** | `/branches` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true`, `data.branches[]` (`id`, `name`, `address`, `city`, `state`, `mobile`, `branch_type`, `status`, `logo`).

**12. Error Responses**

"We couldn't load branches right now." on failure.

**13. Sample Request**

```
GET /branches
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{
  "status": true,
  "message": "Branches fetched successfully",
  "data": {
    "branches": [
      { "id": 1, "name": "MG Road Branch", "address": "2nd Floor, Prestige Arcade, MG Road", "city": "Bengaluru", "state": "Karnataka", "mobile": "9876543210", "branch_type": "Unisex", "status": "Active", "logo": "https://i.pravatar.cc/150?img=12" }
    ]
  }
}
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load branches right now." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- `branch_type` is one of a fixed set (`Unisex`/`Male`/`Female` observed in fixtures) — backend should confirm the authoritative enum.
- `status` (`Active`/`Inactive`) drives list-screen filtering/display client-side.

**18. Notes**

Uses the shared `callApi` helper (current preferred pattern).

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_022 — Fetch Branch Detail

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Branch Detail |
| **2. Purpose** | Returns full detail for a single Branch, including geolocation, hours, assigned services, and assigned employees. |
| **3. Endpoint** | `/branches/{branchId}/details` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `branchId` (integer, path). |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

- `branchId` must reference an existing Branch owned by the caller's account.

**11. Success Response**

`200` — `status: true`, `data` with `id`, `name`, `address_line1`, `address_line2`, `city`, `state`, `pincode`, `latitude`, `longitude`, `maps_link`, `mobile`, `email`, `branch_type`, `opening_time`, `closing_time`, `weekly_off`, `status`, `logo`, `services[]` (`id`, `name`), `employees[]` (`id`, `name`, `role`, `photo`).

**12. Error Responses**

`404` — branch id not found / not owned by caller.

**13. Sample Request**

```
GET /branches/1/details
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{
  "status": true,
  "message": "Branch details fetched successfully",
  "data": {
    "id": 1, "name": "MG Road Branch",
    "address_line1": "2nd Floor, Prestige Arcade", "address_line2": "MG Road",
    "city": "Bengaluru", "state": "Karnataka", "pincode": "560001",
    "latitude": 12.9752, "longitude": 77.6065,
    "maps_link": "https://maps.app.goo.gl/vzCg9kRVS2EEeQ2x7",
    "mobile": "9876543210", "email": "mgroad.branch@example.com",
    "branch_type": "Unisex", "opening_time": "09:00", "closing_time": "21:00",
    "weekly_off": "Monday", "status": "Active", "logo": "https://i.pravatar.cc/150?img=12",
    "services": [ { "id": 1, "name": "Haircut" } ],
    "employees": [ { "id": 101, "name": "Ritu Sharma", "role": "Branch Manager", "photo": null } ]
  }
}
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load this branch's details." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- `weekly_off` is a single day name — backend should confirm whether multiple weekly-off days are ever supported (client currently models one).

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_023 — Create Branch

| Field | Detail |
|---|---|
| **1. API Name** | Create Branch |
| **2. Purpose** | Creates a new Branch, with an optional logo upload. |
| **3. Endpoint** | `/branches` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `multipart/form-data` when `logo` is attached, otherwise plain JSON. |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

Branch fields (name, address, city, state, pincode, mobile, email, branch_type, opening_time, closing_time, weekly_off, service ids, etc. — exact set defined by the Branch form, not fully enumerated in the API layer itself) plus:

| Field | Type | Required |
|---|---|---|
| `logo` | file | No |

**10. Validation Rules**

- Payload validation is owned by the Branch form (client-side); server should independently validate required Branch fields (name, address, city, state, mobile at minimum, per the detail shape in API_022).

**11. Success Response**

`200` — `status: true`, `data.saved` (bool).

**12. Error Responses**

"Failed to create branch" on failure.

**13. Sample Request**

```
POST /branches
Content-Type: multipart/form-data; boundary=...

name=MG Road Branch
address=2nd Floor, Prestige Arcade, MG Road
city=Bengaluru
state=Karnataka
mobile=9876543210
branch_type=Unisex
logo=<binary>
```

**14. Sample Success Response**

```json
{ "status": true, "message": "Branch saved successfully", "data": { "saved": true } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to create branch" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Create and Update (API_024) share the same mock/live response fixture (`branch_save_response.json`) and the same `saved: true` contract.

**18. Notes**

**Bug-fix context (leave as-is, informational):** this method previously bypassed the shared `callApi` helper by calling the HTTP client directly in its own try/catch, which meant it never went through the mock branch in mock/dev builds and instead attempted a real network call — this was the confirmed root cause of a previously reported Create/Update Branch failure. It has since been routed through `callApi` like every other endpoint; no further action needed here, noted for backend/QA context only.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_024 — Update Branch

| Field | Detail |
|---|---|
| **1. API Name** | Update Branch |
| **2. Purpose** | Updates an existing Branch, optionally replacing or removing its logo. |
| **3. Endpoint** | `/branches/{branchId}` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `multipart/form-data` when `logo` is attached or being removed, otherwise plain JSON. |
| **7. Path Parameters** | `branchId` (integer, path). |
| **8. Query Parameters** | None. |

**9. Request Body**

Same editable Branch fields as Create (API_023), plus:

| Field | Type | Required |
|---|---|---|
| `logo` | file | No |
| `remove_logo` | "true"/omitted | No |

**10. Validation Rules**

Same as Create (API_023).

**11. Success Response**

`200` — `status: true`, `data.saved` (bool).

**12. Error Responses**

"Failed to update branch" on failure.

**13. Sample Request**

```
POST /branches/1
Content-Type: multipart/form-data; boundary=...

name=MG Road Branch
remove_logo=true
```

**14. Sample Success Response**

```json
{ "status": true, "message": "Branch saved successfully", "data": { "saved": true } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to update branch" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- `remove_logo=true` clears the existing logo without requiring a new file.

**18. Notes**

`PUT` was considered but not used — `DioClient` only exposes `GET`/`POST` for the branch/logo-upload pattern's original implementation, so update is modeled as `POST` to the resource path, matching every other mutation endpoint in the app except Transactions (API_051), which is the one place `PUT` was later introduced.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

# Module: Services

## API_025 — Fetch Services Catalog

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Services Catalog |
| **2. Purpose** | Returns the lightweight master Service catalog used by the Branch Create/Edit form's service picker. |
| **3. Endpoint** | `/services` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true`, `data.services[]` (`id`, `name`, `active`).

**12. Error Responses**

"We couldn't load services right now." on failure.

**13. Sample Request**

```
GET /services
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{
  "status": true,
  "message": "Services fetched successfully",
  "data": { "services": [ { "id": 1, "name": "Haircut", "active": true } ] }
}
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load services right now." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Deliberately kept as a separate, lightweight shape from Service List (API_026) — Service Management changes must never affect the Branch picker's contract.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_026 — Fetch Service List

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Service List |
| **2. Purpose** | Returns the full Service List screen's data — richer than the catalog (category, pricing, status, photo). |
| **3. Endpoint** | `/services/list` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true`, `data.services[]` with category, pricing, status, photo fields (see `service_list_response.json` fixture / `ServiceListItem` model).

**12. Error Responses**

"We couldn't load services right now." on failure.

**13. Sample Request**

```
GET /services/list
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "services": [ { "id": 1, "name": "Haircut", "category": "Hair", "price": 300, "status": "Active" } ] } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load services right now." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Independent contract from API_025 by design (see API_025's Notes).

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_027 — Fetch Service Detail

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Service Detail |
| **2. Purpose** | Returns full detail for a single Service. |
| **3. Endpoint** | `/services/{serviceId}/details` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `serviceId` (integer, path). |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

- `serviceId` must reference an existing Service owned by the caller's account.

**11. Success Response**

`200` — `status: true`, `data` with full Service fields (see `ServiceDetailResponse` model).

**12. Error Responses**

"We couldn't load this service's details." on failure.

**13. Sample Request**

```
GET /services/1/details
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "id": 1, "name": "Haircut", "category": "Hair", "price": 300, "description": "...", "status": "Active", "photo": null, "branch_ids": [1,2] } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load this service's details." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- N/A beyond ownership scoping.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_028 — Create Service

| Field | Detail |
|---|---|
| **1. API Name** | Create Service |
| **2. Purpose** | Creates a new Service, with an optional photo upload. |
| **3. Endpoint** | `/services` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `multipart/form-data` when `photo` is attached, otherwise plain JSON. |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

Service fields (name, category, price, description, branch assignment, etc. — owned by the Service form) plus:

| Field | Type | Required |
|---|---|---|
| `photo` | file | No |

**10. Validation Rules**

- Non-string payload values are JSON-encoded per multipart part when a photo is present (numbers, lists, nulls), since Dio's multipart encoder only accepts `String`/`MultipartFile`.

**11. Success Response**

`200` — `status: true`, `data.saved` (bool).

**12. Error Responses**

"Failed to create service" on failure.

**13. Sample Request**

```
POST /services
Content-Type: multipart/form-data; boundary=...

name=Haircut
category=Hair
price=300
photo=<binary>
```

**14. Sample Success Response**

```json
{ "status": true, "message": "Service saved successfully", "data": { "saved": true } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to create service" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Shares its response fixture/contract with Update (API_029).

**18. Notes**

Uses the shared `callApi` helper (mirrors `BranchesApi`'s `_buildRequestBody` pattern).

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_029 — Update Service

| Field | Detail |
|---|---|
| **1. API Name** | Update Service |
| **2. Purpose** | Updates an existing Service, optionally replacing or removing its photo. |
| **3. Endpoint** | `/services/{serviceId}` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `multipart/form-data` when `photo` is attached or being removed, otherwise plain JSON. |
| **7. Path Parameters** | `serviceId` (integer, path). |
| **8. Query Parameters** | None. |

**9. Request Body**

Same editable Service fields as Create (API_028), plus:

| Field | Type | Required |
|---|---|---|
| `photo` | file | No |
| `remove_photo` | "true"/omitted | No |

**10. Validation Rules**

Same as Create (API_028).

**11. Success Response**

`200` — `status: true`, `data.saved` (bool).

**12. Error Responses**

"Failed to update service" on failure.

**13. Sample Request**

```
POST /services/1
Content-Type: application/json

{ "name": "Haircut", "price": 350 }
```

**14. Sample Success Response**

```json
{ "status": true, "message": "Service saved successfully", "data": { "saved": true } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to update service" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- `remove_photo=true` clears the photo without a new upload.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_030 — Delete Service

| Field | Detail |
|---|---|
| **1. API Name** | Delete Service |
| **2. Purpose** | Deletes an existing Service. |
| **3. Endpoint** | `/services/{serviceId}/delete` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `serviceId` (integer, path). |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

- `serviceId` must reference an existing Service owned by the caller's account. Backend should confirm/enforce referential-integrity rules (e.g. a Service in use by existing Transactions/Branches) — not modeled client-side.

**11. Success Response**

`200` — `status: true`, `data.deleted` (bool, defaults `true`).

**12. Error Responses**

"Failed to delete service" on failure.

**13. Sample Request**

```
POST /services/1/delete
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "message": "Service deleted", "data": { "deleted": true } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to delete service" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |
| 409 | Recommended if the backend blocks deletion of a Service still referenced elsewhere (not currently modeled client-side). |

**17. Business Rules**

- Modeled as `POST .../delete` rather than an HTTP `DELETE`, consistent with every other delete in this app except the Notifications module (API_071/072), which does use `DELETE`.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

# Module: Staff

## API_031 — Fetch Staff Form Config

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Staff Form Config |
| **2. Purpose** | Returns Branch list + Salary Rule list + Specialist list in a single call, so the Staff Add/Edit form's three dropdowns load in one round trip instead of three. |
| **3. Endpoint** | `/staff/form-config` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true`, `data` with branch list, salary-rule list, and specialist list (see `StaffFormConfig` model).

**12. Error Responses**

"We couldn't load form options right now." on failure.

**13. Sample Request**

```
GET /staff/form-config
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "branches": [ { "id": 1, "name": "MG Road Branch" } ], "salary_rules": [ { "id": 1, "name": "Standard" } ], "specialists": [ "Haircut", "Facial" ] } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load form options right now." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Exists specifically to avoid three separate lookups on form open — backend should keep this as one combined response rather than splitting it back into per-entity calls.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_032 — Fetch Staff List

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Staff List |
| **2. Purpose** | Returns the full Staff List screen's data. |
| **3. Endpoint** | `/staff/list` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true`, `data.staff[]` (see `StaffListItem` model).

**12. Error Responses**

"We couldn't load staff right now." on failure.

**13. Sample Request**

```
GET /staff/list
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "staff": [ { "id": 101, "name": "Ritu Sharma", "role": "Branch Manager", "branch_name": "MG Road Branch", "status": "Active" } ] } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load staff right now." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

N/A.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_033 — Fetch Staff Detail

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Staff Detail |
| **2. Purpose** | Returns full detail for a single Staff member. |
| **3. Endpoint** | `/staff/{staffId}/details` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `staffId` (integer, path). |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

- `staffId` must reference an existing Staff member owned by the caller's account.

**11. Success Response**

`200` — `status: true`, `data` with full Staff fields (see `StaffDetailResponse` model — likely includes employee code, salary rule, branch, Aadhaar, photo).

**12. Error Responses**

"We couldn't load this staff member's details." on failure.

**13. Sample Request**

```
GET /staff/101/details
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "id": 101, "name": "Ritu Sharma", "employee_code": "EMP-0101", "role": "Branch Manager", "branch_id": 1, "salary_rule_id": 1, "photo": null, "aadhaar_card": null } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load this staff member's details." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

N/A beyond ownership scoping.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_034 — Fetch Next Employee Code

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Next Employee Code |
| **2. Purpose** | Returns a backend-suggested next Employee Code for a brand-new Staff member, if the backend supports auto-generation. |
| **3. Endpoint** | `/staff/next-employee-code` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true`, `data.employee_code` (string).

**12. Error Responses**

Treated as "not supported" — see Business Rules; no user-facing error is shown for a failure here.

**13. Sample Request**

```
GET /staff/next-employee-code
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "employee_code": "EMP-0102" } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- If this call fails or returns empty, the Add Staff form simply leaves Employee Code blank and manually editable — it never blocks the form on this call. Backend is free to not implement true auto-generation; an empty/absent `employee_code` is a fully valid response.

**18. Notes**

Uses the shared `callApi` helper with an intentionally empty `fallbackErrorMessage` (silent failure by design).

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_035 — Create Staff

| Field | Detail |
|---|---|
| **1. API Name** | Create Staff |
| **2. Purpose** | Creates a new Staff member, with optional profile photo and Aadhaar card uploads. |
| **3. Endpoint** | `/staff` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `multipart/form-data` when `photo` and/or `aadhaarCard` are attached, otherwise plain JSON. |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

Staff fields (name, employee code, role, branch, salary rule, contact, etc. — owned by the Staff form) plus:

| Field | Type | Required |
|---|---|---|
| `photo` | file | No |
| `aadhaar_card` | file | No |

**10. Validation Rules**

- Non-string payload values are JSON-encoded per multipart part when at least one file is present.

**11. Success Response**

`200` — `status: true`, `data.saved` (bool).

**12. Error Responses**

"Failed to add staff member" on failure.

**13. Sample Request**

```
POST /staff
Content-Type: multipart/form-data; boundary=...

name=Ritu Sharma
employee_code=EMP-0101
branch_id=1
salary_rule_id=1
photo=<binary>
aadhaar_card=<binary>
```

**14. Sample Success Response**

```json
{ "status": true, "message": "Staff saved successfully", "data": { "saved": true } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to add staff member" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Shares its response fixture/contract with Update (API_036).

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_036 — Update Staff

| Field | Detail |
|---|---|
| **1. API Name** | Update Staff |
| **2. Purpose** | Updates an existing Staff member, optionally replacing or removing photo and/or Aadhaar card. |
| **3. Endpoint** | `/staff/{staffId}` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `multipart/form-data` when a file is attached or being removed, otherwise plain JSON. |
| **7. Path Parameters** | `staffId` (integer, path). |
| **8. Query Parameters** | None. |

**9. Request Body**

Same editable Staff fields as Create (API_035), plus:

| Field | Type | Required |
|---|---|---|
| `photo` | file | No |
| `aadhaar_card` | file | No |
| `remove_photo` | "true"/omitted | No |
| `remove_aadhaar_card` | "true"/omitted | No |

**10. Validation Rules**

Same as Create (API_035).

**11. Success Response**

`200` — `status: true`, `data.saved` (bool).

**12. Error Responses**

"Failed to update staff member" on failure.

**13. Sample Request**

```
POST /staff/101
Content-Type: application/json

{ "name": "Ritu Sharma", "branch_id": 2 }
```

**14. Sample Success Response**

```json
{ "status": true, "message": "Staff saved successfully", "data": { "saved": true } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to update staff member" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- `remove_photo`/`remove_aadhaar_card` each independently clear that file without requiring a new upload.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_037 — Delete Staff

| Field | Detail |
|---|---|
| **1. API Name** | Delete Staff |
| **2. Purpose** | Deletes an existing Staff member. |
| **3. Endpoint** | `/staff/{staffId}/delete` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `staffId` (integer, path). |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

- `staffId` must reference an existing Staff member owned by the caller's account.

**11. Success Response**

`200` — `status: true`, `data.deleted` (bool, defaults `true`).

**12. Error Responses**

"Failed to delete staff member" on failure.

**13. Sample Request**

```
POST /staff/101/delete
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "message": "Staff deleted", "data": { "deleted": true } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to delete staff member" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |
| 409 | Recommended if the backend blocks deletion of a Staff member with existing Transactions (not currently modeled client-side). |

**17. Business Rules**

N/A beyond referential-integrity considerations noted above.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

# Module: Salary Rules

## API_038 — Fetch Salary Rules Catalog

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Salary Rules Catalog |
| **2. Purpose** | Returns the lightweight Salary Rule list used by the Staff form's Salary Rule picker. |
| **3. Endpoint** | `/salary-rules` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true`, `data.salary_rules[]` (lightweight `SalaryRuleModel` shape — id, name).

**12. Error Responses**

"We couldn't load salary rules right now." on failure.

**13. Sample Request**

```
GET /salary-rules
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "salary_rules": [ { "id": 1, "name": "Standard Commission" } ] } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load salary rules right now." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Kept as a separate, lightweight contract from Salary Rule List (API_039) — same separation-of-concerns pattern as Services (API_025 vs API_026).

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_039 — Fetch Salary Rule List

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Salary Rule List |
| **2. Purpose** | Returns the full Salary Rule Management list screen's data. |
| **3. Endpoint** | `/salary-rules/list` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true`, `data.salary_rules[]` (richer `SalaryRuleListItem` shape).

**12. Error Responses**

"We couldn't load salary rules right now." on failure.

**13. Sample Request**

```
GET /salary-rules/list
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "salary_rules": [ { "id": 1, "name": "Standard Commission", "type": "Percentage", "value": 10, "status": "Active" } ] } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load salary rules right now." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

N/A.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_040 — Fetch Salary Rule Detail

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Salary Rule Detail |
| **2. Purpose** | Returns full detail for a single Salary Rule. |
| **3. Endpoint** | `/salary-rules/{ruleId}/details` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `ruleId` (integer, path). |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

- `ruleId` must reference an existing Salary Rule owned by the caller's account.

**11. Success Response**

`200` — `status: true`, `data` with full Salary Rule fields (see `SalaryRuleDetailResponse` model).

**12. Error Responses**

"We couldn't load this salary rule's details." on failure.

**13. Sample Request**

```
GET /salary-rules/1/details
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "id": 1, "name": "Standard Commission", "type": "Percentage", "value": 10, "applies_to": "all_services" } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load this salary rule's details." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

N/A.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_041 — Create Salary Rule

| Field | Detail |
|---|---|
| **1. API Name** | Create Salary Rule |
| **2. Purpose** | Creates a new Salary Rule. |
| **3. Endpoint** | `/salary-rules` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

Salary Rule fields (name, type, value, applicability, etc. — owned by the Salary Rules form; plain JSON, no file upload involved for this module).

**10. Validation Rules**

- Numeric fields (e.g. rate/value) should be non-negative and, where the field represents a required amount, greater than zero — enforced client-side today via `NumericFieldValidators` (see `core/validators/numeric_field_validators.dart`); backend should apply equivalent server-side checks.

**11. Success Response**

`200` — `status: true`, `data.saved` (bool).

**12. Error Responses**

"Failed to create salary rule" on failure.

**13. Sample Request**

```
POST /salary-rules
Content-Type: application/json

{ "name": "Standard Commission", "type": "Percentage", "value": 10 }
```

**14. Sample Success Response**

```json
{ "status": true, "message": "Salary rule saved successfully", "data": { "saved": true } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to create salary rule" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Shares its response fixture/contract with Update (API_042).

**18. Notes**

Unlike Branches/Services/Staff, Salary Rules involves no file upload — this is always a plain JSON `POST`. Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_042 — Update Salary Rule

| Field | Detail |
|---|---|
| **1. API Name** | Update Salary Rule |
| **2. Purpose** | Updates an existing Salary Rule. |
| **3. Endpoint** | `/salary-rules/{ruleId}` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `ruleId` (integer, path). |
| **8. Query Parameters** | None. |

**9. Request Body**

Same editable Salary Rule fields as Create (API_041).

**10. Validation Rules**

Same as Create (API_041).

**11. Success Response**

`200` — `status: true`, `data.saved` (bool).

**12. Error Responses**

"Failed to update salary rule" on failure.

**13. Sample Request**

```
POST /salary-rules/1
Content-Type: application/json

{ "name": "Standard Commission", "value": 12 }
```

**14. Sample Success Response**

```json
{ "status": true, "message": "Salary rule saved successfully", "data": { "saved": true } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to update salary rule" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

N/A.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_043 — Delete Salary Rule

| Field | Detail |
|---|---|
| **1. API Name** | Delete Salary Rule |
| **2. Purpose** | Deletes an existing Salary Rule. |
| **3. Endpoint** | `/salary-rules/{ruleId}/delete` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `ruleId` (integer, path). |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

- `ruleId` must reference an existing Salary Rule owned by the caller's account.

**11. Success Response**

`200` — `status: true`, `data.deleted` (bool, defaults `true`).

**12. Error Responses**

"Failed to delete salary rule" on failure.

**13. Sample Request**

```
POST /salary-rules/1/delete
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "message": "Salary rule deleted", "data": { "deleted": true } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to delete salary rule" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |
| 409 | Recommended if the backend blocks deletion of a Salary Rule still assigned to Staff (not currently modeled client-side). |

**17. Business Rules**

N/A beyond referential-integrity considerations noted above.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

# Module: Expenses

## API_044 — Fetch Expense List

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Expense List |
| **2. Purpose** | Returns the full Expense (Types) Management list screen's data. |
| **3. Endpoint** | `/expenses/list` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true`, `data.expenses[]` (see `ExpenseListItem` model).

**12. Error Responses**

"We couldn't load expenses right now." on failure.

**13. Sample Request**

```
GET /expenses/list
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "expenses": [ { "id": 1, "name": "Rent", "branch_name": "MG Road Branch", "status": "Active" } ] } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load expenses right now." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

N/A.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_045 — Fetch Expense Detail

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Expense Detail |
| **2. Purpose** | Returns full detail for a single Expense type. |
| **3. Endpoint** | `/expenses/{expenseId}/details` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `expenseId` (integer, path). |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

- `expenseId` must reference an existing Expense type owned by the caller's account.

**11. Success Response**

`200` — `status: true`, `data` with full Expense fields (name, description, branch assignment — see `ExpenseDetailResponse` model).

**12. Error Responses**

"We couldn't load this expense's details." on failure.

**13. Sample Request**

```
GET /expenses/1/details
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "id": 1, "name": "Rent", "description": "Monthly branch rent", "branch_ids": [1] } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load this expense's details." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

N/A.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_046 — Create Expense

| Field | Detail |
|---|---|
| **1. API Name** | Create Expense |
| **2. Purpose** | Creates a new Expense type. |
| **3. Endpoint** | `/expenses` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

| Field | Type | Required |
|---|---|---|
| `name` | string | Yes |
| `description` | string | No |
| `branch_ids` | array\<int\> | Yes (branch assignment) |

**10. Validation Rules**

- `name` required.
- No file upload for this module — always a plain JSON payload.

**11. Success Response**

`200` — `status: true`, `data.saved` (bool).

**12. Error Responses**

"Failed to add expense" on failure.

**13. Sample Request**

```
POST /expenses
Content-Type: application/json

{ "name": "Rent", "description": "Monthly branch rent", "branch_ids": [1] }
```

**14. Sample Success Response**

```json
{ "status": true, "message": "Expense saved successfully", "data": { "saved": true } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to add expense" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Shares its response fixture/contract with Update (API_047).

**18. Notes**

Uses the shared `callApi` helper. Configuration-only screen — no photo/document upload involved, unlike Branches/Services/Staff.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_047 — Update Expense

| Field | Detail |
|---|---|
| **1. API Name** | Update Expense |
| **2. Purpose** | Updates an existing Expense type. |
| **3. Endpoint** | `/expenses/{expenseId}` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `expenseId` (integer, path). |
| **8. Query Parameters** | None. |

**9. Request Body**

Same editable Expense fields as Create (API_046).

**10. Validation Rules**

Same as Create (API_046).

**11. Success Response**

`200` — `status: true`, `data.saved` (bool).

**12. Error Responses**

"Failed to update expense" on failure.

**13. Sample Request**

```
POST /expenses/1
Content-Type: application/json

{ "name": "Rent", "branch_ids": [1, 2] }
```

**14. Sample Success Response**

```json
{ "status": true, "message": "Expense saved successfully", "data": { "saved": true } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to update expense" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

N/A.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_048 — Delete Expense

| Field | Detail |
|---|---|
| **1. API Name** | Delete Expense |
| **2. Purpose** | Deletes an existing Expense type. |
| **3. Endpoint** | `/expenses/{expenseId}/delete` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `expenseId` (integer, path). |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

- `expenseId` must reference an existing Expense type owned by the caller's account.

**11. Success Response**

`200` — `status: true`, `data.deleted` (bool, defaults `true`).

**12. Error Responses**

"Failed to delete expense" on failure.

**13. Sample Request**

```
POST /expenses/1/delete
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "message": "Expense deleted", "data": { "deleted": true } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to delete expense" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |
| 409 | Recommended if the backend blocks deletion of an Expense type referenced by existing Transactions (not currently modeled client-side). |

**17. Business Rules**

N/A beyond referential-integrity considerations noted above.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

# Module: Transactions

## API_049 — Fetch Transaction Bootstrap

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Transaction Bootstrap |
| **2. Purpose** | Returns everything the Transaction Entry screen needs in one call — services, expenses, staff, branches, the caller's role, and last-used preferences. |
| **3. Endpoint** | `/transactions/bootstrap` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true`, `data` with `services[]`, `expenses[]`, `staff[]`, `branches[]`, `role`, last-used preferences (see `TransactionBootstrapData` model).

**12. Error Responses**

"We couldn't load transaction data right now." on failure.

**13. Sample Request**

```
GET /transactions/bootstrap
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "services": [], "expenses": [], "staff": [], "branches": [], "role": "employee", "last_used": { "branch_id": 1 } } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load transaction data right now." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Fetched exactly once per screen-open — never re-fetched on every quantity/service change within the same session on that screen (client-side performance requirement; backend should not expect repeated calls per keystroke/selection).

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_050 — Create Transaction

| Field | Detail |
|---|---|
| **1. API Name** | Create Transaction |
| **2. Purpose** | Creates a new Transaction (sale/entry) record. |
| **3. Endpoint** | `/transactions` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

Transaction fields (line items, staff, branch, payment mode, totals, etc. — owned by the Transaction Entry form) plus:

| Field | Type | Required |
|---|---|---|
| `idempotency_key` | string | Yes |

**10. Validation Rules**

- `idempotency_key` is generated once per screen-open by the client and resent unchanged on every retry of the *same* transaction (double-submit, HTTP client auto-retry-on-timeout, crash-and-reopen). **Backend must treat a repeated `idempotency_key` as "return the original record", not create a duplicate.**

**11. Success Response**

`200` — `status: true`, `data` with the saved Transaction record (see `TransactionSaveResult` model).

**12. Error Responses**

"Failed to save transaction" on failure.

**13. Sample Request**

```
POST /transactions
Content-Type: application/json

{
  "idempotency_key": "5f2c9e10-...",
  "branch_id": 1,
  "items": [ { "service_id": 1, "qty": 1, "price": 300 } ],
  "payment_mode": "cash"
}
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "id": "TXN-1001", "status": "paid" } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to save transaction" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- See Validation Rules — idempotency is a hard backend requirement for this endpoint, not just a client-side nicety.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_051 — Update Transaction

| Field | Detail |
|---|---|
| **1. API Name** | Update Transaction |
| **2. Purpose** | Edits an existing Transaction, within a backend-enforced edit window. |
| **3. Endpoint** | `/transactions/{id}` |
| **4. HTTP Method** | PUT |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `id` (string, path) — Transaction id. |
| **8. Query Parameters** | None. |

**9. Request Body**

Updated Transaction fields (same shape as Create, API_050, minus `idempotency_key`).

**10. Validation Rules**

- Server must reject the edit with `409` specifically once the edit window has closed since the Edit screen was opened — the client relies on this exact status code to show a distinct "can no longer be edited" message rather than a generic save error.

**11. Success Response**

`200` — `status: true`, `data` with the updated Transaction record.

**12. Error Responses**

`409` — edit window closed. Other 4xx/5xx — "Failed to update transaction".

**13. Sample Request**

```
PUT /transactions/TXN-1001
Content-Type: application/json

{ "items": [ { "service_id": 1, "qty": 2, "price": 300 } ] }
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "id": "TXN-1001", "status": "paid" } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "This transaction can no longer be edited." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |
| 409 | Edit window has closed since the Edit screen was opened — must be this exact code, the client branches on it specifically. |

**17. Business Rules**

- This is the only endpoint in the entire client that uses HTTP `PUT` — every other mutation uses `POST`. Backend should implement it as a true `PUT` (idempotent full/partial update), not `POST`.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_052 — Mark Transaction Paid

| Field | Detail |
|---|---|
| **1. API Name** | Mark Transaction Paid |
| **2. Purpose** | Settles a Pending transaction, changing only its status/paid timestamp. |
| **3. Endpoint** | `/transactions/{id}/mark-paid` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `id` (string, path) — Transaction id. |
| **8. Query Parameters** | None. |

**9. Request Body**

Empty object `{}` — no fields.

**10. Validation Rules**

- Transaction must currently be in `Pending` status; server should reject if already paid/settled.

**11. Success Response**

`200` — `status: true`, `data` with `status`/`paid_at` (see `TransactionMarkPaidResult` model).

**12. Error Responses**

"Failed to mark transaction as paid" on failure.

**13. Sample Request**

```
POST /transactions/TXN-1001/mark-paid
Content-Type: application/json

{}
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "id": "TXN-1001", "status": "paid", "paid_at": "2026-08-07T10:00:00Z" } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to mark transaction as paid" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Deliberately separate from Update (API_051): never gated by the edit window, since settling a payment is a distinct action from editing line items.

**18. Notes**

Uses the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_053 — Fetch Transactions List

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Transactions List |
| **2. Purpose** | Returns the full Transactions list (no pagination, no filters). |
| **3. Endpoint** | `/transactions` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None currently sent — all filtering/search happens client-side against the full list. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true`, full `TransactionsResponse` payload (list of transactions).

**12. Error Responses**

"Failed to load transactions" on failure.

**13. Sample Request**

```
GET /transactions
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "transactions": [ { "id": "TXN-1001", "status": "paid", "amount": 300 } ] } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to load transactions" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- **Scalability flag for backend:** this is unpaginated by contract today; recommend backend plan for pagination/filtering support before transaction volume grows, since the client currently loads the entire list on every screen open.

**18. Notes**

Hand-rolled try/catch pattern (not the shared `callApi` helper) — consistent with this file's other list method.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_054 — Fetch Transaction Details

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Transaction Details |
| **2. Purpose** | Returns full detail for a single Transaction. |
| **3. Endpoint** | `/transactions/{id}` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `id` (string, path) — Transaction id. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

- `id` must reference an existing Transaction owned by the caller's account.

**11. Success Response**

`200` — `status: true`, `data` with full Transaction detail (line items, staff, branch, payment info — see `TransactionDetailsResponse` model).

**12. Error Responses**

"Failed to load transaction details" on failure.

**13. Sample Request**

```
GET /transactions/TXN-1001
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "id": "TXN-1001", "status": "paid", "items": [ { "service_id": 1, "qty": 1, "price": 300 } ], "branch_id": 1 } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to load transaction details" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Always fetched fresh — the Details screen never receives more than the id from the list screen, so this is called independently every time the screen opens (no client-side caching to invalidate).

**18. Notes**

Hand-rolled try/catch pattern (not the shared `callApi` helper).

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

# Module: Reports

## API_055 — Fetch P&L Report

| Field | Detail |
|---|---|
| **1. API Name** | Fetch P&L Report |
| **2. Purpose** | Returns the Profit & Loss report for the selected period/branch/date range (Account > Report > P&L). |
| **3. Endpoint** | `/reports/pnl` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | | Param | Type | Required | Notes |
|---|---|---|---|
| `period` | string | Yes | One of the keys the response's own `meta.periods[]` advertises — observed values: `today`, `this_week`, `this_month`, `3m`, `6m`, `12m`, `custom`. |
| `branch_id` | string | No | Defaults to `all`. |
| `start_date` | string (ISO 8601) | No | Only meaningful when `period=custom`. |
| `end_date` | string (ISO 8601) | No | Only meaningful when `period=custom`. | |

**9. Request Body**

None.

**10. Validation Rules**

- `period` required; if omitted/unrecognized the client's own mock layer falls back to a `3m`-equivalent dataset — the real backend should define its own explicit default rather than relying on client behavior.

**11. Success Response**

`200` — `status: true`, `data` with the P&L report payload (see `PnlReportData` model).

**12. Error Responses**

"We couldn't load the P&L report right now." on failure.

**13. Sample Request**

```
GET /reports/pnl?period=this_month&branch_id=all
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "revenue": 50000, "expenses": 12000, "profit": 38000, "period": "this_month" } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load the P&L report right now." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- `custom` period requires a real backend to answer an arbitrary date range — not yet supported (client currently mocks this by reusing a fixed dataset).

**18. Notes**

**Backend status: no endpoint currently exists for this report** (per in-code comment) — the client is fully wired against this contract and resolves from local mock JSON per period in mock mode.

**19. Change Log**

v1.0 — Documented against the client's implemented contract; endpoint pending backend implementation.

---

## API_056 — Export P&L Report

| Field | Detail |
|---|---|
| **1. API Name** | Export P&L Report |
| **2. Purpose** | Requests a downloadable export (PDF or Excel) of the P&L report. |
| **3. Endpoint** | `/reports/pnl/export` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | | Param | Type | Required | Notes |
|---|---|---|---|
| `format` | string | Yes | `pdf` or `excel`. | |

**9. Request Body**

None.

**10. Validation Rules**

- `format` required, must be one of `pdf`/`excel`.

**11. Success Response**

`200` — `status: true`, `data.pdf_url` or `data.excel_url` (whichever matches the requested `format`) — a downloadable file URL the client simply launches.

**12. Error Responses**

"We couldn't generate that export right now." on failure.

**13. Sample Request**

```
GET /reports/pnl/export?format=pdf
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "pdf_url": "https://.../pnl_report.pdf" } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't generate that export right now." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Same "backend hands back a URL, client just opens it" contract as Payment Details' Download Receipt/Invoice — no binary streaming through this endpoint's JSON envelope.

**18. Notes**

**Backend status: no endpoint currently exists for this** — mocked client-side today.

**19. Change Log**

v1.0 — Documented against the client's implemented contract; endpoint pending backend implementation.

---

## API_057 — Fetch Revenue & Expense Report

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Revenue & Expense Report |
| **2. Purpose** | Returns the Revenue & Expense Summary report for the selected period/branch/date range. |
| **3. Endpoint** | `/reports/revenue-expense` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | | Param | Type | Required | Notes |
|---|---|---|---|
| `period` | string | Yes | One of the keys the response's own `meta.periods[]` advertises — observed values: `today`, `this_week`, `this_month`, `3m`, `6m`, `12m`, `custom`. |
| `branch_id` | string | No | Defaults to `all`. |
| `start_date` | string (ISO 8601) | No | Only meaningful when `period=custom`. |
| `end_date` | string (ISO 8601) | No | Only meaningful when `period=custom`. | |

**9. Request Body**

None.

**10. Validation Rules**

- `period` required; client falls back to a `today`-equivalent dataset for unrecognized values — backend should define its own default.

**11. Success Response**

`200` — `status: true`, `data` with the Revenue & Expense payload (see `RevenueExpenseReportData` model).

**12. Error Responses**

"We couldn't load the revenue & expense report right now." on failure.

**13. Sample Request**

```
GET /reports/revenue-expense?period=today&branch_id=all
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "revenue": 5000, "expense": 1200, "period": "today" } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load the revenue & expense report right now." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Same `custom`-period limitation as API_055.

**18. Notes**

**Backend status: no endpoint currently exists for this report** — mocked client-side today.

**19. Change Log**

v1.0 — Documented against the client's implemented contract; endpoint pending backend implementation.

---

## API_058 — Export Revenue & Expense Report

| Field | Detail |
|---|---|
| **1. API Name** | Export Revenue & Expense Report |
| **2. Purpose** | Requests a downloadable export (PDF or Excel) of the Revenue & Expense report. |
| **3. Endpoint** | `/reports/revenue-expense/export` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | | Param | Type | Required | Notes |
|---|---|---|---|
| `format` | string | Yes | `pdf` or `excel`. | |

**9. Request Body**

None.

**10. Validation Rules**

- `format` required, must be one of `pdf`/`excel`.

**11. Success Response**

`200` — `status: true`, `data.pdf_url` or `data.excel_url`.

**12. Error Responses**

"We couldn't generate that export right now." on failure.

**13. Sample Request**

```
GET /reports/revenue-expense/export?format=excel
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "excel_url": "https://.../revenue_expense.xlsx" } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't generate that export right now." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Same URL-hand-back contract as API_056.

**18. Notes**

**Backend status: no endpoint currently exists for this** — mocked client-side today.

**19. Change Log**

v1.0 — Documented against the client's implemented contract; endpoint pending backend implementation.

---

## API_059 — Fetch Payment Mode Report

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Payment Mode Report |
| **2. Purpose** | Returns the Payment Mode breakdown report for the selected period/branch/date range (Account > Report > Payment Mode). |
| **3. Endpoint** | `/reports/payment-mode` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | | Param | Type | Required | Notes |
|---|---|---|---|
| `period` | string | Yes | One of the keys the response's own `meta.periods[]` advertises — observed values: `today`, `this_week`, `this_month`, `3m`, `6m`, `12m`, `custom`. |
| `branch_id` | string | No | Defaults to `all`. |
| `start_date` | string (ISO 8601) | No | Only meaningful when `period=custom`. |
| `end_date` | string (ISO 8601) | No | Only meaningful when `period=custom`. | |

**9. Request Body**

None.

**10. Validation Rules**

- `period` required; client falls back to a `this_month`-equivalent dataset for unrecognized values — backend should define its own default.

**11. Success Response**

`200` — `status: true`, `data` with the payment-mode breakdown (see `PaymentModeReportData` model).

**12. Error Responses**

"We couldn't load the payment mode breakdown right now." on failure.

**13. Sample Request**

```
GET /reports/payment-mode?period=3m&branch_id=all
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "cash": 3000, "card": 5000, "upi": 2000, "period": "3m" } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "We couldn't load the payment mode breakdown right now." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Same `custom`-period limitation as API_055/057.

**18. Notes**

**Backend status: no endpoint currently exists for this report** — mocked client-side today; unlike API_055/057 this report has no Export variant in the client.

**19. Change Log**

v1.0 — Documented against the client's implemented contract; endpoint pending backend implementation.

---

# Module: Payments & Subscription

## API_060 — Fetch Payment History

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Payment History |
| **2. Purpose** | Returns the full, unpaginated, unfiltered Payment History list. |
| **3. Endpoint** | `/api/v1/payments/history` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None currently sent — search and status-chip filtering both happen client-side against the full list. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` with `success: true` **(note: this endpoint's envelope uses the key `success`, not `status`, unlike every other endpoint in this app)**, `data` with the payment list.

**12. Error Responses**

"Failed to load payment history" on failure.

**13. Sample Request**

```
GET /api/v1/payments/history
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "success": true, "data": { "payments": [ { "id": "PAY-1001", "amount": 999, "status": "success" } ] } }
```

**15. Sample Error Response**

```json
{ "success": false, "message": "Failed to load payment history" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- **Envelope inconsistency to flag for backend alignment:** this endpoint and API_061 check `response.data['success']`, while every other endpoint in this app checks `response.data['status']`. Recommend standardizing on one envelope key across the whole API surface before this ships broadly — the two payment endpoints are the sole outliers today.
- Client plans for pagination/filtering to eventually move server-side, per the module's own contract notes; currently unpaginated.

**18. Notes**

Hand-rolled try/catch pattern (not the shared `callApi` helper).

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_061 — Fetch Payment Details

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Payment Details |
| **2. Purpose** | Returns full detail for a single payment, always fetched fresh (the Details screen only ever receives an id from the list screen). |
| **3. Endpoint** | `/api/v1/payments/{id}` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `id` (string, path) — Payment id. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

- `id` must reference an existing Payment owned by the caller's account.

**11. Success Response**

`200` with `success: true` (see API_060's envelope note), `data` with full payment detail (receipt/invoice URLs, method, amount, timestamps — see `PaymentDetailsResponse` model).

**12. Error Responses**

"Failed to load payment details" on failure.

**13. Sample Request**

```
GET /api/v1/payments/PAY-1001
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "success": true, "data": { "id": "PAY-1001", "amount": 999, "status": "success", "receipt_url": "https://.../receipt.pdf" } }
```

**15. Sample Error Response**

```json
{ "success": false, "message": "Failed to load payment details" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Same `success`-vs-`status` envelope inconsistency noted in API_060.

**18. Notes**

Hand-rolled try/catch pattern (not the shared `callApi` helper).

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_062 — Create Razorpay Order

| Field | Detail |
|---|---|
| **1. API Name** | Create Razorpay Order |
| **2. Purpose** | Creates a Razorpay payment order for a subscription plan purchase, to be handed to the Razorpay SDK client-side. |
| **3. Endpoint** | `/payments/razorpay/order` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

| Field | Type | Required |
|---|---|---|
| `amount` | integer (paise) | Yes |
| `currency` | string | Yes |
| `planId` | string | Yes |

**10. Validation Rules**

- `amount` must be the integer paise value (not decimal rupees) — e.g. ₹999.00 → `99900`.
- `planId` must reference a valid, purchasable plan from the Plan Catalog (API_064).

**11. Success Response**

`200` — `status: true`, `data` with the Razorpay order object (order id, amount, currency — see `RazorpayOrderResponse` model), to be passed directly into the Razorpay Checkout SDK.

**12. Error Responses**

Non-200/`status:false` surfaces as a generic payment-init failure.

**13. Sample Request**

```
POST /payments/razorpay/order
Content-Type: application/json

{ "amount": 99900, "currency": "INR", "planId": "plan_pro_monthly" }
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "order_id": "order_9A33XWu170gUtm", "amount": 99900, "currency": "INR" } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "<reason>" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- This call precedes handing control to the Razorpay SDK; the actual charge happens outside this API, with the result reported back via API_063.
- Free plans (`isFree: true`) skip this flow entirely and go straight to Activate Free Trial (API_066).

**18. Notes**

**Implementation inconsistency to flag:** hand-rolled try/catch, not the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_063 — Save Razorpay Payment Result

| Field | Detail |
|---|---|
| **1. API Name** | Save Razorpay Payment Result |
| **2. Purpose** | Reports the outcome of a Razorpay checkout attempt back to the backend, for every outcome (success, failure, cancellation). |
| **3. Endpoint** | `/payments/razorpay/result` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

Razorpay payment result payload — payment id, order id, signature (on success), or failure/cancellation reason (see `RazorpayPaymentPayload` model's `toJson()`).

**10. Validation Rules**

- On success, the payload should include everything needed for the backend to independently verify the payment signature server-side (standard Razorpay verification practice) rather than trusting the client's report at face value.

**11. Success Response**

`200` — `status: true`, empty `data` (`void`).

**12. Error Responses**

Failure here is treated as best-effort by the client — see Notes.

**13. Sample Request**

```
POST /payments/razorpay/result
Content-Type: application/json

{ "razorpay_payment_id": "pay_9A33XWu170gUtm", "razorpay_order_id": "order_9A33XWu170gUtm", "razorpay_signature": "..." }
```

**14. Sample Success Response**

```json
{ "status": true }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "<reason>" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- **Must be called for every outcome of the Razorpay flow**, not just success — including a cancelled or failed checkout — so the backend has a complete record even for abandoned payments.

**18. Notes**

**Implementation inconsistency to flag:** hand-rolled try/catch, not the shared `callApi` helper.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_064 — Fetch Plan Catalog

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Plan Catalog |
| **2. Purpose** | Returns the static-ish subscription plan catalog, independent of any one organization. |
| **3. Endpoint** | `/plans` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — full `PlanCatalogResponse` payload (plans list with pricing, features, `isFree` flag).

**12. Error Responses**

Non-200/error → generic catalog-load failure.

**13. Sample Request**

```
GET /plans
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "plans": [ { "id": "plan_free", "name": "Free", "isFree": true, "price": 0 }, { "id": "plan_pro_monthly", "name": "Pro", "isFree": false, "price": 999 } ] } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "<reason>" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- `isFree: true` plans route the purchase flow directly to Activate Free Trial (API_066), skipping Razorpay (API_062/063) entirely.

**18. Notes**

Hand-rolled try/catch pattern (not the shared `callApi` helper).

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_065 — Fetch Subscription Status

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Subscription Status |
| **2. Purpose** | Returns the current subscription lifecycle state for a given organization (trial, active, expiring soon, expired, suspended, cancelled, or first-purchase/no subscription yet). |
| **3. Endpoint** | `/organizations/{orgId}/subscription` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `orgId` (string, path) — Organization id. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

- `orgId` must reference an organization the caller has access to.

**11. Success Response**

`200` — same response shape for every lifecycle state; only field values differ (see `SubscriptionStatusResponse` model). Observed lifecycle states in the client's own test fixtures: first purchase, trial, active (healthy), active (expiring soon), expired, suspended, cancelled.

**12. Error Responses**

Non-200/error → generic subscription-status-load failure.

**13. Sample Request**

```
GET /organizations/ORG-1001/subscription
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "state": "trial", "plan_name": "Pro", "trial_ends_at": "2026-08-21" } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "<reason>" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- One unified response contract across all seven lifecycle states listed above — backend should avoid branching the response shape per state, only the field values should differ.

**18. Notes**

Hand-rolled try/catch pattern (not the shared `callApi` helper).

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_066 — Activate Free Trial

| Field | Detail |
|---|---|
| **1. API Name** | Activate Free Trial |
| **2. Purpose** | Activates a free-tier plan directly for an organization, bypassing the Razorpay payment flow entirely. |
| **3. Endpoint** | `/organizations/{orgId}/subscription/activate-trial` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `orgId` (string, path) — Organization id. |
| **8. Query Parameters** | None. |

**9. Request Body**

None documented — client sends no body beyond the path parameter.

**10. Validation Rules**

- `orgId` must reference an organization the caller has access to, and the targeted plan must have `isFree: true` per the Plan Catalog (API_064).

**11. Success Response**

`200` — `status: true`, empty `data` (`void`).

**12. Error Responses**

Non-200/error → generic activation failure.

**13. Sample Request**

```
POST /organizations/ORG-1001/subscription/activate-trial
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "<reason>" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Must be called instead of the Razorpay flow (API_062/063) whenever the selected plan is free — this is a hard branch in the purchase flow, not an optional shortcut.

**18. Notes**

**Backend status: exact path not yet confirmed against a live backend** — the client's own comment notes the contract only requires this action to exist and be called for free plans; the literal path shown here is the client's current placeholder and should be confirmed/finalized with backend before release.

**19. Change Log**

v1.0 — Documented against the client's current placeholder contract; path pending backend confirmation.

---

# Module: Notifications

## API_067 — Fetch Notifications

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Notifications |
| **2. Purpose** | Returns the full, unpaginated Notification list for the signed-in user. |
| **3. Endpoint** | `/api/v1/notifications` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None — there is no server-side search/filtering yet; the All/Unread/Read chips and search are both applied client-side against this full list. |

**9. Request Body**

None.

**10. Validation Rules**

None (read-only).

**11. Success Response**

`200` — `status: true`, full `NotificationListResponse` payload (list of notifications with id, title, message, read state, timestamp, destination).

**12. Error Responses**

"Failed to load notifications" on failure.

**13. Sample Request**

```
GET /api/v1/notifications
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "notifications": [ { "id": 1, "title": "New transaction", "message": "...", "read": false, "created_at": "2026-08-07T09:00:00Z" } ] } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to load notifications" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- **Scalability flag for backend:** unpaginated by contract today; recommend planning for server-side pagination/filtering as notification volume grows.

**18. Notes**

Hand-rolled try/catch pattern (not the shared `callApi` helper). Base path for the whole Notifications module: `/api/v1/notifications`.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_068 — Fetch Notification By Id

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Notification By Id |
| **2. Purpose** | Returns full detail for a single notification — used only when a push/deep-link payload arrives with just `{id, display_mode, destination}` and needs the full title/message/actions a slim push payload doesn't carry. |
| **3. Endpoint** | `/api/v1/notifications/{id}` |
| **4. HTTP Method** | GET |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `id` (integer, path) — Notification id. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

- `id` must reference an existing notification belonging to the caller.

**11. Success Response**

`200` — `status: true`, `data` (or `data.notification`, both shapes are accepted by the client) with the full `NotificationModel` fields.

**12. Error Responses**

"Failed to load notification" on failure; `404` if the notification does not exist for this user.

**13. Sample Request**

```
GET /api/v1/notifications/1
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true, "data": { "id": 1, "title": "New transaction", "message": "...", "read": false, "destination": "transaction_detail" } }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to load notification" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Optional per the client's contract — used only for the specific push/deep-link case described in Purpose, not on the normal Notifications list screen (which relies entirely on API_067).

**18. Notes**

Client accepts the payload either as a bare object under `data`, or nested one level deeper under `data.notification` — backend should pick one and the client will be aligned to match; documented here as-implemented (both currently tolerated).

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_069 — Mark Notification Read

| Field | Detail |
|---|---|
| **1. API Name** | Mark Notification Read |
| **2. Purpose** | Marks a single notification as read. |
| **3. Endpoint** | `/api/v1/notifications/read` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None (id is in the body, not the path — see Request Body). |
| **8. Query Parameters** | None. |

**9. Request Body**

| Field | Type | Required |
|---|---|---|
| `notification_id` | integer | Yes |

**10. Validation Rules**

- `notification_id` must reference an existing notification belonging to the caller.

**11. Success Response**

`200` — `status: true` (boolean success signal).

**12. Error Responses**

"Failed to mark notification read" on failure.

**13. Sample Request**

```
POST /api/v1/notifications/read
Content-Type: application/json

{ "notification_id": 1 }
```

**14. Sample Success Response**

```json
{ "status": true }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to mark notification read" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Client applies the read state optimistically in the UI immediately and treats a failure here as best-effort — a failed mark-as-read call is logged/ignored rather than shown as an error to the user, per the module's "never crash / gracefully handle failed mark-as-read" requirement.

**18. Notes**

Hand-rolled try/catch pattern (not the shared `callApi` helper).

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_070 — Mark All Notifications Read

| Field | Detail |
|---|---|
| **1. API Name** | Mark All Notifications Read |
| **2. Purpose** | Marks every notification for the signed-in user as read in one call. |
| **3. Endpoint** | `/api/v1/notifications/read-all` |
| **4. HTTP Method** | POST |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

Empty object `{}`.

**10. Validation Rules**

None beyond a valid Authorization header.

**11. Success Response**

`200` — `status: true`.

**12. Error Responses**

"Failed to mark all notifications read" on failure.

**13. Sample Request**

```
POST /api/v1/notifications/read-all
Content-Type: application/json

{}
```

**14. Sample Success Response**

```json
{ "status": true }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to mark all notifications read" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- Same best-effort/optimistic-update treatment as API_069.

**18. Notes**

Hand-rolled try/catch pattern (not the shared `callApi` helper).

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_071 — Delete Notification

| Field | Detail |
|---|---|
| **1. API Name** | Delete Notification |
| **2. Purpose** | Deletes a single notification. |
| **3. Endpoint** | `/api/v1/notifications/{id}` |
| **4. HTTP Method** | DELETE |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `id` (integer, path) — Notification id. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

- `id` must reference an existing notification belonging to the caller.

**11. Success Response**

`200` — `status: true`.

**12. Error Responses**

"Failed to delete notification" on failure.

**13. Sample Request**

```
DELETE /api/v1/notifications/1
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to delete notification" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

N/A.

**18. Notes**

This and API_072 are the only two `DELETE`-verb calls in the entire client (every other delete elsewhere in the app is modeled as `POST .../delete`). Hand-rolled try/catch pattern (not the shared `callApi` helper).

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_072 — Delete All Read Notifications

| Field | Detail |
|---|---|
| **1. API Name** | Delete All Read Notifications |
| **2. Purpose** | Bulk-deletes every notification currently marked as read ("Delete All Read" overflow action). |
| **3. Endpoint** | `/api/v1/notifications/read` |
| **4. HTTP Method** | DELETE |
| **5. Authentication** | Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once. |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

None beyond a valid Authorization header.

**11. Success Response**

`200` — `status: true`.

**12. Error Responses**

"Failed to delete read notifications" on failure.

**13. Sample Request**

```
DELETE /api/v1/notifications/read
Authorization: Bearer <access_token>
```

**14. Sample Success Response**

```json
{ "status": true }
```

**15. Sample Error Response**

```json
{ "status": false, "message": "Failed to delete read notifications" }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success — `status: true` and the requested `data` payload returned. |
| 400 | Bad Request — malformed payload or a field failed server-side validation. |
| 401 | Unauthorized — missing/invalid/expired access token (protected endpoints only). |
| 404 | Not Found — the referenced resource (id in the path) does not exist. |
| 422 | Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id). |
| 500 | Internal Server Error — unexpected server-side failure. |

**17. Business Rules**

- **Path collision to flag for backend routing:** this endpoint's path (`DELETE /api/v1/notifications/read`) differs from API_069's (`POST /api/v1/notifications/read`) only in HTTP verb — both must be registered as distinct routes sharing the same path string. Confirm the backend router disambiguates by method correctly.

**18. Notes**

Hand-rolled try/catch pattern (not the shared `callApi` helper).

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

# Module: Third-Party APIs (Not Our Backend)

## API_073 — Fetch Indian States (3rd-Party)

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Indian States (3rd-Party) |
| **2. Purpose** | Fetches the list of Indian states from the free public countriesnow.space API, used to populate a State dropdown during Registration/Account/Branch address entry. |
| **3. Endpoint** | `https://countriesnow.space/api/v0.1/countries/states` |
| **4. HTTP Method** | POST |
| **5. Authentication** | None. Public third-party API, no API key or token required. Not routed through the app's own `DioClient` (no base URL, no Authorization header, no token-refresh interceptor). |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

| Field | Type | Required |
|---|---|---|
| `country` | string | Yes (always `"India"` in this client) |

**10. Validation Rules**

- This is a third-party contract, not ours — client does not control or validate beyond checking `error: false` in the response.

**11. Success Response**

`200` — `error: false`, `data.states[]` (each with a `name`), sorted alphabetically by the client after receipt.

**12. Error Responses**

`error: true` from the third party, or a `DioException`, both surface as "Could not load states".

**13. Sample Request**

```
POST https://countriesnow.space/api/v0.1/countries/states
Content-Type: application/json

{ "country": "India" }
```

**14. Sample Success Response**

```json
{ "error": false, "data": { "name": "India", "states": [ { "name": "Karnataka" }, { "name": "Maharashtra" } ] } }
```

**15. Sample Error Response**

```json
{ "error": true, "msg": "..." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success (third party's own envelope indicates success/failure via `error`, not HTTP status alone). |
| 4xx/5xx | Third-party service error — surfaced as a generic "Could not load states" / connectivity failure. |

**17. Business Rules**

- Deliberately **not** routed through `DioClient` (our backend's base URL, auth interceptor, and token-refresh logic would be actively wrong for a public third party) — this uses its own isolated `Dio` instance with a 15s timeout.
- Connectivity is pre-checked before the call, same UX as our own backend calls, so a user with no signal sees an immediate "No internet connection" rather than waiting out the full timeout.

**18. Notes**

Not part of our backend surface — documented here for completeness per the requested full API inventory, but any backend contract changes are out of our control (owned by countriesnow.space).

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_074 — Fetch Cities For State (3rd-Party)

| Field | Detail |
|---|---|
| **1. API Name** | Fetch Cities For State (3rd-Party) |
| **2. Purpose** | Fetches the list of cities for a given Indian state from the free public countriesnow.space API, used to populate a City dropdown once a State is selected. |
| **3. Endpoint** | `https://countriesnow.space/api/v0.1/countries/state/cities` |
| **4. HTTP Method** | POST |
| **5. Authentication** | None. Public third-party API, no API key or token required. Not routed through the app's own `DioClient` (no base URL, no Authorization header, no token-refresh interceptor). |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | None. |
| **8. Query Parameters** | None. |

**9. Request Body**

| Field | Type | Required |
|---|---|---|
| `country` | string | Yes (always `"India"`) |
| `state` | string | Yes — the state name selected via API_073 |

**10. Validation Rules**

- Third-party contract, not ours.

**11. Success Response**

`200` — `error: false`, `data[]` (array of city name strings), sorted alphabetically by the client after receipt.

**12. Error Responses**

`error: true`, or a `DioException`, both surface as "Could not load cities".

**13. Sample Request**

```
POST https://countriesnow.space/api/v0.1/countries/state/cities
Content-Type: application/json

{ "country": "India", "state": "Karnataka" }
```

**14. Sample Success Response**

```json
{ "error": false, "data": ["Bengaluru", "Mysuru", "Mangaluru"] }
```

**15. Sample Error Response**

```json
{ "error": true, "msg": "..." }
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Success (third party's own envelope indicates success/failure via `error`). |
| 4xx/5xx | Third-party service error — surfaced as a generic connectivity/load failure. |

**17. Business Rules**

- Same isolation-from-`DioClient` rationale as API_073.

**18. Notes**

Not part of our backend surface — documented here for completeness. **Implementation detail:** this call hardcodes the full URL rather than a relative path on the shared `_dio` instance's `baseUrl` — functionally equivalent, but inconsistent with `fetchIndianStates`' relative-path style in the same class; harmless but worth normalizing if this file is touched again.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---

## API_075 — Verify Pincode (3rd-Party)

| Field | Detail |
|---|---|
| **1. API Name** | Verify Pincode (3rd-Party) |
| **2. Purpose** | Looks up City/State for a given Indian postal (PIN) code via the free public api.postalpincode.in service, to auto-fill and let the user confirm City/State from a pincode entry. |
| **3. Endpoint** | `https://api.postalpincode.in/pincode/{pincode}` |
| **4. HTTP Method** | GET |
| **5. Authentication** | None. Public third-party API, no API key or token required. Not routed through the app's own `DioClient` (no base URL, no Authorization header, no token-refresh interceptor). |
| **6. Headers** | `Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit). |
| **7. Path Parameters** | `pincode` (string, path) — the 6-digit Indian PIN code to look up. |
| **8. Query Parameters** | None. |

**9. Request Body**

None.

**10. Validation Rules**

- Third-party contract, not ours; client treats any non-2xx, empty response, non-`Success` status, or missing `PostOffice` data uniformly as "invalid pincode" rather than surfacing the specific third-party error.

**11. Success Response**

`200` — a JSON array; first element's `Status` is `"Success"` and `PostOffice[]` is non-empty. Client extracts `District` (→ city) and `State` from the first post office entry.

**12. Error Responses**

Any failure (network, empty result, non-`Success` status) resolves to `{ isValid: false }` client-side — no error message is surfaced to distinguish "bad pincode" from "service unreachable" beyond the separate `isOffline` flag for connectivity specifically.

**13. Sample Request**

```
GET https://api.postalpincode.in/pincode/560025
```

**14. Sample Success Response**

```json
[
  {
    "Message": "Number of Post Office(s) found: 1",
    "Status": "Success",
    "PostOffice": [ { "Name": "Residency Road", "District": "Bengaluru", "State": "Karnataka" } ]
  }
]
```

**15. Sample Error Response**

```json
[ { "Message": "No records found", "Status": "Error", "PostOffice": null } ]
```

**16. HTTP Status Codes**

| Code | Meaning |
|---|---|
| 200 | Always 200 from this third party — success/failure is signaled inside the JSON body via `Status`, not HTTP status. |
| Network | A connectivity failure (checked up front) returns `{ isValid: false, isOffline: true }` client-side so the UI can distinguish "bad pincode" from "can't reach the service". |

**17. Business Rules**

- `isOffline: true` specifically prevents the UI from telling the user their pincode is invalid when the real cause is a connectivity problem — this distinction matters for the confirmation-dialog UX.

**18. Notes**

Not part of our backend surface — documented here for completeness. India-only, free, no API key.

**19. Change Log**

v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing.

---
