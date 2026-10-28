# Skills pack

Three agent skills for Claude Code, Codex, or any agent that reads `SKILL.md`.
Plain Markdown plus one PowerShell script per skill. No dependencies, no network calls.

| Skill | What it does |
|---|---|
| [`fullstack-studio`](fullstack-studio/) | Builds complete websites and web apps: interview, plan, design direction, frontend + backend + database, security pass, handoff. |
| [`client-proposal`](client-proposal/) | Turns a client conversation into a scoped proposal: deliverables, exclusions, estimate with buffer, payment terms, three-tier pricing. |
| [`desktop-control-consent`](desktop-control-consent/) | Operates the Windows desktop - screenshot, click, type, focus windows, open apps - through fixed PowerShell scripts, after the user approves the task. |

## Install

Global (every project):

```bash
cp -r fullstack-studio client-proposal desktop-control-consent ~/.claude/skills/
```

Per project:

```bash
mkdir -p .claude/skills
cp -r fullstack-studio client-proposal desktop-control-consent .claude/skills/
```

PowerShell:

```powershell
Copy-Item -Recurse -Force fullstack-studio, client-proposal, desktop-control-consent "$env:USERPROFILE\.claude\skills\"
```

Restart the agent, then trigger a skill with `@skill-name` or just describe the task.

## How each one works

### fullstack-studio

Six phases, each with a gate. The agent interviews you first, then writes
`docs/brief.md`, `docs/plan.md` and `docs/design.md` before any code.

- Six references: interview, stack selection, design direction, frontend, backend, security, quality, debugging.
- `scripts/check.ps1` - the quality gate. Detects typecheck, lint, test and build scripts and runs them; exits non-zero on failure.
- Two reference files in `examples/` showing the expected code quality (not scaffolding).

Key rules: no invented requirements, no "done" without a green check, one source of truth, every slice is a full vertical path (data + API + UI).

### client-proposal

Discovery, scope, estimate, terms, then a client-facing proposal with three tiers.

- `references/discovery.md` - what to ask and what the answers mean.
- `references/scope.md` - deliverables with acceptance criteria, plus an explicit "not included" list.
- `references/pricing.md` - estimation method, buffer, tiers, payment schedule.
- `references/terms.md` - payment, revisions, ownership, delays, cancellation.
- `scripts/quote.ps1` - quote arithmetic with buffer, tax, deposit and tier suggestions. Refuses to run without a rate, because the freelancer's rate is never invented.

### desktop-control-consent

Approval-scoped desktop automation for Windows.

- `scripts/pc.ps1` - actions: `screenshot`, `click`, `move`, `type`, `keys`, `open`, `windows`, `focus`, `clipboard`, `sleep`.
- `-Title` guard: refuses to type unless the foreground window matches, so keystrokes cannot land in the wrong app.
- `-DryRun` prints what would happen without touching the desktop.
- Every action is appended as JSON to `%LOCALAPPDATA%\pc-control\actions.log`.
- Typing uses the clipboard and restores it, because keystroke-by-keystroke input is mapped through the keyboard layout and breaks Arabic and other non-Latin text.
- Hard limits: 25 actions per task, no deleting files, no registry edits, no elevation, no passwords.

## Requirements

- `fullstack-studio` and `client-proposal` are documentation-first and work anywhere.
- The PowerShell scripts need Windows with PowerShell 5.1+ (they use .NET and Win32 APIs).
- `desktop-control-consent/scripts/pc.ps1` needs an interactive desktop session.

## Verified

- `pc.ps1`: screenshot, window list, focus, typing (including Arabic), key combos, and file save verified on disk.
- `check.ps1`: verified to pass and to fail correctly on a sample project.
- `quote.ps1`: verified arithmetic and the missing-rate guard.
