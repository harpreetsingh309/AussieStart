# AussieStart — App Store submission

Use this file while creating the app record, in-app purchase, and first 1.0.0 build in App Store Connect.

**Status:** project is signed for team **Harpreet Singh RHK Solutions PTY LTD** (`6757XQF27Y`). Local StoreKit purchase/restore is covered by `AussieStartTests`. Live App Store products still need the same product ID in App Store Connect.

---

## Identity

| Field | Value |
| --- | --- |
| App name | AussieStart |
| Subtitle (30 characters) | Australia starter guide |
| Bundle ID | `com.aussiestart.app` |
| SKU | `aussiestart-ios` |
| Primary language | English (Australia) |
| Category | Reference (Lifestyle as secondary if asked) |
| Age rating | 4+ |
| Platforms | iPhone and iPad |
| Minimum OS | iOS 17.0 |
| Version | 1.0.0 |
| Build | 1 (`CURRENT_PROJECT_VERSION`) |
| Price | Free, with one paid unlock |

Copyright: © 2026 RHK Solutions PTY LTD

---

## What the app is (reviewer summary)

AussieStart is an **offline information app** for people settling in Australia. It explains first-week tasks (airport, SIM, bank, TFN, transport, emergencies) and later official-site steps. Content is Markdown bundled in the app.

It does **not**:

- log into myGov, ImmiAccount, Centrelink, ATO, Medicare, or any government site
- lodge visas, tax, bonds, or claims
- sell insurance, SIMs, or other products
- require an account or send settlement data to a server

Users open official `.gov.au` pages themselves. Pro is a **one-time non-consumable** that unlocks extra guides plus share/print of First 30 Days and optional on-device reminders.

---

## Listing copy (English Australia)

### Promotional text (170 characters)

Your first 30 days in Australia, offline on your phone. Airport to TFN, SIM, bank, transport, and official .gov.au links — in English, Hindi, and Punjabi.

### Description

AussieStart is a practical starter guide for new arrivals, students, workers, families, and visitors. It stays on your iPhone or iPad — no account, no feed, no ads.

**First week, without the guesswork**
- Airport arrival, biosecurity, and getting into the city
- Local SIM or eSIM, bank account, TFN, and your state’s transport card
- Emergency 000, Medicare GP visits, and OSHC basics for students
- Rent, jobs, and driving rules explained in plain language

**A First 30 Days roadmap**
Home and the journey list filter by who you are (student, worker, family, visitor) and which state you chose. Tick tasks as you go. Everything stays on this device.

**Clear guides, official links**
Each guide covers why it matters, when to do it, what you need, step-by-step, common mistakes, and FAQs. Tappable .gov.au links open the real government site — AussieStart never logs in for you.

**English, हिन्दी, and ਪੰਜਾਬੀ**
The app UI and priority guides are available in English, Hindi, and Punjabi.

**AussieStart Pro (optional, one-time)**
Unlock later settlement guides: myGov, visa work rights, super, utilities, rental bond, scams, tax, Medicare enrolment, ImmiAccount, Centrelink claims, PPSR, contents insurance, private health waiting periods, OVHC, tolls, car insurance types, ambulance cover, and more. Pro also lets you share or print your First 30 Days list and turn on weekly reminders on this device.

Informational only — not legal, migration, financial, or medical advice. Always verify critical steps with official Australian Government sources. AussieStart is not affiliated with the Australian Government.

### Keywords (100 characters max, no spaces after commas)

```
australia,migrant,visa,tfn,medicare,myki,settlement,hindi,punjabi,student
```
(89 characters)

### What's New (1.0.0)

First release: offline first-week guides, a First 30 Days roadmap, English / Hindi / Punjabi, and optional AussieStart Pro for extra official-site guides.

---

## In-app purchase

Create the product **before** submitting the binary. The app looks up this exact ID.

| Field | Value |
| --- | --- |
| Type | Non-Consumable |
| Product ID | `com.aussiestart.app.pro` |
| Reference name | AussieStart Pro |
| Price | AUD $9.99 (tier that maps to 9.99 in Australia) |
| Availability | All countries you ship the app in |
| Display name (en-AU) | AussieStart Pro |
| Description (en-AU) | One-time unlock of extra settlement guides: private health waiting periods, OVHC, tolls, car insurance, ambulance cover, myGov, visa rights, super, official bond lodgement, utilities, scams, tax, PPSR, and more. Informational only — AussieStart never lodges government forms or sells insurance. |
| Review screenshot | `AppStore/screenshots/iap-640x920/aussiestart-pro.png` (640 × 920) |
| Review notes | Local StoreKit file `AussieStart/Configuration/Products.storekit` uses the same product ID. Purchase and Restore are on Settings → AussieStart Pro. |

Family sharing: off (matches the StoreKit config).

Local testing: the AussieStart scheme attaches `Products.storekit` (locale `en_AU`, storefront Australia). Run `AussieStartTests` for load / purchase / restore. On a device, use a Sandbox Apple ID after the product is created in App Store Connect.

---

## Privacy (App Store Connect questionnaire)

**Privacy policy URL:** https://rhksolutions.com.au/aussiestart/privacy/

**Support URL:** https://rhksolutions.com.au/aussiestart/support/

**Marketing URL (optional):** https://rhksolutions.com.au/aussiestart/

Hosted on the RHK Solutions site. Source copy lives in `docs/legal/` in this project. Contact: support@rhksolutions.com.au.

Answer **No** to tracking. Data collection:

| Type | Linked to identity? | Used for |
| --- | --- | --- |
| Purchases (App Store) | Yes, by Apple | App functionality (unlock Pro on this Apple ID) |
| Nothing else | — | AussieStart does not run its own backend |

Declare that you do **not** collect contact info, location, health, browsing history, or user content on your servers. Bookmarks, checklist ticks, and journey progress are **on-device only** (UserDefaults / SwiftData).

Privacy Nutrition Label: Purchases → App Functionality. No tracking. No third-party analytics.

`PrivacyInfo.xcprivacy` already declares:

- UserDefaults `CA92.1`
- File timestamp `C617.1`
- `NSPrivacyTracking` = false
- empty collected-data array from the app itself

Export compliance: **ITSAppUsesNonExemptEncryption = false** (standard HTTPS only).

---

## Privacy policy page (host this)

**AussieStart Privacy Policy**  
Last updated 19 August 2026

AussieStart is published by RHK Solutions PTY LTD. The app does not require an account.

**What stays on your device.** Bookmarks, reading history, search history, checklist ticks, First 30 Days progress, language, state, and persona are stored on the device. We do not operate a server that receives your settlement data.

**Purchases.** If you buy AussieStart Pro, Apple processes the payment. The app stores an App Store entitlement on the device so Pro guides unlock. We do not receive your card number.

**Notifications.** Optional weekly reminders are scheduled locally with Apple’s notification APIs. They are not sent through our servers.

**Not a government service.** We cannot see, change, or apply for visas, myGov, TFN, Medicare, Centrelink, licences, or bonds. Use official .gov.au websites for those steps.

**Contact.** Email support@rhksolutions.com.au for content corrections.

---

## Age rating

- No unrestricted web, gambling, or user-generated content
- Infrequent/mild references to scams and emergency services (000)
- Suggested rating: **4+**

---

## App Review notes

```
AussieStart is an offline settlement guide. There is no login.

To test the free app:
1. Complete onboarding (English, any state, any persona).
2. Open Home, First 30 Days, Topics, and a free guide such as “Get a local SIM or eSIM”.
3. Official links open in Safari. The app never signs into government services.

To test AussieStart Pro (non-consumable, com.aussiestart.app.pro, $9.99 AUD):
1. Settings → Unlock AussieStart Pro.
2. Purchase with a sandbox Apple ID.
3. Confirm a previously locked guide (for example myGov) opens.
4. Settings → Restore purchases also works after delete/reinstall.

Demo account: none. Username/password: none.

The app is not affiliated with the Australian Government. Content is informational only.
```

Support URL: https://rhksolutions.com.au/aussiestart/support/  
Marketing URL: https://rhksolutions.com.au/aussiestart/  
Privacy Policy URL: https://rhksolutions.com.au/aussiestart/privacy/

Contact: Harpreet Singh, RHK Solutions PTY LTD.

---

## Archive checklist

1. Confirm signing team `6757XQF27Y` and bundle `com.aussiestart.app`.
2. Version 1.0.0, build 1 (bump build for each upload).
3. Product `com.aussiestart.app.pro` is **Ready to Submit** in App Store Connect.
4. In Xcode: **Product → Archive** (generic iOS device), then Distribute → App Store Connect.
5. Attach screenshots below. Prefer 6.9" iPhone **and** 6.5" if you want both wells filled; Apple currently requires a 6.9" set for new iPhone apps and a 13" set because iPad is enabled.
6. Submit for review with the notes above.

Regenerate the Xcode project after adding files:

```bash
python3 scripts/generate_xcodeproj.py
```

Local IAP tests (StoreKit config is on the scheme; Product ID must stay `com.aussiestart.app.pro`):

```bash
# Preferred: Product → Test in Xcode with Products.storekit attached.
xcodebuild -project AussieStart.xcodeproj -scheme AussieStart \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' \
  -only-testing:AussieStartTests test
```

If `xcodebuild test` fails to launch the runner (Mach -308), run `AussieStartTests` from Xcode’s Test navigator. Purchase and Restore also work in Simulator when the scheme StoreKit file is enabled: Settings → Unlock AussieStart Pro.

---

## Screenshots to upload

PNG, RGB, no transparency. Featured text is already on the files.

| Slot | Size | Folder |
| --- | --- | --- |
| iPhone 6.5" | 1284 × 2778 | `AppStore/screenshots/iphone-6.5/` |
| iPhone 6.9" (required for new apps) | 1320 × 2868 | `AppStore/screenshots/iphone-6.9/` |
| iPad 13" | 2064 × 2752 | `AppStore/screenshots/ipad-13/` |
| IAP review image | 640 × 920 | `AppStore/screenshots/iap-640x920/` |

Suggested order (same captions on every size):

1. Your Australia starter guide
2. First 30 Days, mapped
3. Clear steps. Official .gov.au links.
4. English · हिन्दी · ਪੰਜਾਬੀ
5. Unlock AussieStart Pro
6. Every topic, in one place
7. Weekends worth seeing

Rebuild from live Simulator captures:

```bash
python3 scripts/capture_app_store_screenshots.py
```

That boots iPhone 16 Plus and iPad Pro 13-inch (M4), screenshots Home / First 30 Days / a guide / Settings / Pro / Topics / Explore, then writes the sized PNGs. Overlay-only rebuild:

```bash
python3 scripts/compose_app_store_screenshots.py
```
