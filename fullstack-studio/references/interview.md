# Interview

Goal: turn "I want a website" into a brief you could hand to another developer.
Ten good questions beat forty mediocre ones.

## Order matters

Ask in this order, because each answer changes the next question:

1. **Purpose** - what does this site do for its owner? (sell, book, publish, manage, impress)
2. **People** - who uses it, and who is allowed to see what?
3. **Core screens** - the 3-5 screens without which it is useless.
4. **Data** - what is stored, who creates it, who edits it.
5. **Money and accounts** - login? roles? payments? subscriptions?
6. **Content and language** - who writes the text? Arabic, English, both? RTL?
7. **Constraints** - deadline, budget, hosting, existing brand or logo, devices.

## How to ask

- Three questions per message, numbered, short, with a suggested default.
- Plain words, no jargon. Not "do you need SSR?" but "will people find these pages
  on Google, or is it for logged-in users only?"
- Offer two or three concrete options instead of an open field.
- Reflect ambiguity back: "So anyone can upload, and only admins approve - correct?"
- Never ask something the answer to which does not change a decision.

## Red flags to probe

| They say | Ask next |
|---|---|
| "like Airbnb/Amazon" | which single flow matters most on day one? |
| "make it beautiful" | show me one site you like; what exactly do you like about it? |
| "it should be fast" | how many users at launch, in one year? |
| "with AI" | what does the AI do that a form cannot? |
| "admin panel too" | which three things does the admin actually change? |
| "secure" | who must not see what? |

## Stop condition

You can finish these sentences without guessing:

- The site exists so that ______ can ______.
- The five core screens are ______.
- We store ______, and only ______ can edit it.
- Authentication is ______ (or: there is none, and that is deliberate).
- It runs on ______.

## Output: docs/brief.md

```markdown
# <Project> - brief

## One line
<who it is for and what it does>

## Users and roles
- visitor: ...
- member: ...
- admin: ...

## Screens
1. /path - purpose - key actions
2. ...

## Data
- Entity: fields, relations, who creates it

## Non-functional
- languages: Arabic (RTL) / English
- devices: mobile first?
- expected volume: ...
- hosting: ...

## Decisions taken for the user
- <decision> - <reason>

## Explicitly out of scope
- ...
```
