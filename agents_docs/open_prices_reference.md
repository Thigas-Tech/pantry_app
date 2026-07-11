# Open Prices API Reference

## Overview

Open Prices is a project to collect and share prices of food products worldwide. It is part of the Open Food Facts ecosystem.

- Production API: `https://prices.openfoodfacts.org/api/v1`
- Pre-production (staging): `https://prices.openfoodfacts.net/api/v1`
- Web interface: `https://prices.openfoodfacts.org`
- Source: `https://github.com/openfoodfacts/open-prices`
- License: OdBL (must attribute source, share-alike)

## Core Data Model

Four key objects:

| Object | Description | Key fields |
|--------|-------------|------------|
| `Proof` | Source evidence (receipt, shelf image, GDPR import) | `id`, `type`, `location_id`, `owner` |
| `Price` | A single price extracted from a proof | `id`, `product_code`, `price`, `currency`, `location_id`, `proof_id`, `date`, `type` |
| `Location` | Where the price was observed (OSM or online) | `id`, `osm_id`, `osm_type`, `osm_name`, `osm_brand`, `osm_lat`, `osm_lon` |
| `Product` | Linked OFF product (auto-created from barcode) | `id`, `code`, `product_name`, `brands`, `categories_tags` |

Relations:
- Prices belong to Proofs (many-to-one)
- Prices and Proofs belong to Locations (many-to-one)
- Prices link to Products via `product_code` (barcode)

## Authentication

Token-based (Bearer) authentication derived from an Open Food Facts account.

### Get a token

```
POST /api/v1/auth
Content-Type: multipart/form-data

username=<OFF_user_id>&password=<OFF_password>
```

Response:
```json
{
  "user_id": "username",
  "is_moderator": false,
  "access_token": "eyJhbGciOiJIUzI1Ni...",
  "token_type": "bearer"
}
```

Also accepts `access_token` (keycloak) instead of username/password.

### Use token

```
Authorization: bearer <token>
```

### Check session

```
GET /api/v1/session
Authorization: bearer <token>
```

### Delete/logout session

```
DELETE /api/v1/session
Authorization: bearer <token>
```

Note: Tokens must be stored securely (env var or user preferences). They are NOT obtained via a simple key generation endpoint — the user must authenticate with OFF credentials first.

## Prices Endpoints

All endpoints return paginated JSON (page, pages, total, items).

### List prices

```
GET /api/v1/prices?product_code=<barcode>&order_by=date&sort=desc
```

Query parameters:
| Parameter | Description |
|-----------|-------------|
| `product_code` | Exact barcode lookup |
| `product_code__in` | Comma-separated barcode list |
| `price__gte` / `price__lte` | Price range |
| `currency` | 3-letter code (EUR, USD...) |
| `date__gte` / `date__lte` | Date range (YYYY-MM-DD) |
| `date__year` / `date__month` | Filter by year/month |
| `location_id` | Exact location ID |
| `location_osm_id` | OSM node/way/relation ID |
| `location_osm_type` | OSM type (NODE, WAY, RELATION) |
| `location__type` | OSM or ONLINE |
| `proof_id` | Exact proof ID |
| `type` | PRICE type (PRODUCT or CATEGORY) |
| `owner` | Owner user ID |
| `ordering` | One of: id, price, date, created (prefix with `-` for desc) |
| `page` | Page number (1-based) |

Price response fields (PriceFullSerializer):
```json
{
  "id": 1,
  "type": "PRODUCT",
  "product_code": "1234567890123",
  "product_name": "Product name",
  "category_tag": null,
  "labels_tags": [],
  "origins_tags": [],
  "product": {
    "id": 1,
    "code": "1234567890123",
    "product_name": "Product name",
    "brands": "Brand",
    "categories_tags": ["en:category"]
  },
  "price": "4.990",
  "price_is_discounted": false,
  "price_without_discount": null,
  "discount_type": null,
  "price_per": null,
  "currency": "EUR",
  "location_osm_id": 12345,
  "location_osm_type": "NODE",
  "location": {
    "id": 1,
    "type": "OSM",
    "osm_id": 12345,
    "osm_type": "NODE",
    "osm_name": "Walmart",
    "osm_brand": "walmart",
    "osm_lat": "48.8566",
    "osm_lon": "2.3522",
    "osm_address_city": "Paris",
    "osm_address_country": "France",
    "osm_address_country_code": "FR"
  },
  "date": "2024-01-15",
  "proof": {
    "id": 1,
    "type": "RECEIPT",
    "location_id": 1,
    "owner": "username"
  },
  "receipt_quantity": null,
  "owner_comment": null,
  "owner": "username",
  "source": "api",
  "tags": [],
  "duplicate_of": null,
  "created": "2024-01-15T10:00:00Z",
  "updated": "2024-01-15T10:00:00Z"
}
```

### Get a single price

```
GET /api/v1/prices/<id>
```

### Create a price (authenticated)

```
POST /api/v1/prices
Authorization: bearer <token>
Content-Type: application/json

{
  "product_code": "1234567890123",
  "price": "4.99",
  "currency": "EUR",
  "proof_id": 1,
  "date": "2024-01-15",
  "location_osm_id": 12345,
  "location_osm_type": "NODE"
}
```

Required fields: `proof_id`, `product_code` (or `category_tag`)
Optional fields: `price`, `currency`, `date`, `location_osm_id`, `location_osm_type`, `location_id`, `price_is_discounted`, `discount_type`, `price_per`, `type`, `product_name`, `labels_tags`, `origins_tags`, `receipt_quantity`, `owner_comment`

Returns 201 with full price object. Validation errors return 400.

### Update a price (authenticated, owner only)

```
PATCH /api/v1/prices/<id>
Authorization: bearer <token>
```

### Delete a price (authenticated, owner or moderator)

```
DELETE /api/v1/prices/<id>
Authorization: bearer <token>
```

### Price stats

```
GET /api/v1/prices/stats?product_code=<barcode>
```

Response:
```json
{
  "price__count": 42,
  "price__min": "1.99",
  "price__max": "5.99",
  "price__avg": "3.50"
}
```

### Price history

```
GET /api/v1/prices/<id>/history
```

### Flag a price (for moderation)

```
POST /api/v1/prices/<id>/flag
Authorization: bearer <token>
```

## Locations Endpoints

### List locations

```
GET /api/v1/locations?type=OSM&osm_name__like=wal
```

Query parameters:
| Parameter | Description |
|-----------|-------------|
| `type` | OSM or ONLINE |
| `osm_name__like` | Case-insensitive name search (contains) |
| `osm_address_city__like` | City search |
| `osm_address_country__like` | Country search |
| `price_count__gte` / `price_count__lte` | Min/max price count |
| `ordering` | One of: id, created, price_count, user_count, product_count, proof_count |

Location response fields:
```json
{
  "id": 1,
  "type": "OSM",
  "osm_id": 12345,
  "osm_type": "NODE",
  "osm_name": "Walmart",
  "osm_display_name": "Walmart, 123 Main St, Paris, France",
  "osm_brand": "walmart",
  "osm_brand_logo_url": "https://...",
  "osm_address_postcode": "75001",
  "osm_address_city": "Paris",
  "osm_address_country": "France",
  "osm_address_country_code": "FR",
  "osm_lat": "48.8566000",
  "osm_lon": "2.3522000",
  "price_count": 42,
  "user_count": 5,
  "product_count": 30,
  "proof_count": 20,
  "source": "api",
  "created": "2024-01-01T00:00:00Z",
  "updated": "2024-01-15T10:00:00Z"
}
```

### Get a single location

```
GET /api/v1/locations/<id>
```

### Look up by OSM

```
GET /api/v1/locations/osm/<osm_type>/<osm_id>
```

### Nearby locations

```
GET /api/v1/locations/nearby?lat=48.8566&lon=2.3522&radius_km=10
```

### Compare two locations

```
GET /api/v1/locations/compare?location_id_a=1&location_id_b=2
```

### Create a location (authenticated)

```
POST /api/v1/locations
Authorization: bearer <token>
Content-Type: application/json

{
  "type": "OSM",
  "osm_id": 12345,
  "osm_type": "NODE"
}
```

Returns 201 (or 200 if duplicate found).

### List countries

```
GET /api/v1/locations/osm/countries
```

### List cities in a country

```
GET /api/v1/locations/osm/countries/<country_code>/cities
```

## Proofs Endpoints

### List proofs

```
GET /api/v1/proofs
```

### Create a proof (authenticated, required before submitting a price)

```
POST /api/v1/proofs
Authorization: bearer <token>
Content-Type: application/json

{
  "type": "PRICE_TAG",
  "location_osm_id": 12345,
  "location_osm_type": "NODE",
  "date": "2024-01-15",
  "currency": "EUR"
}
```

Required fields: `type`
Proof types: `PRICE_TAG`, `RECEIPT`, `RECEIPT_IN_PROCESS`, `SHELF`, `GDPR_IMPORT`, `SHOP_IMPORT`

## Products Endpoints

### List products

```
GET /api/v1/products?code=1234567890123
```

### Get by code

```
GET /api/v1/products/<id>
```

Products are auto-created when a price with a new barcode is submitted.

## Status / Health

```
GET /api/v1/status
```

No auth required. Returns `{"status": "ok"}`.

## Pagination

All list endpoints use Django REST Framework pagination:
```json
{
  "items": [...],
  "page": 1,
  "pages": 1,
  "total": 42,
  "size": 100
}
```

`size` can be set via `?size=<n>` parameter (max 100).

## Implementation Notes

- Token is generated via `POST /api/v1/auth` — NOT from OFF website directly. User must have an OFF account.
- The contact email for API rate limiting / issues is configured per app (see `AppConfig.contactEmail`).
- Price `product_code` uses normalized barcode (13-digit EAN or 8-digit UPC, no leading zeros).
- `proof_id` is required when creating prices. For our app, we create a "PRICE_TAG" proof for each manual price submission.
- Location can be specified via `location_osm_id` + `location_osm_type` (auto-creates Location record) or via existing `location_id`.
- `product_code` is the API field name for barcode — NOT `barcode`.
- All money amounts are decimal strings, not floats.
- Currency uses 3-letter ISO codes.
- The API is read-only without authentication (GET endpoints allow anonymous).
- Write operations (POST/PATCH/DELETE) require authentication.
- Discount types: QUANTITY, SALE, SEASONAL, LOYALTY_PROGRAM, EXPIRES_SOON, PICK_IT_YOURSELF, SECOND_HAND, OTHER.
- Price type: PRODUCT (has `product_code`) or CATEGORY (has `category_tag` instead).
