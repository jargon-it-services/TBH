# API change needed: `totalCustomers` on the dashboard response

## Why
The "Total Services Served" KPI card now shows two counts side by side — Services and Customers. Services is already backed by `meta.counts.totalServices`. Customers has no backing field yet, so it currently renders as `—`.

## What to add
Add one new integer field to the existing `counts` object returned by:

- `GET /dashboard` (admin/manager/branch-admin/employee dashboard)

```jsonc
{
  "status": true,
  "data": {
    "meta": {
      "currency": "INR",
      "periods": ["Daily", "Weekly", "Monthly", "Yearly"],
      "counts": {
        "totalFirms": 4,
        "totalServices": 10,
        "totalStaff": 10,
        "totalCustomers": 7   // <-- NEW: count of distinct customers served in the selected period
      }
    }
  }
}
```

## Field definition
| Field | Type | Notes |
|---|---|---|
| `totalCustomers` | integer | Count of distinct customers served within the currently selected period/scope (same period + branch/org scoping already applied to `totalServices`). |

## Client-side status
The Flutter app already:
- Parses this field if present (`DashboardCounts.totalCustomers`, nullable).
- Falls back to `—` in the UI if the field is absent or `null`, so this is a safe, non-breaking addition — ship whenever convenient, no coordinated release required.

## Scope note
The period selector was simultaneously simplified from 5 options to 4 (Daily / Weekly / Monthly / Yearly — Quarterly removed) to match the approved design. This already matched `meta.periods` in your existing mock response, so no backend change is needed for that part.
