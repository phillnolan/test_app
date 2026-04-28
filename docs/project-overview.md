# sinhvien-app - Tá»•ng quan dá»± Ã¡n

**NgÃ y quÃ©t:** 2026-04-02T14:13:05+07:00  
**Loáº¡i repo:** Monorepo 2 pháº§n  
**Loáº¡i dá»± Ã¡n:** Mobile client + backend serverless  
**Máº«u kiáº¿n trÃºc:** Flutter MVC thá»±c dá»¥ng + Cloudflare Worker REST API

## TÃ³m táº¯t Ä‘iá»u hÃ nh

`sinhvien-app` lÃ  á»©ng dá»¥ng há»— trá»£ sinh viÃªn theo dÃµi lá»‹ch há»c, lá»‹ch thi, báº£ng Ä‘iá»ƒm, chÆ°Æ¡ng trÃ¬nh Ä‘Ã o táº¡o vÃ  ghi chÃº cÃ¡ nhÃ¢n trong má»™t giao diá»‡n thá»‘ng nháº¥t. Repo hiá»‡n gá»“m hai pháº§n tÃ­ch há»£p cháº·t cháº½:

- á»¨ng dá»¥ng Flutter á»Ÿ thÆ° má»¥c gá»‘c, cháº¡y chÃ­nh trÃªn Android vÃ  cÃ³ cáº¥u hÃ¬nh web.
- Cloudflare Worker trong `cloudflare-worker/`, dÃ¹ng Ä‘á»ƒ Ä‘á»“ng bá»™ ghi chÃº, task, tá»‡p Ä‘Ã­nh kÃ¨m vÃ  snapshot dá»¯ liá»‡u qua D1, KV, R2.

Äiá»ƒm máº¡nh kiáº¿n trÃºc hiá»‡n táº¡i lÃ  tráº£i nghiá»‡m local-first: dá»¯ liá»‡u trÆ°á»ng Ä‘Æ°á»£c táº£i tá»« cá»•ng sinh viÃªn, lÆ°u cache cá»¥c bá»™ báº±ng `SharedPreferences`, sau Ä‘Ã³ cÃ¡c pháº§n dá»¯ liá»‡u cÃ¡ nhÃ¢n Ä‘Æ°á»£c Ä‘á»“ng bá»™ lÃªn cloud khi ngÆ°á»i dÃ¹ng Ä‘Äƒng nháº­p Firebase. Äiá»u nÃ y cho phÃ©p app váº«n dÃ¹ng Ä‘Æ°á»£c khi offline, trong khi váº«n cÃ³ kháº£ nÄƒng khÃ´i phá»¥c ghi chÃº vÃ  tá»‡p giá»¯a cÃ¡c thiáº¿t bá»‹.

## PhÃ¢n loáº¡i dá»± Ã¡n

- **Repository type:** Monorepo
- **CÃ¡c part chÃ­nh:** `mobile-app`, `worker-api`
- **NgÃ´n ngá»¯ chÃ­nh:** Dart, TypeScript
- **NgÃ´n ngá»¯ phá»¥:** Kotlin, SQL, JSON, TOML
- **Phá»¥ thuá»™c háº¡ táº§ng:** Firebase Auth, Cloudflare Worker, D1, KV, R2, Open-Meteo, API cá»•ng sinh viÃªn TLU

## Cáº¥u trÃºc nhiá»u pháº§n

### 1. mobile-app

- **Loáº¡i:** `mobile`
- **Vá»‹ trÃ­:** `.`
- **Má»¥c Ä‘Ã­ch:** á»¨ng dá»¥ng Flutter cho sinh viÃªn xem lá»‹ch, Ä‘iá»ƒm, Ä‘á»“ng bá»™ dá»¯ liá»‡u trÆ°á»ng, quáº£n lÃ½ ghi chÃº vÃ  tá»‡p Ä‘Ã­nh kÃ¨m
- **Stack:** Flutter 3 / Dart 3.11, Firebase Core/Auth, Google Sign-In, local notifications, SharedPreferences

### 2. worker-api

- **Loáº¡i:** `backend`
- **Vá»‹ trÃ­:** `cloudflare-worker/`
- **Má»¥c Ä‘Ã­ch:** API serverless xÃ¡c thá»±c Firebase token vÃ  lÆ°u dá»¯ liá»‡u ngÆ°á»i dÃ¹ng vÃ o Cloudflare
- **Stack:** Cloudflare Worker, TypeScript, `jose`, D1, KV, R2, Wrangler

## CÃ¡ch cÃ¡c pháº§n tÃ­ch há»£p vá»›i nhau

1. NgÆ°á»i dÃ¹ng dÃ¹ng tab `Äá»“ng bá»™` Ä‘á»ƒ nháº­p tÃ i khoáº£n cá»•ng sinh viÃªn.
2. `SchoolApiService` gá»i trá»±c tiáº¿p API trÆ°á»ng, chuáº©n hÃ³a dá»¯ liá»‡u thÃ nh `SchoolSyncSnapshot`.
3. `HomeController` ghi payload vÃ o cache cá»¥c bá»™, cáº­p nháº­t notification vÃ  Android widget.
4. Khi Ä‘Ã£ Ä‘Äƒng nháº­p Firebase, `CloudSyncService` láº¥y Firebase ID token vÃ  gá»i Worker.
5. Worker xÃ¡c thá»±c token báº±ng JWKS cá»§a Google, sau Ä‘Ã³:
   - ghi note vÃ  personal task vÃ o D1,
   - ghi snapshot dashboard vÃ o KV vÃ  Ä‘á»“ng thá»i log sang D1,
   - upload/download tá»‡p Ä‘Ã­nh kÃ¨m qua R2.

## TÃ³m táº¯t stack cÃ´ng nghá»‡

### mobile-app

| NhÃ³m | CÃ´ng nghá»‡ | Ghi chÃº |
| --- | --- | --- |
| UI | Flutter Material 3 | `lib/app.dart`, `lib/theme/app_theme.dart` |
| State/UI flow | Riverpod Notifier + controller | HomeController, AccountAuthController |
| Auth | Firebase Auth, Google Sign-In | ÄÄƒng nháº­p cloud lÃ  tÃ¹y chá»n |
| Local storage | SharedPreferences | LÆ°u `LocalCachePayload` |
| Notifications | `flutter_local_notifications`, `timezone` | Chá»‰ cháº¡y Android |
| External APIs | TLU education API, Open-Meteo | Äá»“ng bá»™ dá»¯ liá»‡u trÆ°á»ng vÃ  thá»i tiáº¿t |

### worker-api

| NhÃ³m | CÃ´ng nghá»‡ | Ghi chÃº |
| --- | --- | --- |
| Runtime | Cloudflare Worker | `src/index.ts` |
| Auth | `jose` + Firebase ID token verify | XÃ¡c thá»±c qua Google JWKS |
| Database | Cloudflare D1 | `users`, `notes`, `attachments`, `personal_tasks`, `sync_snapshots` |
| Cache | Cloudflare KV | LÆ°u snapshot dashboard theo TTL |
| File storage | Cloudflare R2 | LÆ°u PDF, DOC, áº£nh Ä‘Ã­nh kÃ¨m |
| Infra config | Wrangler | `wrangler.toml` |

## Chá»©c nÄƒng ná»•i báº­t

- Lá»‹ch há»c, lá»‹ch thi vÃ  viá»‡c cÃ¡ nhÃ¢n hiá»ƒn thá»‹ trÃªn cÃ¹ng má»™t lá»‹ch ngÃ y.
- Ghi chÃº vÃ  Ä‘Ã­nh kÃ¨m tá»‡p trá»±c tiáº¿p trÃªn tá»«ng sá»± kiá»‡n.
- Xem báº£ng Ä‘iá»ƒm vÃ  chÆ°Æ¡ng trÃ¬nh Ä‘Ã o táº¡o.
- Láº­p káº¿ hoáº¡ch GPA má»¥c tiÃªu vÃ  gá»£i Ã½ há»c láº¡i/chá»n mÃ´n cháº¯c A.
- Cache dá»¯ liá»‡u Ä‘á»ƒ dÃ¹ng offline.
- Äá»“ng bá»™ cloud cho note, task, attachments vÃ  snapshot.
- Notification cá»¥c bá»™ vÃ  Android home widget cho lá»‹ch hÃ´m nay.

## Äiá»ƒm nháº¥n kiáº¿n trÃºc

- `HomeController` lÃ  Ä‘iá»ƒm Ä‘iá»u phá»‘i trung tÃ¢m giá»¯a UI, local cache, sync trÆ°á»ng, sync cloud, weather, notification vÃ  widget.
- App Æ°u tiÃªn local-first: cloud failure khÃ´ng cháº·n tráº£i nghiá»‡m cÆ¡ báº£n.
- Worker tÃ¡ch biá»‡t háº³n lÆ°u trá»¯ cloud khá»i client, trÃ¡nh Ä‘á»ƒ app nÃ³i chuyá»‡n trá»±c tiáº¿p vá»›i D1/KV/R2.
- Repo Ä‘ang cÃ³ dáº¥u váº¿t tÃ i liá»‡u cÅ© vá» má»™t scraper/backend khÃ¡c; mÃ£ hiá»‡n táº¡i pháº£n Ã¡nh mÃ´ hÃ¬nh gá»i trá»±c tiáº¿p API trÆ°á»ng tá»« app, khÃ´ng pháº£i tá»« Worker.

## Tá»•ng quan phÃ¡t triá»ƒn

### Äiá»u kiá»‡n cáº§n

- Flutter SDK tÆ°Æ¡ng thÃ­ch Dart `^3.11.0`
- Android Studio hoáº·c VS Code
- Node.js Ä‘á»ƒ cháº¡y `cloudflare-worker`
- TÃ i nguyÃªn Cloudflare Ä‘Ã£ táº¡o sáºµn náº¿u muá»‘n test cloud tháº­t

### Khá»Ÿi Ä‘á»™ng nhanh

- Mobile app: `flutter pub get` rá»“i `flutter run`
- Worker: `cd cloudflare-worker`, `npm install`, `npm run dev`

### Lá»‡nh chÃ­nh

#### mobile-app

- **Install:** `flutter pub get`
- **Dev:** `flutter run`
- **Build web:** `flutter run -d chrome`
- **Test:** `flutter test`

#### worker-api

- **Install:** `npm install`
- **Dev:** `npm run dev`
- **Deploy:** `npm run deploy`

## TÃ³m táº¯t cáº¥u trÃºc repo

Repo Ä‘áº·t app Flutter á»Ÿ thÆ° má»¥c gá»‘c Ä‘á»ƒ thuáº­n tiá»‡n cho Android/Web build, cÃ²n backend cloud tÃ¡ch riÃªng trong `cloudflare-worker/`. `docs/` hiá»‡n chá»©a cáº£ tÃ i liá»‡u má»›i Ä‘Æ°á»£c quÃ©t vÃ  má»™t sá»‘ tÃ i liá»‡u lá»‹ch sá»­/Ä‘á» xuáº¥t cÅ©. CÃ¡c thÆ° má»¥c sinh build nhÆ° `build/`, `.dart_tool/`, `cloudflare-worker/node_modules/` khÃ´ng pháº£i pháº§n lÃµi cá»§a kiáº¿n trÃºc.

## Báº£n Ä‘á»“ tÃ i liá»‡u

- [index.md](./index.md) - Äiá»ƒm vÃ o chÃ­nh cho AI vÃ  ngÆ°á»i má»›i
- [architecture-mobile-app.md](./architecture-mobile-app.md) - Kiáº¿n trÃºc app Flutter
- [architecture-worker-api.md](./architecture-worker-api.md) - Kiáº¿n trÃºc Worker
- [integration-architecture.md](./integration-architecture.md) - Luá»“ng giao tiáº¿p giá»¯a cÃ¡c part
- [source-tree-analysis.md](./source-tree-analysis.md) - CÃ¢y thÆ° má»¥c cÃ³ chÃº giáº£i
- [development-guide-mobile-app.md](./development-guide-mobile-app.md) - HÆ°á»›ng dáº«n phÃ¡t triá»ƒn app
- [development-guide-worker-api.md](./development-guide-worker-api.md) - HÆ°á»›ng dáº«n phÃ¡t triá»ƒn Worker

---

_Generated using BMAD Method `document-project` workflow_

