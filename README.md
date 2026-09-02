# AussieStart

Local-first iOS settlement companion for new migrants to Australia.

> **The Complete Australia Starter Guide in Your Pocket.**

## Open & run

```bash
cd ~/Desktop/AussieStart
python3 scripts/generate_xcodeproj.py   # regenerate project if files change
open AussieStart.xcodeproj
```

`generate_xcodeproj.py` derives its root from its own location and reads the
language list from `AussieStart/Resources/Localization/*.lproj`, so adding a
language means creating the folder and re-running it — no edit to the script.

In Xcode: select an iPhone simulator → **Run**.

- **Platform:** iOS 17+
- **Stack:** SwiftUI · MVVM · SwiftData · offline Markdown
- **Languages:** 11 (Arabic is right-to-left; layout direction follows the choice)
- **Bundle ID:** `com.aussiestart.app`

## What's included (MVP)

| Area | Status |
|------|--------|
| Onboarding (language / state / persona / roadmap) | Done |
| Home (tip, journey, popular, emergency) | Done |
| Search with synonym expansion | Done |
| Categories + article reader | Done |
| Bookmarks + reading history | Done |
| Checklists + First 30 Days journey | Done |
| State-aware Markdown (`<!-- state:vic -->`) | Done |
| Offline content pack (12 starter guides) | Done |
| 11-language interface (EN, Mandarin, Arabic, Vietnamese, Cantonese, PA, Italian, Greek, HI, Spanish, Nepali) | Done |
| Premium / StoreKit (non-consumable Pro unlock) | Done |
| Translated Markdown guides (EN / HI / PA only — others fall back to English) | Partial |
| History & Culture guides incl. First Peoples and Country | Done |

## Content schema

- `AussieStart/Resources/Content/catalog.json` — articles, tips, journey, checklists, synonyms, emergency contacts
- `AussieStart/Resources/Content/articles/*.md` — Markdown guides
- State blocks:

```markdown
<!-- state:vic -->
Victoria-specific Myki notes
<!-- /state -->
```

Placeholders: `{{state.name}}`, `{{state.short}}`, `{{state.transport}}`

See [docs/MVP.md](docs/MVP.md) and [docs/CONTENT.md](docs/CONTENT.md).

## Privacy

No account. No cloud. Bookmarks and progress stay on-device. Analytics off by default.

## Disclaimer

Informational only — not legal, migration, financial, or medical advice. Verify with official Australian Government sources.
