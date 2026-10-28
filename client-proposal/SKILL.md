---
name: client-proposal
display-name: Client Proposal
description: Turns a client conversation into a scoped proposal with price,
  timeline, exclusions and payment terms. Use when quoting, scoping or replying
  to a freelance client.
---

# Client Proposal

A proposal is not a price. It is a shared definition of "done" that protects both
sides. Never send a number without writing the scope that justifies it.

## The order (do not reorder)

1. **Discover** - `references/discovery.md`
2. **Scope** - `references/scope.md` -> `scope.md`
3. **Estimate** - `references/pricing.md` -> run `scripts/quote.ps1`
4. **Terms** - `references/terms.md`
5. **Write** `proposal.md` in the client's language
6. **Present** - three tiers, one recommendation

## Artifacts

Keep them in `proposals/<client>-<date>/`:

| File | Content |
|---|---|
| `scope.md` | deliverables, acceptance criteria, exclusions, assumptions |
| `estimate.md` | hours per deliverable, buffer, rate, phases (internal - never send) |
| `proposal.md` | the client-facing document |
| `terms.md` | payment, revisions, ownership, cancellation |

## Phase 1 - Discover

Ask what changes the price. Three questions per message, in the client's language,
with a suggested default so "I don't know" does not stall the conversation.

Never ask "what is your budget" first. Ask about the outcome, then the deadline,
then the budget, framed as a range choice.

## Phase 2 - Scope

Every line is a **deliverable**, not an activity. "Home page with hero, services,
contact form" - not "work on the home page".

Each deliverable needs an acceptance criterion the client can check: "form sends
an email to info@ and shows a confirmation".

Always write, explicitly:
- **Included** - what they get
- **Not included** - the list that saves you later
- **Assumptions** - what must be true for the price (content ready, one decision maker...)
- **Revisions** - two rounds per screen, then it is a change request

## Phase 3 - Estimate

Break scope into items, estimate each in hours, then apply buffer. Use
`scripts/quote.ps1` so the arithmetic is never wrong and the deposit is consistent.

Never invent the user's hourly rate. If they have not given a rate, ask.

## Phase 4 - Terms

Deposit before work, balance before handover, IP transfers on final payment,
change requests in writing, support window stated, hosting/domain billed separately.

## Phase 5 - Write

Structure of `proposal.md`:

1. What I understood (their words, one short paragraph)
2. What you get (deliverables, plain language)
3. How it will look and work (2-3 sentences, plus links if you have work)
4. Timeline with phases and a start date
5. Investment: three tiers, middle one recommended
6. What is not included
7. What I need from you to start
8. Payment terms and validity (14 days)
9. Next step, one sentence, one action

## Phase 6 - Present

Three tiers beat one price: Basic (core only), Standard (recommended), Premium
(everything plus support). Anchor at Premium; most clients pick the middle.

## Hard rules

- No estimate without a written scope.
- No unlimited revisions, ever.
- Never promise a date without a buffer for late content from the client.
- Price must state the currency and whether tax is included.
- If the client refuses to define scope, that is a red flag - say so in
  `estimate.md` and price the discovery phase separately.
- Never send `estimate.md`. It contains your hours and your margin.
- Quote in the client's language; numbers and currency the way they read them.
