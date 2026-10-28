# Security

Not a phase at the end - a checklist you re-walk before handoff. Each item is
either done, not applicable, or an accepted risk written into `docs/handoff.md`.

## Input and output

- [ ] Every request body, query and param parsed with a schema at the boundary.
- [ ] Unknown fields rejected on anything that writes.
- [ ] Uploads: allow-listed types, size cap, random filenames, stored outside the web root.
- [ ] No `dangerouslySetInnerHTML`, `innerHTML`, or `eval` with user data.
- [ ] User content rendered as text by default; markdown sanitised with a maintained library.
- [ ] Redirect targets validated (no open redirect via `?next=`).

## Data access

- [ ] Parameterised queries only. No string-built SQL anywhere.
- [ ] Ownership checked in the query for every user-scoped row.
- [ ] Mass assignment impossible: explicit field allow-list on create/update.
- [ ] Database user has the minimum rights the app needs.
- [ ] Backups exist and a restore has been tried at least once.

## Sessions and auth

- [ ] Passwords hashed with argon2id/bcrypt; no SHA family.
- [ ] Cookie flags: `httpOnly`, `secure`, `sameSite=lax` (or strict), sensible expiry.
- [ ] Session invalidated on logout and on password change.
- [ ] CSRF protection for cookie-based state changes (token or sameSite + origin check).
- [ ] Auth endpoints rate limited (login, register, reset, OTP).
- [ ] No user enumeration: same response and timing for "unknown" and "wrong password".
- [ ] MFA available for admin accounts if the product has admins.

## Transport and headers

- [ ] HTTPS only, HSTS on, no mixed content.
- [ ] CSP that actually restricts (`default-src 'self'` + explicit exceptions).
- [ ] `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `X-Frame-Options` or
      `frame-ancestors` in CSP.
- [ ] Cookies and tokens never in URLs.

## Secrets and config

- [ ] Secrets in env vars, `.env` git-ignored, `.env.example` committed with empty values.
- [ ] No key, token or password in code, fixtures, comments, or client bundles.
- [ ] Different credentials per environment; production keys never used locally.
- [ ] Public/private key split respected (only `NEXT_PUBLIC_*` reaches the browser).

## Abuse

- [ ] Rate limit per IP + per account on auth, writes, search and expensive endpoints.
- [ ] Body size limit on the server (defaults are often too generous).
- [ ] Pagination capped - no `limit=1000000`.
- [ ] Expensive operations (email, PDF, AI) have a quota.
- [ ] Error messages do not reveal whether a record exists to someone unauthorised.

## Dependencies and supply chain

- [ ] Lockfile committed.
- [ ] `npm audit` reviewed; no high/critical left unexplained.
- [ ] New dependency justified in the commit message (maintenance, size, licence).
- [ ] No `postinstall` scripts from unknown packages.

## Before you call it done

- [ ] Logged-out user hitting every private URL gets redirected, not a 500.
- [ ] User A cannot read or modify user B's data by changing an id.
- [ ] Admin-only routes reject a normal session.
- [ ] A failed login leaves no trace of which part was wrong.
- [ ] Stack traces are off in production.
- [ ] `docs/handoff.md` lists every accepted risk in plain language.
