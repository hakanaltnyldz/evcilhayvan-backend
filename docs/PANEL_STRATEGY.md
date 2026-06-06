# Panel Strategy

## Decision

The source of truth for web panel work is `evcilhayvan_admin/`.

This React/Vite app contains both workspaces:

- Admin workspace: `/dashboard`, `/users`, `/pets`, `/orders`, `/returns`, `/moderation-queue`, `/posts`, `/coupons`, `/platform-settings`, `/support`, `/sitters`, `/vets`, `/vet-claims`, `/seller-applications`, `/audit-logs`
- Seller workspace: `/seller`, `/seller/products`, `/seller/orders`, `/seller/coupons`, `/seller/analytics`, `/seller/store-profile`

`evcilhayvan_seller/` is now treated as a legacy standalone seller panel. It is not the deploy target for new seller work unless a separate seller deployment is intentionally reintroduced.

## Why

- `render.yaml` publishes `evcilhayvan_admin/dist` as the only static panel.
- `evcilhayvan_admin/src/App.jsx` already has role-based routing for both `admin` and `seller`.
- `evcilhayvan_admin/src/lib/session.js` already normalizes legacy `admin_token` and `seller_token` storage into `panel_token`.
- Keeping two active seller panel code paths creates duplicated UI, duplicated tests, and drift between feature coverage.

## Working Rules

- Add new admin features under `evcilhayvan_admin/src/pages/`.
- Add new web seller features under `evcilhayvan_admin/src/pages/seller/`.
- Keep shared panel navigation in `evcilhayvan_admin/src/config/navigation.js`.
- Keep shared auth/session behavior in `evcilhayvan_admin/src/lib/session.js`.
- Do not add new features to `evcilhayvan_seller/` unless the explicit goal is to keep the legacy app working.
- If the standalone seller panel is needed again, add a separate deploy service and document how it differs from the unified panel.

## Current Gaps To Resolve Next

- Admin operation screens missing despite backend support:
  - `/api/admin/sitter-bookings`
  - `/api/admin/walk-updates`
  - `/api/admin/care-reports`
  - `/api/admin/users/:id/sensitive`
  - `/api/admin/orders/:id/guest-sensitive`
- Seller web workspace gaps:
  - Product variants and option-level stock
  - Fast stock increase/decrease actions
  - Seller product reviews
  - Seller coupon performance
  - Return resolution parity with mobile seller panel
