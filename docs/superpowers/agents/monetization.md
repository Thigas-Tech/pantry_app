# App Monetization

Future-reference document for AdMob ads, in-app purchases, and cloud
backup. **Not yet implemented** — pending legal and accounting review.

## Status: deferred

All monetization features are deferred until a lawyer and accountant are
consulted. This document serves as the implementation reference when
the time comes.

Tracking issues #191 (AdMob), #192 (GDPR/LGPD consent), #193 (donations),
#194 (Pro subscription), #195 (Google Sign-In), and #196 (cloud backup)
are labeled `priority: low` to match this deferred status. They will be
re-scoped once the Google Play listing is live and the legal/accounting
review is complete.

## AdMob (banner and native ads)

### Overview

AdMob is the simplest monetization strategy. Banner ads are shown on
free-tier screens. Pro subscribers see no ads.

### Architecture

See ARCHITECTURE/SERVICES.md for the full service architecture. Summary:

- Package: `google_mobile_ads`
- Provider: planned `AdService` Riverpod provider
- Widgets: `AdBanner` (banner), `SearchNativeAd` (native in Search)
- Screens: Home, Product Detail, Settings, Stats (banner); Search (native, every 5th item)
- Ad unit IDs: from `.env`, test IDs in debug, production IDs in release

### Implementation checklist

- [ ] `flutter pub add google_mobile_ads`
- [ ] Add AdMob app ID to `AndroidManifest.xml` via manifest placeholder
- [ ] Add AdMob app ID to `Info.plist` (iOS, if applicable)
- [ ] Create `lib/services/ad_service.dart` (init, load banner, dispose)
- [ ] Create `lib/widgets/ad_banner.dart` (wraps `BannerAd`)
- [ ] Create `lib/widgets/search_native_ad.dart` (native ad)
- [ ] Insert `<AdBanner>` on Home, Product Detail, Settings, Stats
- [ ] Insert `<SearchNativeAd>` in Search results list
- [ ] Add test ad unit IDs to `.env.example`
- [ ] New ARB strings: `adLoading`, `adFailedToLoad`

### Pitfalls

- **LGPD consent is mandatory in Brazil before serving targeted ads.**
  The UMP consent flow (Phase 4) must ship together with ads.
- **Test ad IDs must be used in debug mode.** Loading real ad unit IDs
  during development triggers fraud detection and can get your AdMob
  account suspended.
- **Ad load failure shows blank space.** The `AdBanner` widget must
  collapse or show a placeholder when no ad is available.
- **Ad placement near interactive elements violates AdMob policy.**
  Bottom banner can't be too close to the FAB or nav bar items.
- **Banner takes 50–90dp** of vertical space. Existing golden tests
  at 360dp will need regeneration.

## GDPR / LGPD consent (UMP SDK)

### Overview

Google's User Messaging Platform (UMP) SDK must be integrated to obtain
consent before serving personalized ads in regions requiring it (EU GDPR,
Brazil LGPD, California CCPA).

### Implementation checklist

- [ ] Initialize UMP SDK in `AdService` on first launch
- [ ] Request consent info update
- [ ] Show consent form if required
- [ ] Load ads only after consent is obtained
- [ ] Add "Ad Preferences" button in Settings (re-opens consent dialog)
- [ ] Privacy policy link in Settings > About
- [ ] New ARB strings: `adConsentTitle`, `adConsentBody`,
  `adPreferences`, `privacyPolicy`
- [ ] Publish privacy policy URL (required for Play Store listing)

### Pitfalls

- **Consent must be obtained before any ad loads.** The `AdService` init
  must gate on consent status.
- **UMP SDK needs network access.** If the consent form fails to load,
  default to non-personalized ads.
- **Test consent form requires debug device ID.** The form won't appear
  on test devices without it.

## In-App Purchases (donations)

### Overview

Three consumable donation tiers set up in Play Console. No subscription
logic — one-time purchases only.

### Product IDs (to create in Play Console)

| Product ID | Price |
|---|---|
| `donation_small` | $2.99 |
| `donation_medium` | $4.99 |
| `donation_large` | $9.99 |

### Implementation checklist

- [ ] `flutter pub add in_app_purchase`
- [ ] Create `lib/services/donation_service.dart`
- [ ] Add "Support Development" section in Settings
- [ ] Three donation buttons (one per tier)
- [ ] Purchase flow: initiate, listen for updates, consume on success
- [ ] Show thank-you snackbar on successful donation

## Pro subscription (auto-renewing)

### Overview

Monthly and yearly auto-renewing subscriptions that remove all ads and
enable cloud backup (Firebase).

### Product IDs (to create in Play Console)

| Product ID | Price | Period |
|---|---|---|
| `pro_monthly` | $0.99 | Monthly |
| `pro_yearly` | $9.99 | Yearly |

### Implementation checklist

- [ ] Add subscription products to Play Console
- [ ] Extend `DonationService` with subscription purchase flow
- [ ] Add `isPro` check via `queryPastPurchases()`
- [ ] Gate cloud backup behind Pro subscription
- [ ] Hide all ads when `isPro` is true
- [ ] Handle subscription cancellation/expiry gracefully

## Firebase cloud backup

### Overview

Pro subscribers can back up their local SQLite database to Firebase
Storage and restore it on a new device.

### Implementation checklist

- [ ] Create Firebase project at https://console.firebase.google.com/
- [ ] Register Android app with package `com.thigas_tech.pantry_app`
- [ ] Download `google-services.json` to `android/app/`
- [ ] `flutter pub add firebase_core firebase_auth firebase_storage`
- [ ] `flutter pub add google_sign_in`
- [ ] Enable Google Sign-In in Firebase Console
- [ ] Create `lib/services/firebase_service.dart` (init, Auth, Storage)
- [ ] Create `lib/services/cloud_backup_service.dart` (export, restore)
- [ ] Create `lib/screens/cloud_backup_screen.dart` (UI)
- [ ] Firebase Storage security rules
- [ ] New ARB strings for backup: `backup`, `restore`, `lastBackup`,
  `backupFailed`, `restoreFailed`, `signInRequired`, `proRequired`

## References

- [google_mobile_ads](https://pub.dev/packages/google_mobile_ads)
- [AdMob quick start](https://developers.google.com/admob/flutter/quick-start)
- [UMP SDK GDPR guide](https://developers.google.com/admob/flutter/privacy/gdpr)
- [in_app_purchase](https://pub.dev/packages/in_app_purchase)
- [Play Billing subscriptions](https://developer.android.com/google/play/billing/subscriptions)
- [Firebase Flutter setup](https://firebase.flutter.dev/docs/overview)
- [Firebase Storage](https://firebase.google.com/docs/storage)
- [ARCHITECTURE/SERVICES.md](../../ARCHITECTURE/SERVICES.md)
