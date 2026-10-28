# Debugging

Never guess twice. One hypothesis, one experiment, one result.

## The loop

1. **Reproduce** it yourself. Exact URL, exact input, exact account. If you cannot
   reproduce it, you cannot fix it - add logging first.
2. **Read the actual error.** Full stack trace, first lines of the server log, the
   network tab response. Not what you assume the error is.
3. **Shrink** the problem: smallest input that still fails, or comment out half.
4. **Hypothesise** in one sentence: "I think X returns 401 because the cookie is not set on this path."
5. **Test the hypothesis** with one change or one log line. No shotgunning.
6. **Fix the cause**, not the symptom. Suppressing an error is not a fix.
7. **Verify** with the original reproduction, then add a regression test.
8. **Prevent**: what would have caught this earlier - a type, a test, a validation?

## Playbooks

**Build fails** - read the first error, not the last. Usually a type or a missing
import. Run the type checker alone for a clean signal (`npx tsc --noEmit`).

**Works locally, fails deployed** - env var missing, wrong branch, build-only
difference (SSR vs client), case-sensitive paths, stale cache. Compare the two
envs before touching code.

**Hydration mismatch** - something differs between server and client render:
`Date.now()`, `Math.random()`, `localStorage`, `window`, locale formatting. Render
it after mount or pass it from the server.

**Prisma errors** - `P2002` duplicate unique, `P2003` foreign key, `P2025` record
not found. Read the meta field; it names the constraint.

**Auth loops / always 401** - cookie domain or path wrong, `secure` set on http,
sameSite too strict for the redirect, or the session read before the cookie is set.
Inspect the actual `Set-Cookie` header.

**CORS** - credentials need an explicit origin (no `*`), plus `Access-Control-Allow-Credentials`.
Preflight `OPTIONS` must answer before the real request.

**Slow page** - measure before optimising: query time vs render time vs payload.
Add an index before adding a cache.

**Intermittent** - look for ordering, race conditions, timezone, retries without
idempotency, and pool exhaustion. Add the request id to every log line.

## Rules

- Change one thing at a time, otherwise you learn nothing.
- Keep a scratch note of what you tried and what happened.
- If two attempts fail, stop and re-read the code and the docs instead of guessing again.
- Delete debug logs before committing.
