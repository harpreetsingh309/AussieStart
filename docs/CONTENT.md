# Content Schema

## Article front-end format

Every guide should follow this outline in Markdown:

1. Title (from catalog; H1s inside body are section titles)
2. Overview
3. Why this matters
4. When to do it
5. Requirements
6. Step-by-step guide
7. Common mistakes
8. FAQs
9. Useful terms
10. Official links
11. Related articles (also listed in catalog `relatedArticles`)

## Catalog entry

```json
{
  "id": "transport-card",
  "title": "Public transport card",
  "subtitle": "Myki, Opal, go card, and other state cards",
  "category": "transport",
  "states": ["all"],
  "keywords": ["myki", "opal", "transport"],
  "estimatedReadingMinutes": 6,
  "relatedArticles": ["housing-rent"],
  "file": "transport-card.md",
  "lastUpdated": "2026-07-28",
  "popularRank": 5
}
```

`states`: `["all"]` or a list like `["vic","nsw"]`.

## State blocks

```markdown
<!-- state:vic,nsw -->
Shared notes for VIC and NSW
<!-- /state -->
```

## Placeholders

| Token | Example |
|-------|---------|
| `{{state.name}}` | Victoria |
| `{{state.short}}` | VIC |
| `{{state.transport}}` | Myki |

## Review rule

Every article must include a `lastUpdated` date and link to at least one official source. Content is informational only.
