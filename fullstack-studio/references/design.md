# Design direction

A site must look like it was built for this client, not generated. That is a
process, not a talent: fix a direction once, then obey it on every screen.

## Step 1 - Direction (write it down before any UI)

Fill this in `docs/design.md`:

- **Three adjectives** for how it should feel (e.g. calm, editorial, tactile).
- **One reference** the user gave, or one you choose, with the exact reason.
- **Palette**: background, surface, border, text, muted text, one accent, one danger.
- **Type**: a display face for headings, a text face for body. Two families maximum.
- **Layout rule**: one sentence that governs every page (e.g. "content column 68ch,
  full-bleed imagery between sections", "asymmetric 5/7 grid").
- **Motion rule**: what moves, how long, and what never moves.
- **Density**: airy or dense. Decide once.

## Step 2 - Tokens

Define tokens in one file and use them everywhere - no raw hex in components.

```css
:root {
  --bg: #0b0b0c;
  --surface: #141416;
  --border: #26262b;
  --text: #f2f2f3;
  --muted: #9a9aa2;
  --accent: #c9f24d;
  --danger: #ff5c5c;

  --space-1: 4px;  --space-2: 8px;  --space-3: 12px; --space-4: 16px;
  --space-5: 24px; --space-6: 32px; --space-7: 48px; --space-8: 64px;

  --radius: 10px;
  --font-display: "Fraunces", serif;
  --font-body: "Inter", sans-serif;
  --measure: 68ch;
}
```

Type scale: 12 / 14 / 16 / 20 / 25 / 31 / 39 / 49 px (roughly 1.25 ratio).
Body text 16-18px, line-height 1.5-1.6, headings 1.1-1.2.

## Anti-generic checklist

Anything below is the default AI look. Replace it deliberately:

- Inter everywhere, indigo-to-purple gradient, glassmorphism cards.
- Centered hero + three identical feature cards + "Trusted by" logo strip of fake logos.
- Emoji used as icons. Use a real icon set (Lucide) or nothing.
- Lorem ipsum, "Revolutionize your workflow", "Unlock the power of".
- Every section the same width, same padding, same rhythm.
- Rounded-rectangle buttons with a shadow on every surface.
- Dark mode invented as an afterthought with inverted colours.

Instead: one strong idea per page, real copy from the brief, a layout that carries
meaning (a table that looks like a table, a schedule that looks like a schedule).

## Content rules

- Every string comes from the brief or the user. Placeholders must be obviously
  marked `TODO(content)` and listed in the handoff.
- Write microcopy for empty, loading, and error states - not only the happy path.
- Numbers, dates, and currency formatted with `Intl`.

## Accessibility floor

- Contrast 4.5:1 for body text, 3:1 for large text.
- Visible focus ring, never `outline: none` without a replacement.
- Keyboard reachable: every action usable with Tab/Enter/Escape.
- Real `<button>` / `<a>`, labelled inputs, `alt` text that says something.
- Respect `prefers-reduced-motion` and `prefers-color-scheme` if dark mode exists.

## Arabic and RTL

- `<html lang="ar" dir="rtl">`; use logical CSS properties (`margin-inline-start`,
  `padding-inline`, `inset-inline`) instead of left/right.
- Mirror directional icons (arrows, chevrons) with `transform: scaleX(-1)` or a
  direction-aware icon set; do not mirror logos or clocks.
- Arabic needs a taller line-height (1.7-1.8) and a font that actually has Arabic
  glyphs - test the pair, do not assume the Latin face covers it.
- Numbers and latin words inside Arabic text: keep them LTR with `dir="auto"` where
  the string is mixed.
