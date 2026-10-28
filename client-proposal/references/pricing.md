# Pricing

## Never invent the user's rate

The hourly rate belongs to the freelancer. If it is not known, ask once:
"What is your hourly rate, or what do you want to earn per month?"

If they still do not know, present the maths and let them choose the number. Do not
fill in a number for them.

## Estimate hours, not feelings

Break the scope into items of 2-8 hours each. Anything bigger gets split.

Typical shapes (adjust to the person's speed, not to industry folklore):

| Item | Hours |
|---|---|
| Static page, designed and built | 4-8 |
| Page with a form + validation + email | 8-12 |
| Auth (register, login, reset) | 12-20 |
| CRUD resource (list, create, edit, delete + permissions) | 14-20 |
| Payment integration (Stripe/checkout + webhooks) | 12-20 |
| Arabic/English bilingual pass | +20-30% of UI hours |
| Content entry per item | 0.2-0.5 |
| Deployment, domain, SSL, backups | 4-8 |
| Project management and client communication | +10-15% of total |

## The buffer is not optional

- **+20%** for normal projects (unknowns, browser fixes, client delay).
- **+30-40%** if content, brand, or integrations are not ready.
- Never quote the raw sum. The raw sum is how freelancers lose money.

## Run the numbers

```powershell
powershell -NoProfile -File scripts/quote.ps1 -Hours 120 -Rate 250 -Currency EGP
```

The script adds the buffer, tax, deposit and balance, and suggests three tiers.

## Three tiers

| Tier | Content | Price |
|---|---|---|
| Basic | core deliverables only | ~70% |
| Standard | core + the second-order features | 100% (recommend this) |
| Premium | everything + support + training | ~140% |

Present Standard as the recommendation. Basic exists to make Standard look sane,
Premium to make Standard look affordable.

## Payment schedule

- **40-50%** deposit, before any work.
- **30%** at the mid milestone (design approved or core flow working).
- **20-30%** before handover / going live.
- Maintenance: monthly retainer, billed in advance, with an hour cap.

## Currency and tax

Always name the currency next to the number. State whether tax is included.
If the client pays in another currency, state the rate date or the fixed rate.

## Red flags in pricing

- "We will pay after it works" -> declined, or paid discovery only.
- "Equity or exposure" -> no.
- Client compares you to a template price -> sell the scope, not the pages.
- Discount requested before scope is agreed -> discount the scope, never the price.
