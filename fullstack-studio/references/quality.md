# Quality

## Definition of done

A slice is done when all of these are true:

- [ ] It works end to end for a real user, not just in isolation.
- [ ] `scripts/check.ps1` passes: typecheck, lint, tests, build.
- [ ] Loading, empty, error and success states exist.
- [ ] Server validates the same rules the form shows.
- [ ] Authorisation is checked on the server for this path.
- [ ] No `console.log`, no commented-out code, no `any`, no TODO without an owner.
- [ ] Committed on its own branch with a message that explains the why.
- [ ] `docs/plan.md` updated if the slice changed shape.

## Tests, proportional to risk

- **Unit**: pure logic, validators, formatters, permission rules. Fast, many.
- **Integration**: one happy path and one failure per endpoint, against a real
  database or a container. This is where most value is.
- **E2E**: only the 2-3 flows that lose money or trust if broken (signup, checkout,
  the core action). Playwright, run locally, not on every keystroke.
- Do not chase coverage numbers. Cover decisions, not lines.
- A bug fix starts with a failing test that reproduces it.

## Code review with yourself

Before saying "done", read your own diff as a stranger:

1. Could I delete a third of this file without losing behaviour?
2. Is the name of every variable the name a domain expert would use?
3. What happens on the second click, the slow network, the empty result, the 500?
4. Is there a second copy of this logic somewhere?
5. Would a new developer know where to add the next feature?

## Git

- Branch per slice: `bionic/<slug>`.
- Conventional commits: `feat(bookings): add cancellation with policy check`.
- One logical change per commit; no "wip" or "fixes" commits in the final history.
- Never commit `.env`, `node_modules`, build output, or database dumps.
- Do not rewrite history, do not force-push, do not merge to main unless asked.

## Reporting

Every slice ends with a short report to the user, in their language:

- What now works, and how to see it.
- What I ran to prove it (the actual command result, summarised).
- What is still stubbed.
- What I would do next.
