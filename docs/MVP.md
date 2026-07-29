# AussieStart MVP Cut

## Goal

Ship a polished offline iOS app that helps Indian new arrivals complete their first 30 days with state-aware guidance.

## In scope for v1.0

- English UI + Hindi/Punjabi string stubs
- 40–60 priority articles (starter pack ships 12; expand in content phase)
- States: all 8, with transport/licence variance in Markdown
- Onboarding → Home → Search → Topics → Saved → Settings
- First 30 Days journey + checklists
- Synonym search
- Privacy-first (no login, no required analytics)

## Explicitly out of scope for v1.0

- Backend / accounts / sync
- StoreKit premium
- AI assistant
- Voice search
- Community Q&A
- Full 10-language article translations
- Apple Watch

## Success metrics (from product plan)

- 10k downloads · 4.8★ · 40% WAU · session > 6m · 70% onboarding completion

## Build phases (compressed)

1. **Foundation** — architecture, navigation, SwiftData, Markdown, theme ✅
2. **Core features** — categories, reader, search, bookmarks, tips, state ✅
3. **Guided experience** — 30-day journey, checklists, history, related ✅
4. **Content** — expand to 40–60 reviewed articles; HI/PA priority translations
5. **Polish** — accessibility audit, icon, screenshots, animations
6. **TestFlight → App Store**

## Technical notes

- iOS 17+, SwiftUI, SwiftData
- ContentLoader resolves state blocks at read time
- LocalSearchEngine expands synonyms from `catalog.json`
- Regenerate Xcode project: `python3 scripts/generate_xcodeproj.py`
