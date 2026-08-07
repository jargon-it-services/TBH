# -*- coding: utf-8 -*-
import io

OUT = []

def w(s=""):
    OUT.append(s)

STD_ENVELOPE_SUCCESS = '{ "status": true, "message": "<text>", "data": { ... } }'
STD_ENVELOPE_ERROR = '{ "status": false, "message": "<reason>", "error_code": "<optional_machine_code>" }'

AUTH_BEARER = "Required. `Authorization: Bearer <access_token>` header, attached automatically by `DioClient`'s request interceptor for every endpoint not in the public-path allow-list. A `401` here (except on Logout, see Notes) triggers the app's silent refresh-token flow before the request is retried once."
AUTH_PUBLIC = "Not required. This endpoint is in `DioClient`'s `_publicPaths` allow-list, so no `Authorization` header is sent and a `401` response is treated as a normal credential/validation failure, not a session expiry."
AUTH_THIRDPARTY = "None. Public third-party API, no API key or token required. Not routed through the app's own `DioClient` (no base URL, no Authorization header, no token-refresh interceptor)."

HEADERS_STD = "`Content-Type: application/json` (default Dio behavior). `Accept: application/json` (implicit)."
HEADERS_MULTIPART = "`Content-Type: multipart/form-data` (set automatically by Dio when the request body is a `FormData` instance, i.e. whenever a file is attached)."

STATUS_CODES_STD = [
    ("200", "Success — `status: true` and the requested `data` payload returned."),
    ("400", "Bad Request — malformed payload or a field failed server-side validation."),
    ("401", "Unauthorized — missing/invalid/expired access token (protected endpoints only)."),
    ("404", "Not Found — the referenced resource (id in the path) does not exist."),
    ("422", "Unprocessable Entity — payload is well-formed JSON but fails business validation (e.g. duplicate code, invalid reference id)."),
    ("500", "Internal Server Error — unexpected server-side failure."),
]

def status_rows(extra=None):
    rows = list(STATUS_CODES_STD)
    if extra:
        rows = rows + extra
    return rows

CHANGELOG_INITIAL = "v1.0 — Initial documented version (this report), reverse-engineered from the Flutter client's `lib/core/network/apis/` layer. No prior backend documentation existed for this endpoint at the time of writing."

def section(title):
    return f"### {title}"

def render_entry(e):
    w(f"## {e['id']} — {e['name']}")
    w()
    w("| Field | Detail |")
    w("|---|---|")
    w(f"| **1. API Name** | {e['name']} |")
    w(f"| **2. Purpose** | {e['purpose']} |")
    w(f"| **3. Endpoint** | `{e['endpoint']}` |")
    w(f"| **4. HTTP Method** | {e['method']} |")
    w(f"| **5. Authentication** | {e['auth']} |")
    w(f"| **6. Headers** | {e['headers']} |")
    w(f"| **7. Path Parameters** | {e['path_params']} |")
    w(f"| **8. Query Parameters** | {e['query_params']} |")
    w()
    w("**9. Request Body**")
    w()
    w(e['request_body'])
    w()
    w("**10. Validation Rules**")
    w()
    w(e['validation_rules'])
    w()
    w("**11. Success Response**")
    w()
    w(e['success_response'])
    w()
    w("**12. Error Responses**")
    w()
    w(e['error_responses'])
    w()
    w("**13. Sample Request**")
    w()
    w("```")
    w(e['sample_request'])
    w("```")
    w()
    w("**14. Sample Success Response**")
    w()
    w("```json")
    w(e['sample_success'])
    w("```")
    w()
    w("**15. Sample Error Response**")
    w()
    w("```json")
    w(e['sample_error'])
    w("```")
    w()
    w("**16. HTTP Status Codes**")
    w()
    w("| Code | Meaning |")
    w("|---|---|")
    for code, meaning in e['status_codes']:
        w(f"| {code} | {meaning} |")
    w()
    w("**17. Business Rules**")
    w()
    w(e['business_rules'])
    w()
    w("**18. Notes**")
    w()
    w(e['notes'])
    w()
    w("**19. Change Log**")
    w()
    w(e.get('changelog', CHANGELOG_INITIAL))
    w()
    w("---")
    w()

ENTRIES = []

def add(**kwargs):
    ENTRIES.append(kwargs)

# ============================================================
# MODULE: AUTH & SESSION
# ============================================================

add(id="API_001", name="Login", module="Auth & Session",
    purpose="Authenticates a user with organization code, email, and password; issues an access token, refresh token, and the user's session bootstrap data (profile, account, current plan, management counters, feature locks).",
    endpoint="/auth/login", method="POST",
    auth=AUTH_PUBLIC,
    headers=HEADERS_STD,
    path_params="None.",
    query_params="None.",
    request_body="""| Field | Type | Required |
|---|---|---|
| `organization_code` | string | Yes |
| `email` | string | Yes |
| `password` | string | Yes |""",
    validation_rules="- All three fields required (non-empty), enforced client-side before the call is made.\n- `email` expected to be a valid email format (client-side only; server-side rule not documented).\n- Server is the source of truth for credential correctness; client places no length/format constraint on `password`.",
    success_response="`200` — `status: true`, `data` contains `token`, `refresh_token`, `expires_in` (seconds), `user_info` (id, user_name, email, mobile, role, profile_image, status), `account` (name, code, branch_name), `recent_plan` (name, valid_until, status, date_format), `management` (total_firms, total_staff, total_services, total_expenses, total_salary_rules), `feature_lock` (array of locked feature keys).",
    error_responses="`401` — invalid organization code, email, or password. `400` — missing/malformed fields.",
    sample_request="""POST /auth/login
Content-Type: application/json

{
  "organization_code": "JAR-1233",
  "email": "krusna.satbhai@gmail.com",
  "password": "••••••••"
}""",
    sample_success="""{
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
}""",
    sample_error="""{
  "status": false,
  "message": "Invalid credentials"
}""",
    status_codes=status_rows(),
    business_rules="- `role` returned in `user_info.role` drives which dashboard/header variant the client renders (Super Admin / Account Admin / Branch Admin / Manager / Employee — see API_017).\n- `feature_lock` gates client-side visibility of paid features (e.g. `report`, `payment_slip`, `pnl`) based on the account's current plan.\n- Response shape changed from a flat `{token, refresh_token, user_name, role}` to the nested `user_info`/`account`/`recent_plan`/`management` shape documented here; the client keeps `userName`/`role` convenience getters for backward compatibility.",
    notes="- `token` and `refresh_token` are persisted client-side (secure storage) via `SessionManager` immediately after a successful call.\n- This is the only endpoint (besides Register) that establishes a session; every other protected call depends on the token issued here.\n- `expires_in` is optional in the payload; the client tolerates its absence.")

add(id="API_002", name="Refresh Token", module="Auth & Session",
    purpose="Exchanges a valid refresh token for a new access token (and optionally a rotated refresh token), used transparently by the client when a protected call returns 401.",
    endpoint="/auth/refresh", method="POST",
    auth=AUTH_PUBLIC + " (Not in the sense of being user-facing — this call itself carries no bearer token; the refresh token is the credential, sent in the body.)",
    headers=HEADERS_STD,
    path_params="None.",
    query_params="None.",
    request_body="""| Field | Type | Required |
|---|---|---|
| `refresh_token` | string | Yes |""",
    validation_rules="- `refresh_token` required, non-empty.\n- Server must reject an expired/revoked/unknown refresh token with `401` specifically — this is the one status code the client treats as \"session is truly over\"; any other failure (timeout, 5xx, malformed response) is treated as transient and does **not** log the user out.",
    success_response="`200` — `status: true`, `data.token` (new access token), `data.refresh_token` (new refresh token, optional — omit to keep the old one valid, per backend's rotation policy).",
    error_responses="`401` — refresh token invalid, expired, or revoked. Any other error is treated by the client as network/transient, not a rejection.",
    sample_request="""POST /auth/refresh
Content-Type: application/json

{ "refresh_token": "mock_refresh_token_7c21f9ab" }""",
    sample_success="""{
  "status": true,
  "message": "Token refreshed",
  "data": {
    "token": "mock_auth_token_refreshed_9f31ab",
    "refresh_token": "mock_refresh_token_9f31ab"
  }
}""",
    sample_error="""{
  "status": false,
  "message": "Refresh token invalid or expired"
}""",
    status_codes=status_rows([("409", "Not expected, but if returned is treated as a non-fatal transient failure, not a session rejection.")]),
    business_rules="- Concurrent 401s from multiple simultaneous requests are coalesced client-side into a single in-flight refresh call — the backend should not expect a refresh storm even if several requests fail at once.\n- On success, the retried original request is re-issued once with the new token; a second 401 after that retry is treated as a hard session failure (auto-logout) with no further refresh attempt (loop guard).",
    notes="**Backend status: not yet implemented at time of writing** (per in-code contract comment `docs/refresh_token_backend_contract.md`). The client is fully wired against this contract and currently resolves from a local mock JSON in mock mode.",
    changelog="v1.0 — Documented against the client's implemented contract; endpoint pending backend implementation.")

add(id="API_003", name="Logout", module="Auth & Session",
    purpose="Invalidates the current session/tokens on the server side.",
    endpoint="/auth/logout", method="POST",
    auth=AUTH_BEARER + " **Exception:** a 401 from this specific call is deliberately NOT routed through the refresh/auto-logout interceptor — the caller already runs its own \"clear session, go to Login\" sequence regardless of this call's outcome, to avoid two logout flows racing each other.",
    headers=HEADERS_STD,
    path_params="None.",
    query_params="None.",
    request_body="None.",
    validation_rules="None beyond a valid Authorization header.",
    success_response="`200` — `status: true`, `data.message`.",
    error_responses="`401` — invalid/expired token (handled locally by the caller, not the global interceptor).",
    sample_request="""POST /auth/logout
Authorization: Bearer <access_token>""",
    sample_success="""{
  "status": true,
  "message": "Logged out successfully",
  "data": { "message": "Logged out successfully" }
}""",
    sample_error="""{
  "status": false,
  "message": "Invalid or expired token"
}""",
    status_codes=status_rows(),
    business_rules="- Client clears local session state and navigates to Login regardless of whether this call ultimately succeeds — this is fire-and-forget from a UX standpoint.",
    notes="**Backend status: not yet implemented at time of writing** (contract documented in-code, resolves from local mock JSON in mock mode).",
    changelog="v1.0 — Documented against the client's implemented contract; endpoint pending backend implementation.")

# ============================================================
# MODULE: REGISTRATION & FORGOT PASSWORD
# ============================================================

add(id="API_004", name="Register Business", module="Registration & Forgot Password",
    purpose="Creates a new business account (organization) along with its owner/admin user, including identity document upload, and returns an access token for immediate sign-in.",
    endpoint="/register", method="POST",
    auth=AUTH_PUBLIC,
    headers=HEADERS_MULTIPART,
    path_params="None.",
    query_params="None.",
    request_body="""Multipart form fields:

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
| `invite_token` | string | No (auto-attached from a stored deep-link invite, if present) |""",
    validation_rules="- All fields marked Required must be non-empty; `gstin` and `account_photo` are optional.\n- `id_proof_document` is mandatory (unlike `account_photo`).\n- `platform` is resolved internally (device/platform identifier) and never shown to or editable by the user.\n- `invite_token`, if a prior deep link stored one, is attached silently without any UI field for it.",
    success_response="`200` — `status: true`, `data` contains `token`, `business_name`, `business_id`, `verification_status`, `gstin`, `account_photo_url`.",
    error_responses="`400`/`422` — validation failure on any required field. Backend may also return a machine-readable `error_code` (e.g. `invite_invalid`, `invite_expired`, `invite_revoked`) specifically for a dead invite token.",
    sample_request="""POST /register
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
platform=android""",
    sample_success="""{
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
}""",
    sample_error="""{
  "status": false,
  "message": "Registration failed",
  "error_code": "invite_expired"
}""",
    status_codes=status_rows(),
    business_rules="- If an `invite_token` was attached: on registration success, or if the backend's `error_code` identifies the invite as dead (`invite_invalid` / `invite_expired` / `invite_revoked`), the client deletes its locally stored invite token. For any other failure (validation, network), the token is kept so the user can retry.\n- `verification_status` in the response (e.g. `pending_review`) implies the backend may run manual/async verification after registration — not surfaced elsewhere in the client beyond this initial value.",
    notes="- The client issues a session token (`token`) directly from this call, i.e. registration doubles as login — no separate login call is made right after successful registration.")

FORGOT_PW_AUTH = AUTH_PUBLIC

add(id="API_005", name="Verify Organization", module="Registration & Forgot Password",
    purpose="First step of the Forgot Password flow — confirms an organization code exists and returns its display name for user confirmation before proceeding to OTP.",
    endpoint="/forgot-password/verify-organization", method="POST",
    auth=FORGOT_PW_AUTH,
    headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="""| Field | Type | Required |
|---|---|---|
| `organization_code` | string | Yes |""",
    validation_rules="- `organization_code` required, non-empty.",
    success_response="`200` — `status: true`, `data.organization_name`.",
    error_responses="`404`/`400` — organization code not found.",
    sample_request="""POST /forgot-password/verify-organization
Content-Type: application/json

{ "organization_code": "JAR-1233" }""",
    sample_success="""{
  "status": true,
  "message": "Organization verified successfully",
  "data": { "organization_name": "Meridian Trading Co." }
}""",
    sample_error="""{
  "status": false,
  "message": "Organization code not found"
}""",
    status_codes=status_rows(),
    business_rules="- Purely a lookup/confirmation step; does not itself advance any server-side reset-flow state machine beyond what Send OTP (API_006) requires.",
    notes="Part of a 4-step Forgot Password sequence: Verify Organization → Send OTP → Verify OTP → Reset Password (API_005–API_008), each step's output feeding the next.")

add(id="API_006", name="Send OTP", module="Registration & Forgot Password",
    purpose="Sends a one-time password to the account's registered email address as the second step of Forgot Password.",
    endpoint="/forgot-password/send-otp", method="POST",
    auth=FORGOT_PW_AUTH, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="""| Field | Type | Required |
|---|---|---|
| `organization_code` | string | Yes |
| `email` | string | Yes |""",
    validation_rules="- Both fields required.\n- `email` should match the account on file for `organization_code` (server-enforced).",
    success_response="`200` — `status: true`, `data.message`, `data.expiry_seconds` (OTP validity window, e.g. 300).",
    error_responses="`404`/`400` — organization/email combination not found, or rate-limited.",
    sample_request="""POST /forgot-password/send-otp
Content-Type: application/json

{ "organization_code": "JAR-1233", "email": "krusna.satbhai@gmail.com" }""",
    sample_success="""{
  "status": true,
  "message": "OTP sent to your registered email address",
  "data": { "message": "OTP sent to your registered email address", "expiry_seconds": 300 }
}""",
    sample_error="""{
  "status": false,
  "message": "Could not send OTP"
}""",
    status_codes=status_rows([("429", "Too many OTP requests in a short window (recommended; not confirmed against a live backend).")]),
    business_rules="- `expiry_seconds` returned by the server drives the client's OTP countdown/resend-enable timer.",
    notes="Second step of the 4-step Forgot Password sequence (API_005–API_008).")

add(id="API_007", name="Verify OTP", module="Registration & Forgot Password",
    purpose="Validates the OTP entered by the user and issues a short-lived reset token used to authorize the final password change.",
    endpoint="/forgot-password/verify-otp", method="POST",
    auth=FORGOT_PW_AUTH, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="""| Field | Type | Required |
|---|---|---|
| `organization_code` | string | Yes |
| `email` | string | Yes |
| `otp` | string | Yes |""",
    validation_rules="- All three fields required.\n- `otp` must match the one most recently sent for this `organization_code`/`email` pair and not be expired.",
    success_response="`200` — `status: true`, `data.reset_token`.",
    error_responses="`400`/`401` — invalid or expired OTP.",
    sample_request="""POST /forgot-password/verify-otp
Content-Type: application/json

{ "organization_code": "JAR-1233", "email": "krusna.satbhai@gmail.com", "otp": "482913" }""",
    sample_success="""{
  "status": true,
  "message": "OTP verified successfully",
  "data": { "reset_token": "mock_reset_token_7f2ab9" }
}""",
    sample_error="""{
  "status": false,
  "message": "Invalid or expired OTP"
}""",
    status_codes=status_rows(),
    business_rules="- `reset_token` returned here must be presented (implicitly — see Notes) to authorize the final Reset Password call; treat it as a single-use, short-lived credential.",
    notes="Third step of the 4-step Forgot Password sequence. **Contract inconsistency to flag for backend alignment:** the client's current `resetPassword` call (API_008) does not actually send `reset_token` in its request body — only `organization_code`/`email`/`otp`/`password`. Backend should confirm whether `reset_token` or the repeated `otp` is the intended authorization mechanism for the final step, and the client updated accordingly.")

add(id="API_008", name="Reset Password", module="Registration & Forgot Password",
    purpose="Final step of Forgot Password — sets a new password for the account.",
    endpoint="/forgot-password/reset", method="POST",
    auth=FORGOT_PW_AUTH, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="""| Field | Type | Required |
|---|---|---|
| `organization_code` | string | Yes |
| `email` | string | Yes |
| `otp` | string | Yes |
| `password` | string | Yes (new password) |""",
    validation_rules="- All fields required.\n- `password` should meet whatever complexity policy the backend enforces (not encoded client-side beyond non-empty).",
    success_response="`200` — `status: true`, `data.message`.",
    error_responses="`400`/`401` — OTP no longer valid for this step, or password fails policy.",
    sample_request="""POST /forgot-password/reset
Content-Type: application/json

{
  "organization_code": "JAR-1233",
  "email": "krusna.satbhai@gmail.com",
  "otp": "482913",
  "password": "••••••••"
}""",
    sample_success="""{
  "status": true,
  "message": "Password changed successfully",
  "data": { "message": "Password changed successfully" }
}""",
    sample_error="""{
  "status": false,
  "message": "Failed to change password"
}""",
    status_codes=status_rows(),
    business_rules="- On success the user is expected to log in again via API_001 with the new password; this call does not itself issue a session token.",
    notes="See API_007's Notes regarding the `reset_token` vs. `otp` inconsistency between the documented 3-step contract and the client's actual request payload — recommend backend and client teams confirm the intended field before this goes live.")

# ============================================================
# MODULE: APP / PROFILE / ACCOUNT
# ============================================================

add(id="API_009", name="Check App Version", module="App / Profile / Account",
    purpose="Backend-driven version gate — tells the client whether the current build is blocked (maintenance mode), force-update-required, optionally-update-available, or up to date.",
    endpoint="/app/version", method="GET",
    auth=AUTH_PUBLIC + " Called from the Splash screen before any session necessarily exists.",
    headers=HEADERS_STD,
    path_params="None.", query_params="None (see Notes for how the client's own build number is used).",
    request_body="None.",
    validation_rules="None (read-only, no input).",
    success_response="`200` — `status: true`, `data.maintenance` (bool), `data.minimum_build` (int), `data.latest_build` (int), `data.store_url`, `data.message`.",
    error_responses="Any non-200/`status:false` is treated as \"could not check version\" and the client fails open (does not block the user).",
    sample_request="""GET /app/version""",
    sample_success="""{
  "status": true,
  "message": "OK",
  "data": {
    "maintenance": false,
    "minimum_build": 120,
    "latest_build": 125,
    "store_url": "https://play.google.com/store/apps/details?id=com.example.app",
    "message": "Please update the application."
  }
}""",
    sample_error="""{
  "status": false,
  "message": "Could not check app version"
}""",
    status_codes=status_rows(),
    business_rules="""- `maintenance: true` → app shows a blocking maintenance screen; `minimum_build`/`latest_build`/`store_url` are irrelevant in this state.
- `maintenance: false` and client build `< minimum_build` → force update (blocking).
- `maintenance: false`, client build `>= minimum_build` and `< latest_build` → optional update (dismissible).
- `maintenance: false`, client build `>= latest_build` → up to date, no prompt.""",
    notes="The client compares the response against its own compiled build number (`AppBuildInfo`) locally — the backend does not need to know the caller's build number in the request; it always returns the same current gate values, and the client does the comparison.")

add(id="API_010", name="Fetch Profile", module="App / Profile / Account",
    purpose="Returns the signed-in user's own profile, current account/branch context, plan, management counters, and feature locks — the same payload shape as Login's `data`, minus the auth-issuing fields.",
    endpoint="/user/profile", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="None.",
    validation_rules="None (read-only).",
    success_response="`200` — `status: true`, `data.user_info`, `data.account`, `data.recent_plan`, `data.management`, `data.feature_lock` — identical shape to Login's `data` minus `token`/`refresh_token`/`expires_in`.",
    error_responses="`401` — expired/invalid token (triggers refresh flow before surfacing to the user).",
    sample_request="""GET /user/profile
Authorization: Bearer <access_token>""",
    sample_success="""{
  "status": true,
  "message": "Profile fetched successfully",
  "data": {
    "user_info": { "id": 101, "user_name": "Krushna Satbhai", "email": "krusna.satbhai@gmail.com", "mobile": "8793052520", "role": "account_admin", "profile_image": null, "status": "active" },
    "account": { "name": "Jargon Pvt Ltd", "code": "JAR-1234", "branch_name": "Pune" },
    "recent_plan": { "name": "Pro", "valid_until": "2026-08-01", "status": "active", "date_format": "dd MMM yyyy" },
    "management": { "total_firms": 22, "total_staff": 220, "total_services": 224, "total_expenses": 12, "total_salary_rules": 5 },
    "feature_lock": []
  }
}""",
    sample_error="""{
  "status": false,
  "message": "We couldn't load your profile right now."
}""",
    status_codes=status_rows(),
    business_rules="- Response contract is intentionally identical to Login's `data` object (minus auth fields) so the client can reuse the same parsing model (`user_info`/`account`/`recent_plan`/`management`/`feature_lock`) for both.",
    notes="Distinct from Account Info (API_011) — Profile is the logged-in user's session/role context; Account Info is the editable business/registration record.")

add(id="API_011", name="Fetch Account Info", module="App / Profile / Account",
    purpose="Returns the full registration/business record for the signed-in account (contact details, GSTIN, owner/ID-proof info, login email).",
    endpoint="/account/info", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="None.",
    validation_rules="None (read-only).",
    success_response="`200` — `status: true`, `data` with `account_code`, `account_name`, `account_email`, `phone`, `address`, `city`, `state`, `zip`, `gstin`, `account_photo_url`, `owner_name`, `designation`, `id_proof_type`, `id_proof_number`, `id_proof_document_url`, `login_email`.",
    error_responses="`401` — expired/invalid token.",
    sample_request="""GET /account/info
Authorization: Bearer <access_token>""",
    sample_success="""{
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
}""",
    sample_error="""{
  "status": false,
  "message": "We couldn't load your account info right now."
}""",
    status_codes=status_rows(),
    business_rules="- This is a single record per account (created at Registration, API_004) — there is no create/delete for it, only fetch (this) and update (API_012).",
    notes="`account_code`, `account_email`, `id_proof_type`, `id_proof_number`, `id_proof_document_url`, `login_email` are returned but are **read-only** — see API_012 for exactly which subset of these fields can be changed by the user.")

add(id="API_012", name="Update Account Info", module="App / Profile / Account",
    purpose="Updates the small subset of Account Info fields the user is allowed to edit, optionally replacing or removing the account photo/logo.",
    endpoint="/account/info", method="POST",
    auth=AUTH_BEARER,
    headers="`Content-Type: application/json` when no photo is attached and `remove_account_photo` is false; `Content-Type: multipart/form-data` when a photo is attached or being removed (non-string fields are JSON-encoded per multipart part).",
    path_params="None.", query_params="None.",
    request_body="""| Field | Type | Required | Editable? |
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

Every other Account Info field (account code, login email, owner name, ID proof type/number/document) is **read-only** and must never be included in this payload.""",
    validation_rules="- Only the editable fields listed above may be sent; the client never includes read-only fields in the payload.\n- `account_photo` and `remove_account_photo` are mutually exclusive in intent (uploading a new photo supersedes removal).\n- `platform` is resolved automatically, not user-entered.",
    success_response="`200` — `status: true`, `data.saved` (bool, defaults to `true` if the field is absent).",
    error_responses="`400`/`422` — invalid field value (e.g. malformed pincode/GSTIN).",
    sample_request="""POST /account/info
Content-Type: multipart/form-data; boundary=...

phone=9876500000
address=221B, Residency Road
pincode=560025
full_name=Ananya Rao
designation=Founder
gstin=29ABCDE1234F1Z5
platform=android
account_photo=<binary>""",
    sample_success="""{
  "status": true,
  "message": "Account info updated successfully",
  "data": { "saved": true }
}""",
    sample_error="""{
  "status": false,
  "message": "Failed to update account info"
}""",
    status_codes=status_rows(),
    business_rules="- City/State are never sent directly by the client — they travel along with (are derived from) `pincode` server-side.",
    notes="Uses `POST` for an update (not `PUT`) — consistent with every other mutation endpoint in this app, since `DioClient` does not expose `PATCH`.")

add(id="API_013", name="Delete Account", module="App / Profile / Account",
    purpose="Permanently deletes the signed-in user's account.",
    endpoint="/user/delete-account", method="POST",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="None documented — client sends no body.",
    validation_rules="None beyond a valid Authorization header. (Recommend backend require a confirmation step, e.g. password re-entry, not currently modeled in the client request.)",
    success_response="`200` — `status: true`, `data.message`.",
    error_responses="`4xx` — `status: false`, `message: \"<reason>\"`.",
    sample_request="""POST /user/delete-account
Authorization: Bearer <access_token>""",
    sample_success="""{
  "status": true,
  "message": "Account deleted successfully",
  "data": { "message": "Account deleted successfully" }
}""",
    sample_error="""{
  "status": false,
  "message": "<reason>"
}""",
    status_codes=status_rows(),
    business_rules="- Irreversible — the client immediately clears the local session on success and returns to Login.",
    notes="**Backend status: not yet implemented at time of writing.** Written against the same contract shape as Logout (API_003); resolves from local mock JSON in mock mode until the real endpoint ships.")

add(id="API_014", name="Get Referral Invite Link", module="App / Profile / Account",
    purpose="Generates/returns the current account's referral invite link for sharing.",
    endpoint="/referrals/invite-link", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="None.",
    validation_rules="None (read-only).",
    success_response="`200` — `status: true`, `data.invite_url`.",
    error_responses="`401` — invalid/expired token.",
    sample_request="""GET /referrals/invite-link
Authorization: Bearer <access_token>""",
    sample_success="""{
  "status": true,
  "message": "OK",
  "data": { "invite_url": "https://app.tbh.com/i/X7Kd92PmLq" }
}""",
    sample_error="""{
  "status": false,
  "message": "Could not generate invite link"
}""",
    status_codes=status_rows(),
    business_rules="- The client never generates or guesses this URL itself — it is entirely backend-owned and opaque.",
    notes="Consumed on the Registration side by `invite_token` handling in API_004 — the two are the entry/exit points of the same referral loop.")

# ============================================================
# MODULE: DASHBOARD
# ============================================================

add(id="API_015", name="Fetch Admin Dashboard", module="Dashboard",
    purpose="Returns the full Admin Dashboard payload (summary metrics, breakdowns) for the signed-in account.",
    endpoint="/dashboard", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None currently sent by the client (dashboard is account-scoped via the auth token).",
    request_body="None.",
    validation_rules="None (read-only).",
    success_response="`200` — `status: true` with the full `DashboardResponse` payload (see `dashboard_models.dart` for the nested schema — revenue/expense summaries, top performers, etc.).",
    error_responses="Any non-200 or `status:false` — client shows a generic \"failed to load\" state.",
    sample_request="""GET /dashboard
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { /* dashboard summary payload — see dashboard_admin_response.json fixture */ } }',
    sample_error='{ "status": false, "message": "<reason>" }',
    status_codes=status_rows(),
    business_rules="- Scoped implicitly to the caller's account/branch via the auth token — no explicit org/branch parameter is sent.",
    notes="**Implementation inconsistency to flag:** this method uses a hand-rolled `try/catch` + manual `Env.isMock` branch rather than the shared `callApi` helper every newer endpoint in this app uses — behavior is equivalent, but it's the older pattern (see API_016's sibling method in the same file, which shares this style).")

add(id="API_016", name="Fetch Revenue Trend", module="Dashboard",
    purpose="Returns a cursor-paginated revenue trend series (for the dashboard's trend chart), one page at a time in either direction.",
    endpoint="/dashboard/revenue-trend", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.",
    query_params="""| Param | Type | Required | Notes |
|---|---|---|---|
| `period` | string | Yes | Lower-cased before sending, e.g. `monthly`, `weekly`. |
| `cursor` | string | No | Pagination cursor from a previous page's `nextCursor`/`prevCursor`. |""",
    request_body="None.",
    validation_rules="- `period` required.\n- `cursor` optional — omitted entirely from the query string when null (not sent as an empty value).",
    success_response="`200` — `status: true`, `data.overviewTrend` containing `period`, `limit`, `hasMoreData`, `range`, `points[]` (`key`, `label`, `value`), `prevCursor`, `nextCursor`.",
    error_responses="Non-200 or `status:false` → client surfaces \"Failed to load revenue trend\".",
    sample_request="""GET /dashboard/revenue-trend?period=monthly&cursor=2025-08
Authorization: Bearer <access_token>""",
    sample_success="""{
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
}""",
    sample_error='{ "status": false, "message": "Failed to load revenue trend" }',
    status_codes=status_rows(),
    business_rules="- `nextCursor`/`prevCursor` being `null` signals the respective end of the series to the client.",
    notes="Same older hand-rolled try/catch pattern as API_015 (not the shared `callApi` helper).")

add(id="API_017", name="Fetch Dashboard Header", module="Dashboard",
    purpose="Returns the data the sticky Dashboard header needs — org identity, notification count, and a role-appropriate switchable-scope list (Organizations for Super Admin, Branches for Account Admin, a single assigned Branch for Branch Admin/Manager/Employee).",
    endpoint="/dashboard/header", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None — role is inferred server-side from the auth token.",
    request_body="None.",
    validation_rules="None (read-only).",
    success_response="`200` — `status: true`, `data` shaped per the caller's role (see Notes).",
    error_responses="Non-200/`status:false` → \"We couldn't load your dashboard header right now.\"",
    sample_request="""GET /dashboard/header
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { /* fields vary by role — see dashboard_header_*_response.json fixtures per role */ } }',
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load your dashboard header right now." }',
    status_codes=status_rows(),
    business_rules="""- Single endpoint for all five roles (Super Admin, Account Admin, Branch Admin, Manager, Employee) — the backend must return only the fields relevant to the caller's role, inferred from the auth token, rather than requiring five separate endpoints.""",
    notes="Client-side, the mock fixture varies by role for local testing (`dashboard_header_super_admin_response.json`, `..._account_admin_...`, `..._branch_admin_...`, `..._manager_...`, `..._employee_...`); the live endpoint is a single fixed path regardless of role.")

# ============================================================
# MODULE: FIRMS
# ============================================================

add(id="API_018", name="Create Firm", module="Firms",
    purpose="Creates a new Firm under the account, with logo and photo uploads.",
    endpoint="/create-firm", method="POST",
    auth=AUTH_BEARER, headers=HEADERS_MULTIPART,
    path_params="None.", query_params="None.",
    request_body="""| Field | Type | Required |
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
| `firm_photo` | file | Yes |""",
    validation_rules="- Every field listed is required by the client — both `firm_logo` and `firm_photo` are mandatory file uploads (unlike Branch/Service/Staff logos/photos elsewhere in the app, which are optional).",
    success_response="`200` — `status: true` (boolean success signal; no structured `data` payload beyond the envelope).",
    error_responses="Non-200 or `status:false` → `message` surfaced as-is to the user.",
    sample_request="""POST /create-firm
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
firm_photo=<binary>""",
    sample_success='{ "status": true, "message": "Firm created successfully" }',
    sample_error='{ "status": false, "message": "<reason>" }',
    status_codes=status_rows(),
    business_rules="- A Firm is a top-level entity distinct from a Branch (API_021–024) — Firm-level dashboards (API_019/020) aggregate revenue/transactions/staff/services across the firm.",
    notes="**Implementation inconsistency to flag:** this method still uses a hand-rolled `try/catch` and is **not** routed through the shared `callApi` helper — i.e. it never goes through the mock branch other endpoints use, meaning in mock mode this call attempts a real network request. This is the same class of gap that was fixed for `BranchesApi.createBranch`/`updateBranch` (see API_023/024's Notes) but not yet applied here.")

add(id="API_019", name="Fetch Firms", module="Firms",
    purpose="Returns the list of Firms under the account with summary metrics (revenue, transaction count, percent change) plus report metadata (currency, available periods, counts).",
    endpoint="/firms", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None currently sent.",
    request_body="None.",
    validation_rules="None (read-only).",
    success_response="`200` — `status: true`, `data.meta` (`currency`, `periods[]`, `counts.totalFirms`), `data.firms[]` (`id`, `name`, `description`, `revenue`, `transactions`, `percent`).",
    error_responses='Non-200/`status:false` → client surfaces "Failed to load firms".',
    sample_request="""GET /firms
Authorization: Bearer <access_token>""",
    sample_success="""{
  "status": true,
  "data": {
    "meta": { "currency": "INR", "periods": ["Daily", "Weekly", "Monthly", "Yearly"], "counts": { "totalFirms": 4 } },
    "firms": [
      { "id": 1, "name": "Beauty Hub Downtown", "description": "BH-Downtown", "revenue": 2850, "transactions": 23, "percent": 12.5 }
    ]
  }
}""",
    sample_error='{ "status": false, "message": "Failed to load firms" }',
    status_codes=status_rows(),
    business_rules="- `percent` can be negative (period-over-period decline) — client renders it as-is, no clamping.",
    notes="Same hand-rolled try/catch pattern as API_018/020 (not the shared `callApi` helper) — flagged as a candidate for future refactor to match the newer API classes' pattern.")

add(id="API_020", name="Fetch Firm Detail", module="Firms",
    purpose="Returns a single Firm's full detail: firm info, a revenue trend series, and its Staff and Services breakdowns.",
    endpoint="/firms/{firmId}/details", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`firmId` (integer, path) — the Firm's id, from API_019's list.",
    query_params="None currently sent.",
    request_body="None.",
    validation_rules="- `firmId` must reference an existing Firm belonging to the caller's account.",
    success_response="`200` — `status: true`, `data.meta.firmInfo` (id, name, description, revenue, transactions, percent, gstin, regNo, email, contact), `data.overviewTrend` (period, limit, hasMoreData, range, points[], prevCursor, nextCursor), `data.firms[]` (sibling firms for comparison), `data.staff[]`, `data.services[]`.",
    error_responses="`404` — firm id not found / not owned by the caller's account.",
    sample_request="""GET /firms/1/details
Authorization: Bearer <access_token>""",
    sample_success="""{
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
}""",
    sample_error='{ "status": false, "message": "Failed to load firm details" }',
    status_codes=status_rows(),
    business_rules="- `data.firms[]` here appears to be a broader/sibling-firm comparison list rather than a subset of this one firm — backend should confirm the intended scope of this array within the detail response.",
    notes="Same hand-rolled try/catch pattern as API_018/019.")

# ============================================================
# MODULE: BRANCHES
# ============================================================

add(id="API_021", name="Fetch Branches", module="Branches",
    purpose="Returns the list of Branches under the account for the Branches list screen.",
    endpoint="/branches", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="None.", validation_rules="None (read-only).",
    success_response="`200` — `status: true`, `data.branches[]` (`id`, `name`, `address`, `city`, `state`, `mobile`, `branch_type`, `status`, `logo`).",
    error_responses="\"We couldn't load branches right now.\" on failure.",
    sample_request="""GET /branches
Authorization: Bearer <access_token>""",
    sample_success="""{
  "status": true,
  "message": "Branches fetched successfully",
  "data": {
    "branches": [
      { "id": 1, "name": "MG Road Branch", "address": "2nd Floor, Prestige Arcade, MG Road", "city": "Bengaluru", "state": "Karnataka", "mobile": "9876543210", "branch_type": "Unisex", "status": "Active", "logo": "https://i.pravatar.cc/150?img=12" }
    ]
  }
}""",
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load branches right now." }',
    status_codes=status_rows(),
    business_rules="- `branch_type` is one of a fixed set (`Unisex`/`Male`/`Female` observed in fixtures) — backend should confirm the authoritative enum.\n- `status` (`Active`/`Inactive`) drives list-screen filtering/display client-side.",
    notes="Uses the shared `callApi` helper (current preferred pattern).")

add(id="API_022", name="Fetch Branch Detail", module="Branches",
    purpose="Returns full detail for a single Branch, including geolocation, hours, assigned services, and assigned employees.",
    endpoint="/branches/{branchId}/details", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`branchId` (integer, path).", query_params="None.",
    request_body="None.", validation_rules="- `branchId` must reference an existing Branch owned by the caller's account.",
    success_response="`200` — `status: true`, `data` with `id`, `name`, `address_line1`, `address_line2`, `city`, `state`, `pincode`, `latitude`, `longitude`, `maps_link`, `mobile`, `email`, `branch_type`, `opening_time`, `closing_time`, `weekly_off`, `status`, `logo`, `services[]` (`id`, `name`), `employees[]` (`id`, `name`, `role`, `photo`).",
    error_responses="`404` — branch id not found / not owned by caller.",
    sample_request="""GET /branches/1/details
Authorization: Bearer <access_token>""",
    sample_success="""{
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
}""",
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load this branch'+chr(39)+'s details." }',
    status_codes=status_rows(),
    business_rules="- `weekly_off` is a single day name — backend should confirm whether multiple weekly-off days are ever supported (client currently models one).",
    notes="Uses the shared `callApi` helper.")

add(id="API_023", name="Create Branch", module="Branches",
    purpose="Creates a new Branch, with an optional logo upload.",
    endpoint="/branches", method="POST",
    auth=AUTH_BEARER,
    headers="`multipart/form-data` when `logo` is attached, otherwise plain JSON.",
    path_params="None.", query_params="None.",
    request_body="""Branch fields (name, address, city, state, pincode, mobile, email, branch_type, opening_time, closing_time, weekly_off, service ids, etc. — exact set defined by the Branch form, not fully enumerated in the API layer itself) plus:

| Field | Type | Required |
|---|---|---|
| `logo` | file | No |""",
    validation_rules="- Payload validation is owned by the Branch form (client-side); server should independently validate required Branch fields (name, address, city, state, mobile at minimum, per the detail shape in API_022).",
    success_response="`200` — `status: true`, `data.saved` (bool).",
    error_responses="\"Failed to create branch\" on failure.",
    sample_request="""POST /branches
Content-Type: multipart/form-data; boundary=...

name=MG Road Branch
address=2nd Floor, Prestige Arcade, MG Road
city=Bengaluru
state=Karnataka
mobile=9876543210
branch_type=Unisex
logo=<binary>""",
    sample_success='{ "status": true, "message": "Branch saved successfully", "data": { "saved": true } }',
    sample_error='{ "status": false, "message": "Failed to create branch" }',
    status_codes=status_rows(),
    business_rules="- Create and Update (API_024) share the same mock/live response fixture (`branch_save_response.json`) and the same `saved: true` contract.",
    notes="**Bug-fix context (leave as-is, informational):** this method previously bypassed the shared `callApi` helper by calling the HTTP client directly in its own try/catch, which meant it never went through the mock branch in mock/dev builds and instead attempted a real network call — this was the confirmed root cause of a previously reported Create/Update Branch failure. It has since been routed through `callApi` like every other endpoint; no further action needed here, noted for backend/QA context only.")

add(id="API_024", name="Update Branch", module="Branches",
    purpose="Updates an existing Branch, optionally replacing or removing its logo.",
    endpoint="/branches/{branchId}", method="POST",
    auth=AUTH_BEARER,
    headers="`multipart/form-data` when `logo` is attached or being removed, otherwise plain JSON.",
    path_params="`branchId` (integer, path).",
    query_params="None.",
    request_body="""Same editable Branch fields as Create (API_023), plus:

| Field | Type | Required |
|---|---|---|
| `logo` | file | No |
| `remove_logo` | "true"/omitted | No |""",
    validation_rules="Same as Create (API_023).",
    success_response="`200` — `status: true`, `data.saved` (bool).",
    error_responses="\"Failed to update branch\" on failure.",
    sample_request="""POST /branches/1
Content-Type: multipart/form-data; boundary=...

name=MG Road Branch
remove_logo=true""",
    sample_success='{ "status": true, "message": "Branch saved successfully", "data": { "saved": true } }',
    sample_error='{ "status": false, "message": "Failed to update branch" }',
    status_codes=status_rows(),
    business_rules="- `remove_logo=true` clears the existing logo without requiring a new file.",
    notes="`PUT` was considered but not used — `DioClient` only exposes `GET`/`POST` for the branch/logo-upload pattern's original implementation, so update is modeled as `POST` to the resource path, matching every other mutation endpoint in the app except Transactions (API_051), which is the one place `PUT` was later introduced.")

# ============================================================
# MODULE: SERVICES
# ============================================================

def crud_block(entity_singular, entity_plural, id_field, list_endpoint, list_field_desc,
               detail_endpoint, detail_field_desc, create_endpoint, update_endpoint, delete_endpoint,
               module, id_prefix, has_photo=True, has_catalog=True, catalog_endpoint=None, catalog_field="active"):
    pass  # not used; entries written explicitly below for clarity/accuracy per module

add(id="API_025", name="Fetch Services Catalog", module="Services",
    purpose="Returns the lightweight master Service catalog used by the Branch Create/Edit form's service picker.",
    endpoint="/services", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="None.", validation_rules="None (read-only).",
    success_response="`200` — `status: true`, `data.services[]` (`id`, `name`, `active`).",
    error_responses="\"We couldn't load services right now.\" on failure.",
    sample_request="""GET /services
Authorization: Bearer <access_token>""",
    sample_success="""{
  "status": true,
  "message": "Services fetched successfully",
  "data": { "services": [ { "id": 1, "name": "Haircut", "active": true } ] }
}""",
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load services right now." }',
    status_codes=status_rows(),
    business_rules="- Deliberately kept as a separate, lightweight shape from Service List (API_026) — Service Management changes must never affect the Branch picker's contract.",
    notes="Uses the shared `callApi` helper.")

add(id="API_026", name="Fetch Service List", module="Services",
    purpose="Returns the full Service List screen's data — richer than the catalog (category, pricing, status, photo).",
    endpoint="/services/list", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="None.", validation_rules="None (read-only).",
    success_response="`200` — `status: true`, `data.services[]` with category, pricing, status, photo fields (see `service_list_response.json` fixture / `ServiceListItem` model).",
    error_responses="\"We couldn't load services right now.\" on failure.",
    sample_request="""GET /services/list
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "services": [ { "id": 1, "name": "Haircut", "category": "Hair", "price": 300, "status": "Active" } ] } }',
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load services right now." }',
    status_codes=status_rows(),
    business_rules="- Independent contract from API_025 by design (see API_025's Notes).",
    notes="Uses the shared `callApi` helper.")

add(id="API_027", name="Fetch Service Detail", module="Services",
    purpose="Returns full detail for a single Service.",
    endpoint="/services/{serviceId}/details", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`serviceId` (integer, path).", query_params="None.",
    request_body="None.", validation_rules="- `serviceId` must reference an existing Service owned by the caller's account.",
    success_response="`200` — `status: true`, `data` with full Service fields (see `ServiceDetailResponse` model).",
    error_responses="\"We couldn't load this service's details.\" on failure.",
    sample_request="""GET /services/1/details
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "id": 1, "name": "Haircut", "category": "Hair", "price": 300, "description": "...", "status": "Active", "photo": null, "branch_ids": [1,2] } }',
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load this service'+chr(39)+'s details." }',
    status_codes=status_rows(),
    business_rules="- N/A beyond ownership scoping.",
    notes="Uses the shared `callApi` helper.")

add(id="API_028", name="Create Service", module="Services",
    purpose="Creates a new Service, with an optional photo upload.",
    endpoint="/services", method="POST",
    auth=AUTH_BEARER, headers="`multipart/form-data` when `photo` is attached, otherwise plain JSON.",
    path_params="None.", query_params="None.",
    request_body="""Service fields (name, category, price, description, branch assignment, etc. — owned by the Service form) plus:

| Field | Type | Required |
|---|---|---|
| `photo` | file | No |""",
    validation_rules="- Non-string payload values are JSON-encoded per multipart part when a photo is present (numbers, lists, nulls), since Dio's multipart encoder only accepts `String`/`MultipartFile`.",
    success_response="`200` — `status: true`, `data.saved` (bool).",
    error_responses="\"Failed to create service\" on failure.",
    sample_request="""POST /services
Content-Type: multipart/form-data; boundary=...

name=Haircut
category=Hair
price=300
photo=<binary>""",
    sample_success='{ "status": true, "message": "Service saved successfully", "data": { "saved": true } }',
    sample_error='{ "status": false, "message": "Failed to create service" }',
    status_codes=status_rows(),
    business_rules="- Shares its response fixture/contract with Update (API_029).",
    notes="Uses the shared `callApi` helper (mirrors `BranchesApi`'s `_buildRequestBody` pattern).")

add(id="API_029", name="Update Service", module="Services",
    purpose="Updates an existing Service, optionally replacing or removing its photo.",
    endpoint="/services/{serviceId}", method="POST",
    auth=AUTH_BEARER, headers="`multipart/form-data` when `photo` is attached or being removed, otherwise plain JSON.",
    path_params="`serviceId` (integer, path).", query_params="None.",
    request_body="""Same editable Service fields as Create (API_028), plus:

| Field | Type | Required |
|---|---|---|
| `photo` | file | No |
| `remove_photo` | "true"/omitted | No |""",
    validation_rules="Same as Create (API_028).",
    success_response="`200` — `status: true`, `data.saved` (bool).",
    error_responses="\"Failed to update service\" on failure.",
    sample_request="""POST /services/1
Content-Type: application/json

{ "name": "Haircut", "price": 350 }""",
    sample_success='{ "status": true, "message": "Service saved successfully", "data": { "saved": true } }',
    sample_error='{ "status": false, "message": "Failed to update service" }',
    status_codes=status_rows(),
    business_rules="- `remove_photo=true` clears the photo without a new upload.",
    notes="Uses the shared `callApi` helper.")

add(id="API_030", name="Delete Service", module="Services",
    purpose="Deletes an existing Service.",
    endpoint="/services/{serviceId}/delete", method="POST",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`serviceId` (integer, path).", query_params="None.",
    request_body="None.", validation_rules="- `serviceId` must reference an existing Service owned by the caller's account. Backend should confirm/enforce referential-integrity rules (e.g. a Service in use by existing Transactions/Branches) — not modeled client-side.",
    success_response="`200` — `status: true`, `data.deleted` (bool, defaults `true`).",
    error_responses="\"Failed to delete service\" on failure.",
    sample_request="""POST /services/1/delete
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "message": "Service deleted", "data": { "deleted": true } }',
    sample_error='{ "status": false, "message": "Failed to delete service" }',
    status_codes=status_rows([("409", "Recommended if the backend blocks deletion of a Service still referenced elsewhere (not currently modeled client-side).")]),
    business_rules="- Modeled as `POST .../delete` rather than an HTTP `DELETE`, consistent with every other delete in this app except the Notifications module (API_071/072), which does use `DELETE`.",
    notes="Uses the shared `callApi` helper.")

# ============================================================
# MODULE: STAFF
# ============================================================

add(id="API_031", name="Fetch Staff Form Config", module="Staff",
    purpose="Returns Branch list + Salary Rule list + Specialist list in a single call, so the Staff Add/Edit form's three dropdowns load in one round trip instead of three.",
    endpoint="/staff/form-config", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="None.", validation_rules="None (read-only).",
    success_response="`200` — `status: true`, `data` with branch list, salary-rule list, and specialist list (see `StaffFormConfig` model).",
    error_responses="\"We couldn't load form options right now.\" on failure.",
    sample_request="""GET /staff/form-config
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "branches": [ { "id": 1, "name": "MG Road Branch" } ], "salary_rules": [ { "id": 1, "name": "Standard" } ], "specialists": [ "Haircut", "Facial" ] } }',
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load form options right now." }',
    status_codes=status_rows(),
    business_rules="- Exists specifically to avoid three separate lookups on form open — backend should keep this as one combined response rather than splitting it back into per-entity calls.",
    notes="Uses the shared `callApi` helper.")

add(id="API_032", name="Fetch Staff List", module="Staff",
    purpose="Returns the full Staff List screen's data.",
    endpoint="/staff/list", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="None.", validation_rules="None (read-only).",
    success_response="`200` — `status: true`, `data.staff[]` (see `StaffListItem` model).",
    error_responses="\"We couldn't load staff right now.\" on failure.",
    sample_request="""GET /staff/list
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "staff": [ { "id": 101, "name": "Ritu Sharma", "role": "Branch Manager", "branch_name": "MG Road Branch", "status": "Active" } ] } }',
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load staff right now." }',
    status_codes=status_rows(),
    business_rules="N/A.",
    notes="Uses the shared `callApi` helper.")

add(id="API_033", name="Fetch Staff Detail", module="Staff",
    purpose="Returns full detail for a single Staff member.",
    endpoint="/staff/{staffId}/details", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`staffId` (integer, path).", query_params="None.",
    request_body="None.", validation_rules="- `staffId` must reference an existing Staff member owned by the caller's account.",
    success_response="`200` — `status: true`, `data` with full Staff fields (see `StaffDetailResponse` model — likely includes employee code, salary rule, branch, Aadhaar, photo).",
    error_responses="\"We couldn't load this staff member's details.\" on failure.",
    sample_request="""GET /staff/101/details
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "id": 101, "name": "Ritu Sharma", "employee_code": "EMP-0101", "role": "Branch Manager", "branch_id": 1, "salary_rule_id": 1, "photo": null, "aadhaar_card": null } }',
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load this staff member'+chr(39)+'s details." }',
    status_codes=status_rows(),
    business_rules="N/A beyond ownership scoping.",
    notes="Uses the shared `callApi` helper.")

add(id="API_034", name="Fetch Next Employee Code", module="Staff",
    purpose="Returns a backend-suggested next Employee Code for a brand-new Staff member, if the backend supports auto-generation.",
    endpoint="/staff/next-employee-code", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="None.", validation_rules="None (read-only).",
    success_response="`200` — `status: true`, `data.employee_code` (string).",
    error_responses="Treated as \"not supported\" — see Business Rules; no user-facing error is shown for a failure here.",
    sample_request="""GET /staff/next-employee-code
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "employee_code": "EMP-0102" } }',
    sample_error='{ "status": false, "message": "" }',
    status_codes=status_rows(),
    business_rules="- If this call fails or returns empty, the Add Staff form simply leaves Employee Code blank and manually editable — it never blocks the form on this call. Backend is free to not implement true auto-generation; an empty/absent `employee_code` is a fully valid response.",
    notes="Uses the shared `callApi` helper with an intentionally empty `fallbackErrorMessage` (silent failure by design).")

add(id="API_035", name="Create Staff", module="Staff",
    purpose="Creates a new Staff member, with optional profile photo and Aadhaar card uploads.",
    endpoint="/staff", method="POST",
    auth=AUTH_BEARER, headers="`multipart/form-data` when `photo` and/or `aadhaarCard` are attached, otherwise plain JSON.",
    path_params="None.", query_params="None.",
    request_body="""Staff fields (name, employee code, role, branch, salary rule, contact, etc. — owned by the Staff form) plus:

| Field | Type | Required |
|---|---|---|
| `photo` | file | No |
| `aadhaar_card` | file | No |""",
    validation_rules="- Non-string payload values are JSON-encoded per multipart part when at least one file is present.",
    success_response="`200` — `status: true`, `data.saved` (bool).",
    error_responses="\"Failed to add staff member\" on failure.",
    sample_request="""POST /staff
Content-Type: multipart/form-data; boundary=...

name=Ritu Sharma
employee_code=EMP-0101
branch_id=1
salary_rule_id=1
photo=<binary>
aadhaar_card=<binary>""",
    sample_success='{ "status": true, "message": "Staff saved successfully", "data": { "saved": true } }',
    sample_error='{ "status": false, "message": "Failed to add staff member" }',
    status_codes=status_rows(),
    business_rules="- Shares its response fixture/contract with Update (API_036).",
    notes="Uses the shared `callApi` helper.")

add(id="API_036", name="Update Staff", module="Staff",
    purpose="Updates an existing Staff member, optionally replacing or removing photo and/or Aadhaar card.",
    endpoint="/staff/{staffId}", method="POST",
    auth=AUTH_BEARER, headers="`multipart/form-data` when a file is attached or being removed, otherwise plain JSON.",
    path_params="`staffId` (integer, path).", query_params="None.",
    request_body="""Same editable Staff fields as Create (API_035), plus:

| Field | Type | Required |
|---|---|---|
| `photo` | file | No |
| `aadhaar_card` | file | No |
| `remove_photo` | "true"/omitted | No |
| `remove_aadhaar_card` | "true"/omitted | No |""",
    validation_rules="Same as Create (API_035).",
    success_response="`200` — `status: true`, `data.saved` (bool).",
    error_responses="\"Failed to update staff member\" on failure.",
    sample_request="""POST /staff/101
Content-Type: application/json

{ "name": "Ritu Sharma", "branch_id": 2 }""",
    sample_success='{ "status": true, "message": "Staff saved successfully", "data": { "saved": true } }',
    sample_error='{ "status": false, "message": "Failed to update staff member" }',
    status_codes=status_rows(),
    business_rules="- `remove_photo`/`remove_aadhaar_card` each independently clear that file without requiring a new upload.",
    notes="Uses the shared `callApi` helper.")

add(id="API_037", name="Delete Staff", module="Staff",
    purpose="Deletes an existing Staff member.",
    endpoint="/staff/{staffId}/delete", method="POST",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`staffId` (integer, path).", query_params="None.",
    request_body="None.", validation_rules="- `staffId` must reference an existing Staff member owned by the caller's account.",
    success_response="`200` — `status: true`, `data.deleted` (bool, defaults `true`).",
    error_responses="\"Failed to delete staff member\" on failure.",
    sample_request="""POST /staff/101/delete
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "message": "Staff deleted", "data": { "deleted": true } }',
    sample_error='{ "status": false, "message": "Failed to delete staff member" }',
    status_codes=status_rows([("409", "Recommended if the backend blocks deletion of a Staff member with existing Transactions (not currently modeled client-side).")]),
    business_rules="N/A beyond referential-integrity considerations noted above.",
    notes="Uses the shared `callApi` helper.")

# ============================================================
# MODULE: SALARY RULES
# ============================================================

add(id="API_038", name="Fetch Salary Rules Catalog", module="Salary Rules",
    purpose="Returns the lightweight Salary Rule list used by the Staff form's Salary Rule picker.",
    endpoint="/salary-rules", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="None.", validation_rules="None (read-only).",
    success_response="`200` — `status: true`, `data.salary_rules[]` (lightweight `SalaryRuleModel` shape — id, name).",
    error_responses="\"We couldn't load salary rules right now.\" on failure.",
    sample_request="""GET /salary-rules
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "salary_rules": [ { "id": 1, "name": "Standard Commission" } ] } }',
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load salary rules right now." }',
    status_codes=status_rows(),
    business_rules="- Kept as a separate, lightweight contract from Salary Rule List (API_039) — same separation-of-concerns pattern as Services (API_025 vs API_026).",
    notes="Uses the shared `callApi` helper.")

add(id="API_039", name="Fetch Salary Rule List", module="Salary Rules",
    purpose="Returns the full Salary Rule Management list screen's data.",
    endpoint="/salary-rules/list", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="None.", validation_rules="None (read-only).",
    success_response="`200` — `status: true`, `data.salary_rules[]` (richer `SalaryRuleListItem` shape).",
    error_responses="\"We couldn't load salary rules right now.\" on failure.",
    sample_request="""GET /salary-rules/list
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "salary_rules": [ { "id": 1, "name": "Standard Commission", "type": "Percentage", "value": 10, "status": "Active" } ] } }',
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load salary rules right now." }',
    status_codes=status_rows(),
    business_rules="N/A.", notes="Uses the shared `callApi` helper.")

add(id="API_040", name="Fetch Salary Rule Detail", module="Salary Rules",
    purpose="Returns full detail for a single Salary Rule.",
    endpoint="/salary-rules/{ruleId}/details", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`ruleId` (integer, path).", query_params="None.",
    request_body="None.", validation_rules="- `ruleId` must reference an existing Salary Rule owned by the caller's account.",
    success_response="`200` — `status: true`, `data` with full Salary Rule fields (see `SalaryRuleDetailResponse` model).",
    error_responses="\"We couldn't load this salary rule's details.\" on failure.",
    sample_request="""GET /salary-rules/1/details
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "id": 1, "name": "Standard Commission", "type": "Percentage", "value": 10, "applies_to": "all_services" } }',
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load this salary rule'+chr(39)+'s details." }',
    status_codes=status_rows(),
    business_rules="N/A.", notes="Uses the shared `callApi` helper.")

add(id="API_041", name="Create Salary Rule", module="Salary Rules",
    purpose="Creates a new Salary Rule.",
    endpoint="/salary-rules", method="POST",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="Salary Rule fields (name, type, value, applicability, etc. — owned by the Salary Rules form; plain JSON, no file upload involved for this module).",
    validation_rules="- Numeric fields (e.g. rate/value) should be non-negative and, where the field represents a required amount, greater than zero — enforced client-side today via `NumericFieldValidators` (see `core/validators/numeric_field_validators.dart`); backend should apply equivalent server-side checks.",
    success_response="`200` — `status: true`, `data.saved` (bool).",
    error_responses="\"Failed to create salary rule\" on failure.",
    sample_request="""POST /salary-rules
Content-Type: application/json

{ "name": "Standard Commission", "type": "Percentage", "value": 10 }""",
    sample_success='{ "status": true, "message": "Salary rule saved successfully", "data": { "saved": true } }',
    sample_error='{ "status": false, "message": "Failed to create salary rule" }',
    status_codes=status_rows(),
    business_rules="- Shares its response fixture/contract with Update (API_042).",
    notes="Unlike Branches/Services/Staff, Salary Rules involves no file upload — this is always a plain JSON `POST`. Uses the shared `callApi` helper.")

add(id="API_042", name="Update Salary Rule", module="Salary Rules",
    purpose="Updates an existing Salary Rule.",
    endpoint="/salary-rules/{ruleId}", method="POST",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`ruleId` (integer, path).", query_params="None.",
    request_body="Same editable Salary Rule fields as Create (API_041).",
    validation_rules="Same as Create (API_041).",
    success_response="`200` — `status: true`, `data.saved` (bool).",
    error_responses="\"Failed to update salary rule\" on failure.",
    sample_request="""POST /salary-rules/1
Content-Type: application/json

{ "name": "Standard Commission", "value": 12 }""",
    sample_success='{ "status": true, "message": "Salary rule saved successfully", "data": { "saved": true } }',
    sample_error='{ "status": false, "message": "Failed to update salary rule" }',
    status_codes=status_rows(),
    business_rules="N/A.", notes="Uses the shared `callApi` helper.")

add(id="API_043", name="Delete Salary Rule", module="Salary Rules",
    purpose="Deletes an existing Salary Rule.",
    endpoint="/salary-rules/{ruleId}/delete", method="POST",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`ruleId` (integer, path).", query_params="None.",
    request_body="None.", validation_rules="- `ruleId` must reference an existing Salary Rule owned by the caller's account.",
    success_response="`200` — `status: true`, `data.deleted` (bool, defaults `true`).",
    error_responses="\"Failed to delete salary rule\" on failure.",
    sample_request="""POST /salary-rules/1/delete
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "message": "Salary rule deleted", "data": { "deleted": true } }',
    sample_error='{ "status": false, "message": "Failed to delete salary rule" }',
    status_codes=status_rows([("409", "Recommended if the backend blocks deletion of a Salary Rule still assigned to Staff (not currently modeled client-side).")]),
    business_rules="N/A beyond referential-integrity considerations noted above.",
    notes="Uses the shared `callApi` helper.")

# ============================================================
# MODULE: EXPENSES
# ============================================================

add(id="API_044", name="Fetch Expense List", module="Expenses",
    purpose="Returns the full Expense (Types) Management list screen's data.",
    endpoint="/expenses/list", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="None.", validation_rules="None (read-only).",
    success_response="`200` — `status: true`, `data.expenses[]` (see `ExpenseListItem` model).",
    error_responses="\"We couldn't load expenses right now.\" on failure.",
    sample_request="""GET /expenses/list
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "expenses": [ { "id": 1, "name": "Rent", "branch_name": "MG Road Branch", "status": "Active" } ] } }',
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load expenses right now." }',
    status_codes=status_rows(), business_rules="N/A.",
    notes="Uses the shared `callApi` helper.")

add(id="API_045", name="Fetch Expense Detail", module="Expenses",
    purpose="Returns full detail for a single Expense type.",
    endpoint="/expenses/{expenseId}/details", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`expenseId` (integer, path).", query_params="None.",
    request_body="None.", validation_rules="- `expenseId` must reference an existing Expense type owned by the caller's account.",
    success_response="`200` — `status: true`, `data` with full Expense fields (name, description, branch assignment — see `ExpenseDetailResponse` model).",
    error_responses="\"We couldn't load this expense's details.\" on failure.",
    sample_request="""GET /expenses/1/details
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "id": 1, "name": "Rent", "description": "Monthly branch rent", "branch_ids": [1] } }',
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load this expense'+chr(39)+'s details." }',
    status_codes=status_rows(), business_rules="N/A.",
    notes="Uses the shared `callApi` helper.")

add(id="API_046", name="Create Expense", module="Expenses",
    purpose="Creates a new Expense type.",
    endpoint="/expenses", method="POST",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="""| Field | Type | Required |
|---|---|---|
| `name` | string | Yes |
| `description` | string | No |
| `branch_ids` | array\\<int\\> | Yes (branch assignment) |""",
    validation_rules="- `name` required.\n- No file upload for this module — always a plain JSON payload.",
    success_response="`200` — `status: true`, `data.saved` (bool).",
    error_responses="\"Failed to add expense\" on failure.",
    sample_request="""POST /expenses
Content-Type: application/json

{ "name": "Rent", "description": "Monthly branch rent", "branch_ids": [1] }""",
    sample_success='{ "status": true, "message": "Expense saved successfully", "data": { "saved": true } }',
    sample_error='{ "status": false, "message": "Failed to add expense" }',
    status_codes=status_rows(), business_rules="- Shares its response fixture/contract with Update (API_047).",
    notes="Uses the shared `callApi` helper. Configuration-only screen — no photo/document upload involved, unlike Branches/Services/Staff.")

add(id="API_047", name="Update Expense", module="Expenses",
    purpose="Updates an existing Expense type.",
    endpoint="/expenses/{expenseId}", method="POST",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`expenseId` (integer, path).", query_params="None.",
    request_body="Same editable Expense fields as Create (API_046).",
    validation_rules="Same as Create (API_046).",
    success_response="`200` — `status: true`, `data.saved` (bool).",
    error_responses="\"Failed to update expense\" on failure.",
    sample_request="""POST /expenses/1
Content-Type: application/json

{ "name": "Rent", "branch_ids": [1, 2] }""",
    sample_success='{ "status": true, "message": "Expense saved successfully", "data": { "saved": true } }',
    sample_error='{ "status": false, "message": "Failed to update expense" }',
    status_codes=status_rows(), business_rules="N/A.",
    notes="Uses the shared `callApi` helper.")

add(id="API_048", name="Delete Expense", module="Expenses",
    purpose="Deletes an existing Expense type.",
    endpoint="/expenses/{expenseId}/delete", method="POST",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`expenseId` (integer, path).", query_params="None.",
    request_body="None.", validation_rules="- `expenseId` must reference an existing Expense type owned by the caller's account.",
    success_response="`200` — `status: true`, `data.deleted` (bool, defaults `true`).",
    error_responses="\"Failed to delete expense\" on failure.",
    sample_request="""POST /expenses/1/delete
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "message": "Expense deleted", "data": { "deleted": true } }',
    sample_error='{ "status": false, "message": "Failed to delete expense" }',
    status_codes=status_rows([("409", "Recommended if the backend blocks deletion of an Expense type referenced by existing Transactions (not currently modeled client-side).")]),
    business_rules="N/A beyond referential-integrity considerations noted above.",
    notes="Uses the shared `callApi` helper.")

# ============================================================
# MODULE: TRANSACTIONS
# ============================================================

add(id="API_049", name="Fetch Transaction Bootstrap", module="Transactions",
    purpose="Returns everything the Transaction Entry screen needs in one call — services, expenses, staff, branches, the caller's role, and last-used preferences.",
    endpoint="/transactions/bootstrap", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="None.", validation_rules="None (read-only).",
    success_response="`200` — `status: true`, `data` with `services[]`, `expenses[]`, `staff[]`, `branches[]`, `role`, last-used preferences (see `TransactionBootstrapData` model).",
    error_responses="\"We couldn't load transaction data right now.\" on failure.",
    sample_request="""GET /transactions/bootstrap
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "services": [], "expenses": [], "staff": [], "branches": [], "role": "employee", "last_used": { "branch_id": 1 } } }',
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load transaction data right now." }',
    status_codes=status_rows(),
    business_rules="- Fetched exactly once per screen-open — never re-fetched on every quantity/service change within the same session on that screen (client-side performance requirement; backend should not expect repeated calls per keystroke/selection).",
    notes="Uses the shared `callApi` helper.")

add(id="API_050", name="Create Transaction", module="Transactions",
    purpose="Creates a new Transaction (sale/entry) record.",
    endpoint="/transactions", method="POST",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="""Transaction fields (line items, staff, branch, payment mode, totals, etc. — owned by the Transaction Entry form) plus:

| Field | Type | Required |
|---|---|---|
| `idempotency_key` | string | Yes |""",
    validation_rules="- `idempotency_key` is generated once per screen-open by the client and resent unchanged on every retry of the *same* transaction (double-submit, HTTP client auto-retry-on-timeout, crash-and-reopen). **Backend must treat a repeated `idempotency_key` as \"return the original record\", not create a duplicate.**",
    success_response="`200` — `status: true`, `data` with the saved Transaction record (see `TransactionSaveResult` model).",
    error_responses="\"Failed to save transaction\" on failure.",
    sample_request="""POST /transactions
Content-Type: application/json

{
  "idempotency_key": "5f2c9e10-...",
  "branch_id": 1,
  "items": [ { "service_id": 1, "qty": 1, "price": 300 } ],
  "payment_mode": "cash"
}""",
    sample_success='{ "status": true, "data": { "id": "TXN-1001", "status": "paid" } }',
    sample_error='{ "status": false, "message": "Failed to save transaction" }',
    status_codes=status_rows(), business_rules="- See Validation Rules — idempotency is a hard backend requirement for this endpoint, not just a client-side nicety.",
    notes="Uses the shared `callApi` helper.")

add(id="API_051", name="Update Transaction", module="Transactions",
    purpose="Edits an existing Transaction, within a backend-enforced edit window.",
    endpoint="/transactions/{id}", method="PUT",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`id` (string, path) — Transaction id.", query_params="None.",
    request_body="Updated Transaction fields (same shape as Create, API_050, minus `idempotency_key`).",
    validation_rules="- Server must reject the edit with `409` specifically once the edit window has closed since the Edit screen was opened — the client relies on this exact status code to show a distinct \"can no longer be edited\" message rather than a generic save error.",
    success_response="`200` — `status: true`, `data` with the updated Transaction record.",
    error_responses="`409` — edit window closed. Other 4xx/5xx — \"Failed to update transaction\".",
    sample_request="""PUT /transactions/TXN-1001
Content-Type: application/json

{ "items": [ { "service_id": 1, "qty": 2, "price": 300 } ] }""",
    sample_success='{ "status": true, "data": { "id": "TXN-1001", "status": "paid" } }',
    sample_error='{ "status": false, "message": "This transaction can no longer be edited." }',
    status_codes=status_rows([("409", "Edit window has closed since the Edit screen was opened — must be this exact code, the client branches on it specifically.")]),
    business_rules="- This is the only endpoint in the entire client that uses HTTP `PUT` — every other mutation uses `POST`. Backend should implement it as a true `PUT` (idempotent full/partial update), not `POST`.",
    notes="Uses the shared `callApi` helper.")

add(id="API_052", name="Mark Transaction Paid", module="Transactions",
    purpose="Settles a Pending transaction, changing only its status/paid timestamp.",
    endpoint="/transactions/{id}/mark-paid", method="POST",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`id` (string, path) — Transaction id.", query_params="None.",
    request_body="Empty object `{}` — no fields.",
    validation_rules="- Transaction must currently be in `Pending` status; server should reject if already paid/settled.",
    success_response="`200` — `status: true`, `data` with `status`/`paid_at` (see `TransactionMarkPaidResult` model).",
    error_responses="\"Failed to mark transaction as paid\" on failure.",
    sample_request="""POST /transactions/TXN-1001/mark-paid
Content-Type: application/json

{}""",
    sample_success='{ "status": true, "data": { "id": "TXN-1001", "status": "paid", "paid_at": "2026-08-07T10:00:00Z" } }',
    sample_error='{ "status": false, "message": "Failed to mark transaction as paid" }',
    status_codes=status_rows(), business_rules="- Deliberately separate from Update (API_051): never gated by the edit window, since settling a payment is a distinct action from editing line items.",
    notes="Uses the shared `callApi` helper.")

add(id="API_053", name="Fetch Transactions List", module="Transactions",
    purpose="Returns the full Transactions list (no pagination, no filters).",
    endpoint="/transactions", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None currently sent — all filtering/search happens client-side against the full list.",
    request_body="None.", validation_rules="None (read-only).",
    success_response="`200` — `status: true`, full `TransactionsResponse` payload (list of transactions).",
    error_responses="\"Failed to load transactions\" on failure.",
    sample_request="""GET /transactions
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "transactions": [ { "id": "TXN-1001", "status": "paid", "amount": 300 } ] } }',
    sample_error='{ "status": false, "message": "Failed to load transactions" }',
    status_codes=status_rows(),
    business_rules="- **Scalability flag for backend:** this is unpaginated by contract today; recommend backend plan for pagination/filtering support before transaction volume grows, since the client currently loads the entire list on every screen open.",
    notes="Hand-rolled try/catch pattern (not the shared `callApi` helper) — consistent with this file's other list method.")

add(id="API_054", name="Fetch Transaction Details", module="Transactions",
    purpose="Returns full detail for a single Transaction.",
    endpoint="/transactions/{id}", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`id` (string, path) — Transaction id.", query_params="None.",
    request_body="None.", validation_rules="- `id` must reference an existing Transaction owned by the caller's account.",
    success_response="`200` — `status: true`, `data` with full Transaction detail (line items, staff, branch, payment info — see `TransactionDetailsResponse` model).",
    error_responses="\"Failed to load transaction details\" on failure.",
    sample_request="""GET /transactions/TXN-1001
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "id": "TXN-1001", "status": "paid", "items": [ { "service_id": 1, "qty": 1, "price": 300 } ], "branch_id": 1 } }',
    sample_error='{ "status": false, "message": "Failed to load transaction details" }',
    status_codes=status_rows(),
    business_rules="- Always fetched fresh — the Details screen never receives more than the id from the list screen, so this is called independently every time the screen opens (no client-side caching to invalidate).",
    notes="Hand-rolled try/catch pattern (not the shared `callApi` helper).")

# ============================================================
# MODULE: REPORTS
# ============================================================

REPORT_QUERY = """| Param | Type | Required | Notes |
|---|---|---|---|
| `period` | string | Yes | One of the keys the response's own `meta.periods[]` advertises — observed values: `today`, `this_week`, `this_month`, `3m`, `6m`, `12m`, `custom`. |
| `branch_id` | string | No | Defaults to `all`. |
| `start_date` | string (ISO 8601) | No | Only meaningful when `period=custom`. |
| `end_date` | string (ISO 8601) | No | Only meaningful when `period=custom`. |"""

add(id="API_055", name="Fetch P&L Report", module="Reports",
    purpose="Returns the Profit & Loss report for the selected period/branch/date range (Account > Report > P&L).",
    endpoint="/reports/pnl", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params=REPORT_QUERY,
    request_body="None.", validation_rules="- `period` required; if omitted/unrecognized the client's own mock layer falls back to a `3m`-equivalent dataset — the real backend should define its own explicit default rather than relying on client behavior.",
    success_response="`200` — `status: true`, `data` with the P&L report payload (see `PnlReportData` model).",
    error_responses="\"We couldn't load the P&L report right now.\" on failure.",
    sample_request="""GET /reports/pnl?period=this_month&branch_id=all
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "revenue": 50000, "expenses": 12000, "profit": 38000, "period": "this_month" } }',
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load the P'+chr(38)+'L report right now." }',
    status_codes=status_rows(),
    business_rules="- `custom` period requires a real backend to answer an arbitrary date range — not yet supported (client currently mocks this by reusing a fixed dataset).",
    notes="**Backend status: no endpoint currently exists for this report** (per in-code comment) — the client is fully wired against this contract and resolves from local mock JSON per period in mock mode.",
    changelog="v1.0 — Documented against the client's implemented contract; endpoint pending backend implementation.")

add(id="API_056", name="Export P&L Report", module="Reports",
    purpose="Requests a downloadable export (PDF or Excel) of the P&L report.",
    endpoint="/reports/pnl/export", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.",
    query_params="""| Param | Type | Required | Notes |
|---|---|---|---|
| `format` | string | Yes | `pdf` or `excel`. |""",
    request_body="None.", validation_rules="- `format` required, must be one of `pdf`/`excel`.",
    success_response="`200` — `status: true`, `data.pdf_url` or `data.excel_url` (whichever matches the requested `format`) — a downloadable file URL the client simply launches.",
    error_responses="\"We couldn't generate that export right now.\" on failure.",
    sample_request="""GET /reports/pnl/export?format=pdf
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "pdf_url": "https://.../pnl_report.pdf" } }',
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t generate that export right now." }',
    status_codes=status_rows(), business_rules="- Same \"backend hands back a URL, client just opens it\" contract as Payment Details' Download Receipt/Invoice — no binary streaming through this endpoint's JSON envelope.",
    notes="**Backend status: no endpoint currently exists for this** — mocked client-side today.",
    changelog="v1.0 — Documented against the client's implemented contract; endpoint pending backend implementation.")

add(id="API_057", name="Fetch Revenue & Expense Report", module="Reports",
    purpose="Returns the Revenue & Expense Summary report for the selected period/branch/date range.",
    endpoint="/reports/revenue-expense", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params=REPORT_QUERY,
    request_body="None.", validation_rules="- `period` required; client falls back to a `today`-equivalent dataset for unrecognized values — backend should define its own default.",
    success_response="`200` — `status: true`, `data` with the Revenue & Expense payload (see `RevenueExpenseReportData` model).",
    error_responses="\"We couldn't load the revenue & expense report right now.\" on failure.",
    sample_request="""GET /reports/revenue-expense?period=today&branch_id=all
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "revenue": 5000, "expense": 1200, "period": "today" } }',
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load the revenue '+chr(38)+' expense report right now." }',
    status_codes=status_rows(), business_rules="- Same `custom`-period limitation as API_055.",
    notes="**Backend status: no endpoint currently exists for this report** — mocked client-side today.",
    changelog="v1.0 — Documented against the client's implemented contract; endpoint pending backend implementation.")

add(id="API_058", name="Export Revenue & Expense Report", module="Reports",
    purpose="Requests a downloadable export (PDF or Excel) of the Revenue & Expense report.",
    endpoint="/reports/revenue-expense/export", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.",
    query_params="""| Param | Type | Required | Notes |
|---|---|---|---|
| `format` | string | Yes | `pdf` or `excel`. |""",
    request_body="None.", validation_rules="- `format` required, must be one of `pdf`/`excel`.",
    success_response="`200` — `status: true`, `data.pdf_url` or `data.excel_url`.",
    error_responses="\"We couldn't generate that export right now.\" on failure.",
    sample_request="""GET /reports/revenue-expense/export?format=excel
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "excel_url": "https://.../revenue_expense.xlsx" } }',
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t generate that export right now." }',
    status_codes=status_rows(), business_rules="- Same URL-hand-back contract as API_056.",
    notes="**Backend status: no endpoint currently exists for this** — mocked client-side today.",
    changelog="v1.0 — Documented against the client's implemented contract; endpoint pending backend implementation.")

add(id="API_059", name="Fetch Payment Mode Report", module="Reports",
    purpose="Returns the Payment Mode breakdown report for the selected period/branch/date range (Account > Report > Payment Mode).",
    endpoint="/reports/payment-mode", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params=REPORT_QUERY,
    request_body="None.", validation_rules="- `period` required; client falls back to a `this_month`-equivalent dataset for unrecognized values — backend should define its own default.",
    success_response="`200` — `status: true`, `data` with the payment-mode breakdown (see `PaymentModeReportData` model).",
    error_responses="\"We couldn't load the payment mode breakdown right now.\" on failure.",
    sample_request="""GET /reports/payment-mode?period=3m&branch_id=all
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "cash": 3000, "card": 5000, "upi": 2000, "period": "3m" } }',
    sample_error='{ "status": false, "message": "We couldn'+chr(39)+'t load the payment mode breakdown right now." }',
    status_codes=status_rows(), business_rules="- Same `custom`-period limitation as API_055/057.",
    notes="**Backend status: no endpoint currently exists for this report** — mocked client-side today; unlike API_055/057 this report has no Export variant in the client.",
    changelog="v1.0 — Documented against the client's implemented contract; endpoint pending backend implementation.")

# ============================================================
# MODULE: PAYMENTS & SUBSCRIPTION
# ============================================================

add(id="API_060", name="Fetch Payment History", module="Payments & Subscription",
    purpose="Returns the full, unpaginated, unfiltered Payment History list.",
    endpoint="/api/v1/payments/history", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None currently sent — search and status-chip filtering both happen client-side against the full list.",
    request_body="None.", validation_rules="None (read-only).",
    success_response="`200` with `success: true` **(note: this endpoint's envelope uses the key `success`, not `status`, unlike every other endpoint in this app)**, `data` with the payment list.",
    error_responses="\"Failed to load payment history\" on failure.",
    sample_request="""GET /api/v1/payments/history
Authorization: Bearer <access_token>""",
    sample_success='{ "success": true, "data": { "payments": [ { "id": "PAY-1001", "amount": 999, "status": "success" } ] } }',
    sample_error='{ "success": false, "message": "Failed to load payment history" }',
    status_codes=status_rows(),
    business_rules="- **Envelope inconsistency to flag for backend alignment:** this endpoint and API_061 check `response.data['success']`, while every other endpoint in this app checks `response.data['status']`. Recommend standardizing on one envelope key across the whole API surface before this ships broadly — the two payment endpoints are the sole outliers today.\n- Client plans for pagination/filtering to eventually move server-side, per the module's own contract notes; currently unpaginated.",
    notes="Hand-rolled try/catch pattern (not the shared `callApi` helper).")

add(id="API_061", name="Fetch Payment Details", module="Payments & Subscription",
    purpose="Returns full detail for a single payment, always fetched fresh (the Details screen only ever receives an id from the list screen).",
    endpoint="/api/v1/payments/{id}", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`id` (string, path) — Payment id.", query_params="None.",
    request_body="None.", validation_rules="- `id` must reference an existing Payment owned by the caller's account.",
    success_response="`200` with `success: true` (see API_060's envelope note), `data` with full payment detail (receipt/invoice URLs, method, amount, timestamps — see `PaymentDetailsResponse` model).",
    error_responses="\"Failed to load payment details\" on failure.",
    sample_request="""GET /api/v1/payments/PAY-1001
Authorization: Bearer <access_token>""",
    sample_success='{ "success": true, "data": { "id": "PAY-1001", "amount": 999, "status": "success", "receipt_url": "https://.../receipt.pdf" } }',
    sample_error='{ "success": false, "message": "Failed to load payment details" }',
    status_codes=status_rows(), business_rules="- Same `success`-vs-`status` envelope inconsistency noted in API_060.",
    notes="Hand-rolled try/catch pattern (not the shared `callApi` helper).")

add(id="API_062", name="Create Razorpay Order", module="Payments & Subscription",
    purpose="Creates a Razorpay payment order for a subscription plan purchase, to be handed to the Razorpay SDK client-side.",
    endpoint="/payments/razorpay/order", method="POST",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="""| Field | Type | Required |
|---|---|---|
| `amount` | integer (paise) | Yes |
| `currency` | string | Yes |
| `planId` | string | Yes |""",
    validation_rules="- `amount` must be the integer paise value (not decimal rupees) — e.g. ₹999.00 → `99900`.\n- `planId` must reference a valid, purchasable plan from the Plan Catalog (API_064).",
    success_response="`200` — `status: true`, `data` with the Razorpay order object (order id, amount, currency — see `RazorpayOrderResponse` model), to be passed directly into the Razorpay Checkout SDK.",
    error_responses="Non-200/`status:false` surfaces as a generic payment-init failure.",
    sample_request="""POST /payments/razorpay/order
Content-Type: application/json

{ "amount": 99900, "currency": "INR", "planId": "plan_pro_monthly" }""",
    sample_success='{ "status": true, "data": { "order_id": "order_9A33XWu170gUtm", "amount": 99900, "currency": "INR" } }',
    sample_error='{ "status": false, "message": "<reason>" }',
    status_codes=status_rows(), business_rules="- This call precedes handing control to the Razorpay SDK; the actual charge happens outside this API, with the result reported back via API_063.\n- Free plans (`isFree: true`) skip this flow entirely and go straight to Activate Free Trial (API_066).",
    notes="**Implementation inconsistency to flag:** hand-rolled try/catch, not the shared `callApi` helper.")

add(id="API_063", name="Save Razorpay Payment Result", module="Payments & Subscription",
    purpose="Reports the outcome of a Razorpay checkout attempt back to the backend, for every outcome (success, failure, cancellation).",
    endpoint="/payments/razorpay/result", method="POST",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="Razorpay payment result payload — payment id, order id, signature (on success), or failure/cancellation reason (see `RazorpayPaymentPayload` model's `toJson()`).",
    validation_rules="- On success, the payload should include everything needed for the backend to independently verify the payment signature server-side (standard Razorpay verification practice) rather than trusting the client's report at face value.",
    success_response="`200` — `status: true`, empty `data` (`void`).",
    error_responses="Failure here is treated as best-effort by the client — see Notes.",
    sample_request="""POST /payments/razorpay/result
Content-Type: application/json

{ "razorpay_payment_id": "pay_9A33XWu170gUtm", "razorpay_order_id": "order_9A33XWu170gUtm", "razorpay_signature": "..." }""",
    sample_success='{ "status": true }',
    sample_error='{ "status": false, "message": "<reason>" }',
    status_codes=status_rows(), business_rules="- **Must be called for every outcome of the Razorpay flow**, not just success — including a cancelled or failed checkout — so the backend has a complete record even for abandoned payments.",
    notes="**Implementation inconsistency to flag:** hand-rolled try/catch, not the shared `callApi` helper.")

add(id="API_064", name="Fetch Plan Catalog", module="Payments & Subscription",
    purpose="Returns the static-ish subscription plan catalog, independent of any one organization.",
    endpoint="/plans", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="None.", validation_rules="None (read-only).",
    success_response="`200` — full `PlanCatalogResponse` payload (plans list with pricing, features, `isFree` flag).",
    error_responses="Non-200/error → generic catalog-load failure.",
    sample_request="""GET /plans
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "plans": [ { "id": "plan_free", "name": "Free", "isFree": true, "price": 0 }, { "id": "plan_pro_monthly", "name": "Pro", "isFree": false, "price": 999 } ] } }',
    sample_error='{ "status": false, "message": "<reason>" }',
    status_codes=status_rows(), business_rules="- `isFree: true` plans route the purchase flow directly to Activate Free Trial (API_066), skipping Razorpay (API_062/063) entirely.",
    notes="Hand-rolled try/catch pattern (not the shared `callApi` helper).")

add(id="API_065", name="Fetch Subscription Status", module="Payments & Subscription",
    purpose="Returns the current subscription lifecycle state for a given organization (trial, active, expiring soon, expired, suspended, cancelled, or first-purchase/no subscription yet).",
    endpoint="/organizations/{orgId}/subscription", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`orgId` (string, path) — Organization id.", query_params="None.",
    request_body="None.", validation_rules="- `orgId` must reference an organization the caller has access to.",
    success_response="`200` — same response shape for every lifecycle state; only field values differ (see `SubscriptionStatusResponse` model). Observed lifecycle states in the client's own test fixtures: first purchase, trial, active (healthy), active (expiring soon), expired, suspended, cancelled.",
    error_responses="Non-200/error → generic subscription-status-load failure.",
    sample_request="""GET /organizations/ORG-1001/subscription
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "state": "trial", "plan_name": "Pro", "trial_ends_at": "2026-08-21" } }',
    sample_error='{ "status": false, "message": "<reason>" }',
    status_codes=status_rows(), business_rules="- One unified response contract across all seven lifecycle states listed above — backend should avoid branching the response shape per state, only the field values should differ.",
    notes="Hand-rolled try/catch pattern (not the shared `callApi` helper).")

add(id="API_066", name="Activate Free Trial", module="Payments & Subscription",
    purpose="Activates a free-tier plan directly for an organization, bypassing the Razorpay payment flow entirely.",
    endpoint="/organizations/{orgId}/subscription/activate-trial", method="POST",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`orgId` (string, path) — Organization id.", query_params="None.",
    request_body="None documented — client sends no body beyond the path parameter.",
    validation_rules="- `orgId` must reference an organization the caller has access to, and the targeted plan must have `isFree: true` per the Plan Catalog (API_064).",
    success_response="`200` — `status: true`, empty `data` (`void`).",
    error_responses="Non-200/error → generic activation failure.",
    sample_request="""POST /organizations/ORG-1001/subscription/activate-trial
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true }',
    sample_error='{ "status": false, "message": "<reason>" }',
    status_codes=status_rows(), business_rules="- Must be called instead of the Razorpay flow (API_062/063) whenever the selected plan is free — this is a hard branch in the purchase flow, not an optional shortcut.",
    notes="**Backend status: exact path not yet confirmed against a live backend** — the client's own comment notes the contract only requires this action to exist and be called for free plans; the literal path shown here is the client's current placeholder and should be confirmed/finalized with backend before release.",
    changelog="v1.0 — Documented against the client's current placeholder contract; path pending backend confirmation.")

# ============================================================
# MODULE: NOTIFICATIONS
# ============================================================

add(id="API_067", name="Fetch Notifications", module="Notifications",
    purpose="Returns the full, unpaginated Notification list for the signed-in user.",
    endpoint="/api/v1/notifications", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None — there is no server-side search/filtering yet; the All/Unread/Read chips and search are both applied client-side against this full list.",
    request_body="None.", validation_rules="None (read-only).",
    success_response="`200` — `status: true`, full `NotificationListResponse` payload (list of notifications with id, title, message, read state, timestamp, destination).",
    error_responses="\"Failed to load notifications\" on failure.",
    sample_request="""GET /api/v1/notifications
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "notifications": [ { "id": 1, "title": "New transaction", "message": "...", "read": false, "created_at": "2026-08-07T09:00:00Z" } ] } }',
    sample_error='{ "status": false, "message": "Failed to load notifications" }',
    status_codes=status_rows(),
    business_rules="- **Scalability flag for backend:** unpaginated by contract today; recommend planning for server-side pagination/filtering as notification volume grows.",
    notes="Hand-rolled try/catch pattern (not the shared `callApi` helper). Base path for the whole Notifications module: `/api/v1/notifications`.")

add(id="API_068", name="Fetch Notification By Id", module="Notifications",
    purpose="Returns full detail for a single notification — used only when a push/deep-link payload arrives with just `{id, display_mode, destination}` and needs the full title/message/actions a slim push payload doesn't carry.",
    endpoint="/api/v1/notifications/{id}", method="GET",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`id` (integer, path) — Notification id.", query_params="None.",
    request_body="None.", validation_rules="- `id` must reference an existing notification belonging to the caller.",
    success_response="`200` — `status: true`, `data` (or `data.notification`, both shapes are accepted by the client) with the full `NotificationModel` fields.",
    error_responses="\"Failed to load notification\" on failure; `404` if the notification does not exist for this user.",
    sample_request="""GET /api/v1/notifications/1
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true, "data": { "id": 1, "title": "New transaction", "message": "...", "read": false, "destination": "transaction_detail" } }',
    sample_error='{ "status": false, "message": "Failed to load notification" }',
    status_codes=status_rows(), business_rules="- Optional per the client's contract — used only for the specific push/deep-link case described in Purpose, not on the normal Notifications list screen (which relies entirely on API_067).",
    notes="Client accepts the payload either as a bare object under `data`, or nested one level deeper under `data.notification` — backend should pick one and the client will be aligned to match; documented here as-implemented (both currently tolerated).")

add(id="API_069", name="Mark Notification Read", module="Notifications",
    purpose="Marks a single notification as read.",
    endpoint="/api/v1/notifications/read", method="POST",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None (id is in the body, not the path — see Request Body).",
    query_params="None.",
    request_body="""| Field | Type | Required |
|---|---|---|
| `notification_id` | integer | Yes |""",
    validation_rules="- `notification_id` must reference an existing notification belonging to the caller.",
    success_response="`200` — `status: true` (boolean success signal).",
    error_responses="\"Failed to mark notification read\" on failure.",
    sample_request="""POST /api/v1/notifications/read
Content-Type: application/json

{ "notification_id": 1 }""",
    sample_success='{ "status": true }',
    sample_error='{ "status": false, "message": "Failed to mark notification read" }',
    status_codes=status_rows(),
    business_rules="- Client applies the read state optimistically in the UI immediately and treats a failure here as best-effort — a failed mark-as-read call is logged/ignored rather than shown as an error to the user, per the module's \"never crash / gracefully handle failed mark-as-read\" requirement.",
    notes="Hand-rolled try/catch pattern (not the shared `callApi` helper).")

add(id="API_070", name="Mark All Notifications Read", module="Notifications",
    purpose="Marks every notification for the signed-in user as read in one call.",
    endpoint="/api/v1/notifications/read-all", method="POST",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="Empty object `{}`.",
    validation_rules="None beyond a valid Authorization header.",
    success_response="`200` — `status: true`.",
    error_responses="\"Failed to mark all notifications read\" on failure.",
    sample_request="""POST /api/v1/notifications/read-all
Content-Type: application/json

{}""",
    sample_success='{ "status": true }',
    sample_error='{ "status": false, "message": "Failed to mark all notifications read" }',
    status_codes=status_rows(), business_rules="- Same best-effort/optimistic-update treatment as API_069.",
    notes="Hand-rolled try/catch pattern (not the shared `callApi` helper).")

add(id="API_071", name="Delete Notification", module="Notifications",
    purpose="Deletes a single notification.",
    endpoint="/api/v1/notifications/{id}", method="DELETE",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="`id` (integer, path) — Notification id.", query_params="None.",
    request_body="None.", validation_rules="- `id` must reference an existing notification belonging to the caller.",
    success_response="`200` — `status: true`.",
    error_responses="\"Failed to delete notification\" on failure.",
    sample_request="""DELETE /api/v1/notifications/1
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true }',
    sample_error='{ "status": false, "message": "Failed to delete notification" }',
    status_codes=status_rows(), business_rules="N/A.",
    notes="This and API_072 are the only two `DELETE`-verb calls in the entire client (every other delete elsewhere in the app is modeled as `POST .../delete`). Hand-rolled try/catch pattern (not the shared `callApi` helper).")

add(id="API_072", name="Delete All Read Notifications", module="Notifications",
    purpose="Bulk-deletes every notification currently marked as read (\"Delete All Read\" overflow action).",
    endpoint="/api/v1/notifications/read", method="DELETE",
    auth=AUTH_BEARER, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="None.", validation_rules="None beyond a valid Authorization header.",
    success_response="`200` — `status: true`.",
    error_responses="\"Failed to delete read notifications\" on failure.",
    sample_request="""DELETE /api/v1/notifications/read
Authorization: Bearer <access_token>""",
    sample_success='{ "status": true }',
    sample_error='{ "status": false, "message": "Failed to delete read notifications" }',
    status_codes=status_rows(),
    business_rules="- **Path collision to flag for backend routing:** this endpoint's path (`DELETE /api/v1/notifications/read`) differs from API_069's (`POST /api/v1/notifications/read`) only in HTTP verb — both must be registered as distinct routes sharing the same path string. Confirm the backend router disambiguates by method correctly.",
    notes="Hand-rolled try/catch pattern (not the shared `callApi` helper).")

# ============================================================
# MODULE: THIRD-PARTY (NOT OUR BACKEND)
# ============================================================

add(id="API_073", name="Fetch Indian States (3rd-Party)", module="Third-Party APIs (Not Our Backend)",
    purpose="Fetches the list of Indian states from the free public countriesnow.space API, used to populate a State dropdown during Registration/Account/Branch address entry.",
    endpoint="https://countriesnow.space/api/v0.1/countries/states", method="POST",
    auth=AUTH_THIRDPARTY, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="""| Field | Type | Required |
|---|---|---|
| `country` | string | Yes (always `"India"` in this client) |""",
    validation_rules="- This is a third-party contract, not ours — client does not control or validate beyond checking `error: false` in the response.",
    success_response="`200` — `error: false`, `data.states[]` (each with a `name`), sorted alphabetically by the client after receipt.",
    error_responses="`error: true` from the third party, or a `DioException`, both surface as \"Could not load states\".",
    sample_request="""POST https://countriesnow.space/api/v0.1/countries/states
Content-Type: application/json

{ "country": "India" }""",
    sample_success='{ "error": false, "data": { "name": "India", "states": [ { "name": "Karnataka" }, { "name": "Maharashtra" } ] } }',
    sample_error='{ "error": true, "msg": "..." }',
    status_codes=[("200", "Success (third party's own envelope indicates success/failure via `error`, not HTTP status alone)."), ("4xx/5xx", "Third-party service error — surfaced as a generic \"Could not load states\" / connectivity failure.")],
    business_rules="- Deliberately **not** routed through `DioClient` (our backend's base URL, auth interceptor, and token-refresh logic would be actively wrong for a public third party) — this uses its own isolated `Dio` instance with a 15s timeout.\n- Connectivity is pre-checked before the call, same UX as our own backend calls, so a user with no signal sees an immediate \"No internet connection\" rather than waiting out the full timeout.",
    notes="Not part of our backend surface — documented here for completeness per the requested full API inventory, but any backend contract changes are out of our control (owned by countriesnow.space).")

add(id="API_074", name="Fetch Cities For State (3rd-Party)", module="Third-Party APIs (Not Our Backend)",
    purpose="Fetches the list of cities for a given Indian state from the free public countriesnow.space API, used to populate a City dropdown once a State is selected.",
    endpoint="https://countriesnow.space/api/v0.1/countries/state/cities", method="POST",
    auth=AUTH_THIRDPARTY, headers=HEADERS_STD,
    path_params="None.", query_params="None.",
    request_body="""| Field | Type | Required |
|---|---|---|
| `country` | string | Yes (always `"India"`) |
| `state` | string | Yes — the state name selected via API_073 |""",
    validation_rules="- Third-party contract, not ours.",
    success_response="`200` — `error: false`, `data[]` (array of city name strings), sorted alphabetically by the client after receipt.",
    error_responses="`error: true`, or a `DioException`, both surface as \"Could not load cities\".",
    sample_request="""POST https://countriesnow.space/api/v0.1/countries/state/cities
Content-Type: application/json

{ "country": "India", "state": "Karnataka" }""",
    sample_success='{ "error": false, "data": ["Bengaluru", "Mysuru", "Mangaluru"] }',
    sample_error='{ "error": true, "msg": "..." }',
    status_codes=[("200", "Success (third party's own envelope indicates success/failure via `error`)."), ("4xx/5xx", "Third-party service error — surfaced as a generic connectivity/load failure.")],
    business_rules="- Same isolation-from-`DioClient` rationale as API_073.",
    notes="Not part of our backend surface — documented here for completeness. **Implementation detail:** this call hardcodes the full URL rather than a relative path on the shared `_dio` instance's `baseUrl` — functionally equivalent, but inconsistent with `fetchIndianStates`' relative-path style in the same class; harmless but worth normalizing if this file is touched again.")

add(id="API_075", name="Verify Pincode (3rd-Party)", module="Third-Party APIs (Not Our Backend)",
    purpose="Looks up City/State for a given Indian postal (PIN) code via the free public api.postalpincode.in service, to auto-fill and let the user confirm City/State from a pincode entry.",
    endpoint="https://api.postalpincode.in/pincode/{pincode}", method="GET",
    auth=AUTH_THIRDPARTY, headers=HEADERS_STD,
    path_params="`pincode` (string, path) — the 6-digit Indian PIN code to look up.",
    query_params="None.",
    request_body="None.",
    validation_rules="- Third-party contract, not ours; client treats any non-2xx, empty response, non-`Success` status, or missing `PostOffice` data uniformly as \"invalid pincode\" rather than surfacing the specific third-party error.",
    success_response="`200` — a JSON array; first element's `Status` is `\"Success\"` and `PostOffice[]` is non-empty. Client extracts `District` (→ city) and `State` from the first post office entry.",
    error_responses="Any failure (network, empty result, non-`Success` status) resolves to `{ isValid: false }` client-side — no error message is surfaced to distinguish \"bad pincode\" from \"service unreachable\" beyond the separate `isOffline` flag for connectivity specifically.",
    sample_request="""GET https://api.postalpincode.in/pincode/560025""",
    sample_success="""[
  {
    "Message": "Number of Post Office(s) found: 1",
    "Status": "Success",
    "PostOffice": [ { "Name": "Residency Road", "District": "Bengaluru", "State": "Karnataka" } ]
  }
]""",
    sample_error="""[ { "Message": "No records found", "Status": "Error", "PostOffice": null } ]""",
    status_codes=[("200", "Always 200 from this third party — success/failure is signaled inside the JSON body via `Status`, not HTTP status."), ("Network", "A connectivity failure (checked up front) returns `{ isValid: false, isOffline: true }` client-side so the UI can distinguish \"bad pincode\" from \"can't reach the service\".")],
    business_rules="- `isOffline: true` specifically prevents the UI from telling the user their pincode is invalid when the real cause is a connectivity problem — this distinction matters for the confirmation-dialog UX.",
    notes="Not part of our backend surface — documented here for completeness. India-only, free, no API key.")

# ============================================================
# RENDER
# ============================================================

MODULE_ORDER = [
    "Auth & Session",
    "Registration & Forgot Password",
    "App / Profile / Account",
    "Dashboard",
    "Firms",
    "Branches",
    "Services",
    "Staff",
    "Salary Rules",
    "Expenses",
    "Transactions",
    "Reports",
    "Payments & Subscription",
    "Notifications",
    "Third-Party APIs (Not Our Backend)",
]

by_module = {}
for e in ENTRIES:
    by_module.setdefault(e["module"], []).append(e)

w("# Backend API Documentation")
w()
w("**Project:** dev20 (Flutter client)  ")
w("**Scope:** Every backend API call made by the client, reverse-engineered from `lib/core/network/apis/` (28 files, 75 individual endpoint calls across our own backend and 2 third-party public services).  ")
w("**Sequence numbering:** Each endpoint below is tagged `API_001`–`API_075`. The same sequence number has been added as a `// ==...==` banner comment directly above each corresponding method in the source code (see `lib/core/network/apis/*.dart`), so this document and the code cross-reference 1:1 via the `Backend Doc Ref` field.  ")
w("**Response envelope:** Unless noted otherwise, every endpoint uses `{ \"status\": true|false, \"message\": \"...\", \"data\": {...} }` on success and `{ \"status\": false, \"message\": \"<reason>\" }` (optionally with `error_code`) on failure. Two endpoints (API_060, API_061 — Payment History/Details) use `success` instead of `status` as the top-level key; this is flagged in their entries as a contract inconsistency worth aligning.  ")
w("**No implementation changes were made** as part of this analysis beyond adding the `API_XXX` sequence-number comment banners to the source files, per the requested scope — this is a documentation and code-comment task only.")
w()
w("## How This Document Was Produced")
w()
w("This is a **client-driven reverse-engineering** of the backend contract, not a spec pulled from backend source or existing backend documentation (none was found in the repository). Every field below reflects what the Flutter client actually sends and expects to receive, inferred from:")
w("- The `lib/core/network/apis/*.dart` files (method signatures, request payload construction, response parsing).")
w("- `lib/core/network/dio_client.dart` (auth header attachment, public-vs-protected routing, token refresh/retry behavior).")
w("- `lib/core/network/api_call_helper.dart` / `api_response.dart` / `api_exceptions.dart` (the shared success/error envelope and status-code handling).")
w("- Bundled mock JSON fixtures under `assets/mocks/` (used as the basis for every Sample Request/Response pair below).")
w("- In-code doc comments, several of which already state an explicit `BACKEND CONTRACT` block or flag an endpoint as **not yet implemented on the backend** — these are called out per-endpoint in the Notes column.")
w()
w("Several endpoints (flagged individually below) do not have a live backend yet and are served from local mock JSON in the client's mock mode. A handful of cross-cutting inconsistencies worth resolving before/at backend integration are also flagged inline where they occur (envelope key mismatch on Payments, the Reset Password token field, the free-trial activation path, etc.).")
w()

w("## Table of Contents")
w()
for module in MODULE_ORDER:
    items = by_module.get(module, [])
    if not items:
        continue
    w(f"**{module}**")
    for e in items:
        w(f"- [{e['id']} — {e['name']}](#{e['id'].lower()}--{e['name'].lower().replace(' ', '-').replace('&','').replace('(', '').replace(')', '').replace('/', '').replace(chr(39),'')})")
    w()
w("---")
w()

for module in MODULE_ORDER:
    items = by_module.get(module, [])
    if not items:
        continue
    w(f"# Module: {module}")
    w()
    for e in items:
        render_entry(e)

with open("API_Backend_Documentation.md", "w", encoding="utf-8") as f:
    f.write("\n".join(OUT))

print("Wrote", len(ENTRIES), "entries;", len(OUT), "lines")
