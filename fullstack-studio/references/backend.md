# Backend

## Endpoints

- Group by resource: `/api/bookings`, `/api/bookings/:id`.
- Correct verbs and status codes: 200/201/204, 400 validation, 401 not signed in,
  403 signed in but not allowed, 404, 409 conflict, 422 business rule, 429 rate limit, 500 unknown.
- Every response has one shape. Success: `{ data }`. Failure:
  `{ error: { code, message, fields? } }`. Never mix.
- Paginate every list: `?page=1&limit=20` or cursor. Return `total` or `nextCursor`.
- Filtering and sorting are explicit allow-lists, never raw query parameters passed
  to the database.

## Validation

Validate at the boundary, once, with `zod`, and pass the parsed value inward.

```ts
const createBooking = z.object({
  roomId: z.string().uuid(),
  startsAt: z.coerce.date().refine(d => d > new Date(), 'must be in the future'),
  note: z.string().max(500).optional(),
});
```

- Client validation is UX. Server validation is the truth. Both use the same schema.
- Reject unknown fields (`.strict()`) on anything that writes.
- Validate file type, size and count on upload, not only in the browser.

## Database

- `snake_case` tables and columns, plural table names, `id` primary key (uuid or
  bigint - decide once), `created_at` / `updated_at` on everything.
- Foreign keys with explicit `onDelete` behaviour. Never cascade into money or logs.
- Index every foreign key and every column used in a filter or sort.
- Money as integer minor units or `Decimal`. Never float.
- Timestamps in UTC (`timestamptz`). Convert in the UI.
- Soft delete only when the product needs history; otherwise delete.
- Migrations are files in git. Never edit a migration that has run.
- Multi-step writes go in a transaction.
- Queries: parameterised only. No string concatenation into SQL, ever.

## Auth and authorisation

- Passwords: `argon2id` (or bcrypt cost >= 12). Never SHA/MD5, never reversible.
- Sessions: httpOnly, secure, sameSite=lax cookies. Not localStorage tokens for browsers.
- Check **authorisation on every read and write**, not only on the route: "is this
  row mine?" belongs in the query (`where: { userId: session.user.id }`).
- Roles are data, not scattered `if (role === 'admin')`. Centralise in one policy module.
- Login, register, password reset and any write endpoint: rate limited.
- Password reset tokens: single use, short TTL, hashed at rest.

## Errors and logging

- Catch at the edge, log once, return a safe message. Never leak stack traces or
  SQL to the client.
- Log: timestamp, request id, route, status, duration, user id (not email/name).
- Never log passwords, tokens, cookies, or full request bodies of auth routes.
- Expected failures (validation, 404) are not errors; do not page anyone for them.

## Background work

- Anything slower than ~2s that the user does not need immediately goes to a job:
  emails, image processing, exports, webhooks.
- Jobs must be idempotent and retried with backoff. Log the job id with the request id.
