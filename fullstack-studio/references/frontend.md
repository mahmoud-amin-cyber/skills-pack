# Frontend

## Structure

Organise by feature, not by file type. One folder per feature holds its
components, hooks, queries and types.

```
src/
  app/                # routes only (Next.js) - thin, no business logic
  features/
    bookings/
      components/
      hooks/
      queries.ts      # data access for this feature
      schema.ts       # zod schemas shared with the server
  components/ui/      # design-system primitives: Button, Field, Dialog
  lib/                # db client, auth helpers, formatting
```

Rules:
- Routes compose features; they do not contain logic.
- A component over ~150 lines gets split.
- Shared UI primitives are dumb: props in, markup out, no data fetching.
- Colocate styles and tests with what they test.

## Server and client state

- Server data: fetch on the server when possible; never mirror it into client
  state. Invalidate after mutations instead of hand-patching caches.
- Client state: local `useState` first, `useReducer` for related fields, a store
  only when state is truly global.
- URL is state: filters, tabs, pagination and search belong in the query string.
- No data fetching inside presentational components.

## Every screen needs four states

1. **Loading** - skeleton that matches the real layout, not a spinner in a void.
2. **Empty** - says what would appear here and offers the action to create it.
3. **Error** - what failed, what to do, and a retry.
4. **Success** - the thing itself.

If you only build the fourth, the screen is half finished.

## Forms

- `react-hook-form` + `zod` resolver, schema imported from the feature folder so
  the server validates the same rules.
- Labels above inputs, `aria-describedby` for errors, errors next to the field.
- Disable the submit button during submit, keep the values on failure.
- Never trust client validation - it is UX, not security.

## Images and performance

- Explicit `width`/`height` or `aspect-ratio` to stop layout shift.
- `next/image` (or `srcset` + `sizes`) for anything large; lazy-load below the fold.
- Self-host or subset fonts, `font-display: swap`, preload the display face only.
- No client-side library over 50KB without a stated reason.

## SEO and metadata

- Unique `title` and `description` per route.
- OpenGraph image and canonical URL.
- Semantic headings: exactly one `h1`, no level skipping.
- `sitemap.xml` and `robots.txt` for public sites; `noindex` on private areas.

## TypeScript

- `strict: true`, no `any` in application code (`unknown` + narrowing instead).
- Types derive from the source of truth: `z.infer<typeof schema>` for validation,
  Prisma types for rows. Never hand-write a duplicate interface.
