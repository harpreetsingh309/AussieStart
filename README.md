# AussieStart

Local-first iOS settlement companion for new migrants to Australia.

> **The Complete Australia Starter Guide in Your Pocket.**

## Open & run

```bash
cd ~/Desktop/AussieStart
python3 scripts/generate_xcodeproj.py   # regenerate project if files change
open AussieStart.xcodeproj
```

In Xcode: select an iPhone simulator → **Run**.

- **Platform:** iOS 17+
- **Stack:** SwiftUI · MVVM · SwiftData · offline Markdown
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
| EN / HI / PA string stubs | Done |
| Premium / StoreKit | Deferred |
| Full Hindi/Punjabi article translations | Deferred |

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
