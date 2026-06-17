# MyEZ App — iOS Client

B2B iOS platform for EZ Inflatables customers. Turns inflatable equipment
ownership into a ranked loyalty experience — owned fleet, weight tiers,
monthly leagues, exclusive deals, and push notifications.

**Owner:** Javier Gomez — sole engineer, architect, and product owner.

---

## Live API

```
https://myez-odooapi-production.up.railway.app
```

---

## Stack

| Layer | Technology |
|---|---|
| iOS App | Swift, UIKit |
| API Middleware | FastAPI on Railway |
| ERP | Odoo 19 — ezinflatables.odoo.com |
| Realtime Database | Firebase Realtime Database |
| Auth (end users) | Firebase Auth (email/password) |
| Auth (admin) | Firebase Auth — myez-admin.web.app only |
| Cloud Jobs | Google Cloud Run |
| Push Notifications | FCM v1 |
| Product Images | Dropbox — shared folder links per SKU |
| Deal/Profile Images | Firebase Storage |
| App Shop | Odoo website via WebView |
| Admin Panel | Single HTML file on Firebase Hosting |

---

## Repos

| Repo | Description |
|---|---|
| github.com/javiergomezgit/MyEZ-App | iOS app (this repo) |
| github.com/javiergomezgit/myez-odoo-api | FastAPI middleware |
| github.com/javiergomezgit/ezclock-api | EZClock internal app |

---

## Setup

```bash
git clone https://github.com/javiergomezgit/MyEZ-App
cd MyEZ-App
pod install
open MyEZ.xcworkspace
```

---

## Key Views

| View | Description |
|---|---|
| LoginView | Firebase Auth email/password login + signup |
| ProfileView | Reads from Firebase — name, rank, owned weight, company |
| MyEZView | Virtual warehouse — owned units grid with Dropbox images |
| DealsView | Reads `dealsLinks` node, filters expired, sorts by `sort` |
| LeaderboardView | Top customers ranked by weight, personal placement row |
| GamificationView | Tier progress, distance to next tier, rank badge |
| DownloadUnitSheet | Fetches Dropbox link per SKU — manual + photo downloads |

---

## Auth Flow

1. User logs in via Firebase Auth (email + password)
2. Firebase UID used as primary identifier and node key
3. User data read from `users/{firebaseUID}/` in Firebase Realtime Database
4. FCM token registered to `users/{firebaseUID}/fcmTokens/{deviceKey}`

> iOS never calls Odoo directly. All Odoo XML-RPC is server-side via FastAPI.

---

## Firebase Structure

```
users/
  {firebaseUID}/
    uid: string                     — Firebase UID (primary key)
    partner_id: int                 — res.partner ID from Odoo
    name: string
    email: string
    phone: string
    zipCode: string
    company_name: string
    profile_image_url: string
    owned_weight: int               — cumulative lbs owned
    typeuser: string                — rank tier name
    activeAt: int                   — Unix timestamp
    createdAt: string
    createdIn: string               — "shopify" | "my_ez" | "web_shop" | "sm_manual"
    subscribed: bool
    fcmTokens/
      {deviceKey}: string
    units/
      {SKU}/
        qty: int
        product_id: int

dealsLinks/
  {timestamp}/
    name, sort, imageURL, emoji, actionType, actionValue, expiresAt

rank_cache/
  {partner_id}: string             — rank tier name
```

---

## Rank Tiers

| Rank | Owned Weight | Discount | Monthly Prize |
|---|---|---|---|
| Minimumweight | 0 lb | 0% | $20 credit |
| Flyweight | 1,000 lb | 2% | $40 credit |
| Bantamweight | 2,000 lb | 3% | $60 credit |
| Featherweight | 4,000 lb | 4% | $90 credit |
| Lightweight | 6,000 lb | 5% | $100 credit |
| Middleweight | 9,000 lb | 6% | $150 credit |
| Heavyweight | 13,000+ lb | 7% | $150 credit |

- Rank is permanent — never resets
- Discount applies automatically on every purchase
- Tier promotion fires a push notification + immediate discount upgrade
- App always shows lbs needed to reach next tier

---

## Monthly League System

- Leaderboard resets on the 1st of every month
- Each customer competes only within their own tier
- Top point earner wins store credit or equivalent catalog product
- Minimumweight customers compete from day one — no purchase required

### Points Engine (resets monthly)

| Action | Points |
|---|---|
| Purchase (per $1,000 spent) | 100 pts |
| Referring a new customer | 50 pts |
| Watching a product video | 20 pts |
| Sharing a deal | 15 pts |
| Reading an article | 10 pts |
| Daily login streak | 5 pts |
| Tapping a deal | 5 pts |

---

## User Registration — Phase 1 (3 paths)

### 1. Shopify Webhook
Trigger: `customers/create` → `POST /shopify/customer-created`
Creates Odoo portal user + Firebase entry. `createdIn: "shopify"`

### 2. MyEZ App Signup
Firebase Auth creates account → FastAPI creates Odoo records → Firebase write.
`createdIn: "my_ez"`

### 3. Sales Master CSV Import
```bash
python3 SM-Importer/sm_import.py --csv /path/to/clients.csv
```
CSV columns: Name, Company, Address, Address 2, City, State, Zip, Phone, Email, CreatedOn, SalesRep

- Skips rows missing email or name
- Duplicate email in Odoo → skip
- Same email twice in CSV → add delivery address to existing partner
- Firebase Auth user created silently, password reset link sent via Admin SDK
- `createdIn: "sm_manual"`

---

## FastAPI Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | /ping | Health check |
| GET | /clients/odoo | Client list from Odoo |
| GET | /clients/odoo/ranking | Clients ranked by weight |
| GET | /clients/owned-units/{partner_id} | Owned units + rank |
| GET | /products | Published products |
| GET | /products/image/{sku} | Dropbox shared folder URL |
| POST | /shopify/customer-created | Shopify webhook |
| POST | /notify/register-token | Register FCM token |
| POST | /notify/user/{partner_id} | Push to all user devices |
| POST | /gamification/check-rank-changes | Manual bulk rank check |

Full backend docs: github.com/javiergomezgit/myez-odoo-api

---

## Odoo Configuration

- **URL:** https://ezinflatables.odoo.com
- **DB:** devops-ghost-test-ezinflatables-main-14244209
- **Company ID:** 25 / **Portal Group ID:** 10
- **Portal user creation:** `"group_ids": [[6, 0, [10]]]` — Odoo 19 only
- Do NOT use: `groups_id`, `sel_groups_*`, `share: True` — broken in Odoo 19

---

## Railway Env Vars

```
ODOO_URL / ODOO_DB / ODOO_USER / ODOO_PASSWORD
FIREBASE_SERVICE_ACCOUNT    — base64-encoded service account JSON
SHOPIFY_WEBHOOK_SECRET
DROPBOX_TOKEN / DROPBOX_REFRESH_TOKEN
DROPBOX_APP_KEY             — z0wqyom5n6h3nbv
DROPBOX_APP_SECRET
```

---

## Live URLs

| Service | URL |
|---|---|
| FastAPI | https://myez-odooapi-production.up.railway.app |
| Firebase DB | https://myezfirebase.firebaseio.com |
| Admin Panel | https://myez-admin.web.app |
| Cloud Run | https://odoo-sync-o3ey4wctia-uc.a.run.app |
| Odoo | https://ezinflatables.odoo.com |

---

## Phase Roadmap

**Phase 1 — Live (Manual Bridge Mode)**
App is live. Registration automated. Orders and weight updates are manual
during transition from Sales Master to Odoo. Orders in Odoo do not
auto-sync to Firebase yet.

**Phase 2 — Planned (Full Odoo Migration)**
Shopify and Sales Master retired. Odoo becomes order engine and website
host. Purchases auto-trigger Firebase updates and gamification.

**Phase 3 — TBD** after Phase 2 ships.

---

## Active Backlog

| Task | Priority |
|---|---|
| Invoice email system (Gmail API) | High |
| Cloud Run sync job documentation | Medium |
| WebView browser margins | Low |

---

## Author

Javier Gomez — Senior Software Engineer
