# Open Food Facts Submission Contract

Defines the exact contract between Pantry and the Open Food Facts (OFF)
write endpoints, recorded before changing the submission flow. Covers
metadata submission, image upload, authentication, app metadata, error
behavior, and the decision to keep the official SDK path.

Sources: official OFF API docs
(https://openfoodfacts.github.io/openfoodfacts-server/api/), the
tutorial-uploading-photo-to-a-product page, the openfoodfacts Dart SDK
3.30.2 source, and the smooth-app reference implementation.

## Decision: retain the SDK path

Pantry keeps the official openfoodfacts Dart SDK for both writes and
reads. No migration to a bespoke v3 client.

- Image upload: `OpenFoodAPIClient.addProductImage` POSTs to
  `/cgi/product_image_upload.pl`, which is exactly the endpoint still
  documented by the official upload tutorial. There is no separate v3
  image endpoint to migrate to.
- Metadata write: `OpenFoodAPIClient.saveProduct` POSTs to
  `/cgi/product_jqm2.pl`. The SDK's only v3 write path
  (`temporarySaveProductV3`, `PATCH /api/v3/product/$barcode`) supports
  only `packagings` / `packagings_complete`, not full product metadata,
  so v3 is not yet viable for metadata submission.
- Reads already use v3: `OpenFoodAPIClient.getProductV3` performs a GET
  to `/api/v3/product/$barcode`.

## Endpoints and auth

| Operation | SDK method | Endpoint | Method | Auth |
|-----------|------------|----------|--------|------|
| Fetch product | `getProductV3` | `/api/v3/product/{barcode}` | GET | read user, optional |
| Search | `searchProducts` | `/api/v2/search` | GET | read user, optional |
| Submit metadata | `saveProduct` | `/cgi/product_jqm2.pl` | POST form | `user_id` + `password` in body |
| Upload image | `addProductImage` | `/cgi/product_image_upload.pl` | POST multipart | `user_id` + `password` in fields |

Production host is `world.openfoodfacts.org`; staging is
`world.openfoodfacts.net`, selected by `AppConfig.useOffStaging`
(`lib/config.dart`). The adapter picks the matching
`off.UriProductHelper` (`off_adapter.dart`).

Authentication is per-request: `user_id` and `password` (not an email)
are sent in the body of every write. There is no session or bearer
token. Credentials come from `OFF_USER_ID` and `OFF_PASSWORD` in `.env`.
When they are empty, `OffAdapter.writeUser` returns null and every write
returns `false` without calling the network.

## App metadata

The SDK attaches app identity to every write via
`HttpHelper.addUserAgentParameters`:

- `app_name` — PantryApp
- `app_version` — the version from `OpenFoodAPIConfiguration.userAgent`
- `app_uuid` — installation UUID when configured
- `app_platform` — the OS name

This is configured in `lib/main.dart`. The helper throws if
`OpenFoodAPIConfiguration.userAgent` is null, so the configuration must
stay in place before any write is attempted.

## Metadata submission contract

`OffAdapter.submitProduct` maps `Product.toOffProduct()`
(`lib/models/product.dart`) to these form fields:

| OFF field | Source |
|-----------|--------|
| `code` | barcode |
| `product_name` | name |
| `brands` | brand |
| `categories` | category |
| `ingredients_text` | ingredients |
| `serving_size` | servingSize |

Optional `lc` (language) and `cc` (country) are not sent today; product
names submit exactly as stored. Success response is JSON with an integer
status: `{"status": 1}`. Any response whose status is not 1 is treated
as failure.

## Image upload contract

`OffAdapter.uploadProductImage` builds `off.SendImage`:

- `code` — barcode
- `imagefield` — one of `front`, `ingredients`, `nutrition` (mapped via
  `parseImageField`), optionally suffixed with the language tag, e.g.
  `ingredients_en`
- `lc` — the language code (defaults to English)
- file part key `imgupload_<imagefield>[_<lang>]` — the raw image bytes

Supported fields per OFF docs: `front`, `ingredients`, `nutrition`,
`packaging`, `other`, plus language suffixes (`front_en`). Minimum image
size is 640 x 160 px. Images must be user-owned under the CC BY-SA 3.0
license.

Success response is JSON: `{"imgid": 123, "status": "status ok", ...}`.
The status is a string, not an integer. `OffAdapter.isStatusOk`
normalizes both the integer `1` (metadata) and the string `status ok`
(image) forms.

## Behavior matrix

| Scenario | Behavior |
|----------|----------|
| Missing credentials | `writeUser` null; every write returns `false`, logs a warning, no network call |
| Wrong credentials | Server responds non-ok; the write returns `false`; `Status.isWrongUsernameOrPassword()` surfaces `Incorrect user name or password` |
| Duplicate barcode | Save is an upsert for the submitting user; re-submitting updates the existing product. The app adds a pre-submission check: a fresh manual product whose barcode already exists on OFF fails fast with a `duplicate` category and is never submitted or queued. Retries skip the check so partial submissions can recover |
| Validation error | A metadata-save response with status 400 or a non-empty `statusVerbose`/`error` is categorized `validation`; other non-ok responses stay `serverRejected` |
| Duplicate image field | New upload is stored; the newest selected photo of each field is displayed, older ones are kept |
| Already-uploaded image | A `status not ok` response carrying an `imgid` means the identical image already exists; the adapter treats it as success so retries do not loop |
| HTTP 429 rate limit | `isRateLimitStatus` detects it; write retries with a 5x linear backoff up to `maxRetries`, then returns `false` |
| Timeout / network error | SDK throws; adapter retries with linear backoff, then returns `false`. Each image upload is additionally bounded by a 60-second `.timeout` |
| Hung image upload | After 60 seconds the attempt is abandoned, retried up to `maxRetries`, then categorized `network` |
| Partial image success | `ProductSubmissionService` persists `partially_completed`; on retry it fetches the server state once and skips re-uploading fields that already have an image, then uploads only the missing ones |
| Large local image | `ProductImageCompressor` re-encodes photos to under 1 MB (JPEG, max side 1600 px, never below the 640 px minimum) in a background isolate before upload |
| File missing on disk | Image upload returns `false` without a network call |
| Logging | The OFF password is redacted from every log message via `redactSensitive`; local image paths are never logged |

## Retry and backoff

Both read and write paths retry up to `maxRetries = 2` (3 attempts) with
`retryDelay`: base `(attempt + 1)` seconds, plus or minus 25 percent
jitter, clamped to at least 500 ms. Rate-limited attempts multiply the
base delay by 5. Reads additionally never retry a
`ProductNotFoundException` (fail fast).

For writes, a rate limit surfaces as a non-ok `off.Status` (the HTTP
client does not throw on 429). The adapter inspects the status code and
response body so the retry path actually engages.

## Testability

The submission queue (`ProductSubmissionQueueDao`) takes an injectable
clock so `next_retry_at` backoff scheduling (2^retry minutes, capped at
24 h) is exercised deterministically in tests without waiting real
minutes. The adapter's `retryDelay` already accepts a seeded `Random` for
jitter, and every SDK call override lets tests simulate failures, hangs,
and rate limits without touching the network.

## Testing policy

Tests never write to production Open Food Facts. All adapter behavior is
exercised through injectable function overrides (`onSaveProduct`,
`onAddProductImage`, ...) in `test/services/off_adapter_test.dart`, and
the orchestration layer uses mocktail fakes in
`test/services/product_submission_service_test.dart`. Manual smoke tests
may target the staging server only.

## References

- OFF API docs: https://openfoodfacts.github.io/
- Upload tutorial:
  https://openfoodfacts.github.io/openfoodfacts-server/api/tutorial-uploading-photo-to-a-product/
- openfoodfacts Dart SDK 3.30.2 (source consulted): lib/src/open_food_api_client.dart,
  lib/src/utils/http_helper.dart, lib/src/model/status.dart,
  lib/src/model/send_image.dart
- smooth-app: https://github.com/openfoodfacts/smooth-app
