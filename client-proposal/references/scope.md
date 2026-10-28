# Scope

The scope document is the contract's spine. Everything else is decoration.

## Write deliverables, not activities

| Bad | Good |
|---|---|
| Work on the homepage | Home page: hero, 3 service cards, testimonial slider, contact form |
| SEO | Metadata for 6 pages, sitemap, robots.txt, 90+ Lighthouse SEO score |
| Admin panel | Admin can add/edit/delete products (name, price, 3 images, stock) |
| "Make it responsive" | Layouts verified at 360, 768, 1280 px |

## Every deliverable needs an acceptance criterion

The client must be able to answer "is this done?" without an opinion:

- "Contact form sends to info@ and shows a success message; failures show a retry."
- "Arabic and English versions of the 5 pages, switchable from the header."
- "Page loads in under 3 seconds on 4G, measured on PageSpeed."

## Sections of scope.md

```markdown
# Scope - <project>

## Deliverables
### 1. <Name>
- What: ...
- Accept: ...
- Depends on: ...

## Not included
- Copywriting, photography, logo design
- Product photography retouching
- Hosting, domain, paid plugins
- Content entry beyond 10 items
- Training beyond one 60-minute session

## Assumptions
- Client provides final texts before <date>
- One decision maker approves each round
- Brand assets delivered in editable format
- Third-party accounts (payment, SMS) opened by the client

## Revisions
- Two rounds per screen, consolidated feedback per round
- After that: change request, quoted separately

## Out of scope by nature
- Anything not listed above
```

## Rules

- **"Not included" is not rude.** It is the sentence that prevents the fight.
- If the client asks for something mid-project, answer with the change-request
  process, not with a price on the spot.
- Free extras: give them as a written bonus with a value, never silently.
- Ambiguous words to ban from scope: "simple", "modern", "fast", "similar to",
  "a few", "as needed". Replace each with a number.
