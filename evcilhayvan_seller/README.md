# Legacy Seller Panel

`evcilhayvan_seller/` is a legacy standalone seller panel.

The active web panel source of truth is now `../evcilhayvan_admin/`, which contains both:

- Admin workspace
- Seller workspace under `/seller/*`

New seller web features should be implemented in:

```text
evcilhayvan_admin/src/pages/seller/
```

This legacy app can still be built and tested for compatibility, but it is not published by the current `render.yaml`.
