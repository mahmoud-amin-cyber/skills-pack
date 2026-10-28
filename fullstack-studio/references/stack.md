# Stack selection

Pick the smallest thing that satisfies the brief. Every extra moving part is a
future outage and a slower build.

## Decision tree

1. **Static content, no login, no database** (portfolio, landing, company profile)
   -> HTML + CSS + vanilla JS, or Astro when there are many pages or a blog.
2. **Content site that must rank on Google** (blog, docs, catalogue)
   -> Astro or Next.js with static generation. No database unless content is edited
   by non-developers.
3. **App with accounts and stored data** (dashboard, SaaS, marketplace, internal tool)
   -> Next.js (App Router) + TypeScript + Postgres + Prisma + Auth.js.
4. **API for another client** (mobile app, external consumers, background jobs)
   -> Node + Fastify (or Express) + Postgres, or FastAPI if the team is Python.
5. **Real-time needs** (chat, presence, live dashboards)
   -> add WebSockets or Server-Sent Events to option 3 or 4. Do not reach for a
   separate realtime service on day one.
6. **Payments** -> Stripe Checkout + webhooks; never store card data yourself.

If two options fit, choose the one with fewer services to operate.

## Defaults that are safe to assume

- TypeScript everywhere, `strict: true`.
- Postgres, not MySQL, not Mongo, unless the data is genuinely document-shaped.
- Prisma for schema + migrations.
- Tailwind or plain CSS modules; pick one and stay consistent.
- `zod` for validation at every boundary.
- `vitest` (or `node:test`) for unit tests, Playwright only for the two or three
  flows that must not break.
- Deploy target decided in the brief; if undecided, Vercel + Neon for option 3,
  static hosting for option 1.

## Bootstrap commands

```powershell
# Static site
mkdir site; cd site; npm init -y; npm i -D vite

# Full app
npx create-next-app@latest app --typescript --tailwind --eslint --app --src-dir
cd app; npm i prisma @prisma/client zod
npx prisma init --datasource-provider postgresql

# API service
mkdir api; cd api; npm init -y; npm i fastify zod @prisma/client; npm i -D typescript tsx
```

## Anti-patterns

- A second framework "just in case".
- MongoDB for relational data.
- Adding Redis, queues, or microservices before there is a measured problem.
- Choosing a stack because a tutorial used it.
- Locking in a paid service before the user agreed to pay for it.
