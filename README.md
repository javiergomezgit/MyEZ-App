# MyEZ App — iOS Client

SwiftUI iOS app for EZ Inflatables customers. Displays owned inflatables,
gamified customer rankings, order history, and product browsing — all powered
by a live FastAPI middleware layer connected to Odoo ERP.

## Live API
https://myez-odoo-api-production-87b0.up.railway.app

## Stack

- **SwiftUI** — iOS UI framework
- **URLSession** — REST API consumption
- **Firebase** — push notifications (planned)
- **FastAPI middleware** — backend data layer (separate repo)
- **Odoo ERP** — source of truth for clients, orders, and rankings

## Features

- **DealsView** — live client ranking data fetched from Railway API
- **Pull to refresh** — triggers live re-fetch from Odoo via middleware
- **Loading states** — skeleton UI during fetch
- **Error handling** — graceful failure with user-facing messaging
- **Gamification** — customer rank tiers based on total inflatable weight owned
- **Owned products** — grid view of customer's purchased inflatables
- **Leaderboard** — top customers ranked by weight with personal placement row

## Rank Tiers

| Rank | Weight Threshold |
|------|-----------------|
| Minimumweight | < 2,500 lb |
| Flyweight | < 5,000 lb |
| Bantamweight | < 7,500 lb |
| Featherweight | < 10,000 lb |
| Lightweight | < 12,500 lb |
| Welterweight | < 15,000 lb |
| Middleweight | < 17,500 lb |
| Cruiserweight | < 20,000 lb |
| Heavyweight | 20,001 lb+ |

## Architecture

iOS (SwiftUI) → REST HTTP GET → FastAPI (Railway) → XML-RPC → Odoo ERP

See backend repo: https://github.com/javiergomezgit/myez-odoo-api

## Setup
```bash
git clone https://github.com/javiergomezgit/MyEZ-App
cd MyEZ-App
pod install
open MyEZ.xcworkspace
```

## Author
Javier Gomez — Senior Software Engineer
