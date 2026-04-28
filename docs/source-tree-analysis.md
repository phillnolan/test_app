# sinhvien-app - PhÃ¢n tÃ­ch source tree

**NgÃ y quÃ©t:** 2026-04-02T14:13:05+07:00

## Tá»•ng quan

Repo lÃ  monorepo nhá» vá»›i app Flutter á»Ÿ thÆ° má»¥c gá»‘c vÃ  má»™t backend Cloudflare Worker á»Ÿ `cloudflare-worker/`. Cáº¥u trÃºc hiá»‡n nghiÃªng vá» dá»… tÃ¬m entry point vÃ  mÃ´ Ä‘un nghiá»‡p vá»¥ hÆ¡n lÃ  chia quÃ¡ nhiá»u lá»›p.

## Cáº¥u trÃºc tá»•ng thá»ƒ

```text
sinhvien-app/
â”œâ”€â”€ README.md                           # TÃ i liá»‡u giá»›i thiá»‡u dá»± Ã¡n
â”œâ”€â”€ pubspec.yaml                        # Manifest Flutter/Dart
â”œâ”€â”€ firebase.json                       # Cáº¥u hÃ¬nh FlutterFire/Firebase
â”œâ”€â”€ lib/                                # MÃ£ nguá»“n app Flutter
â”‚   â”œâ”€â”€ main.dart                       # Bootstrap Flutter + Firebase + notification
â”‚   â”œâ”€â”€ app.dart                        # MaterialApp, locale, theme, home shell
â”‚   â”œâ”€â”€ controllers/                    # Äiá»u phá»‘i state vÃ  flow UI
â”‚   â”œâ”€â”€ models/                         # Model dá»¯ liá»‡u dÃ¹ng chung
â”‚   â”œâ”€â”€ services/                       # Táº§ng háº¡ táº§ng vÃ  tÃ­ch há»£p ngoÃ i
â”‚   â”œâ”€â”€ theme/                          # Theme á»©ng dá»¥ng
â”‚   â”œâ”€â”€ utils/                          # HÃ m thuáº§n há»— trá»£ lá»‹ch
â”‚   â””â”€â”€ views/                          # MÃ n hÃ¬nh vÃ  widget UI
â”œâ”€â”€ android/                            # Android host app + home widget
â”œâ”€â”€ web/                                # Web shell cá»§a Flutter
â”œâ”€â”€ test/                               # Widget test cÆ¡ báº£n
â”œâ”€â”€ cloudflare-worker/                  # Backend serverless
â”‚   â”œâ”€â”€ package.json                    # Scripts dev/deploy Worker
â”‚   â”œâ”€â”€ wrangler.toml                   # Bindings D1/KV/R2 vÃ  vars
â”‚   â”œâ”€â”€ schema.sql                      # Schema D1
â”‚   â””â”€â”€ src/index.ts                    # REST API chÃ­nh
â”œâ”€â”€ docs/                               # TÃ i liá»‡u dá»± Ã¡n vÃ  tÃ i liá»‡u cÅ©
â””â”€â”€ _bmad-output/                       # Artifact cá»§a BMAD
```

## Cáº¥u trÃºc nhiá»u pháº§n

- **mobile-app** (`.`): app Flutter, bao trÃ¹m `lib/`, `android/`, `web/`, `test/`
- **worker-api** (`cloudflare-worker/`): Worker + persistence bindings

## ThÆ° má»¥c quan trá»ng

### `lib/`

**Má»¥c Ä‘Ã­ch:** mÃ£ nguá»“n nghiá»‡p vá»¥ vÃ  UI cá»§a á»©ng dá»¥ng Flutter  
**Chá»©a:** controllers, models, services, views  
**Entry points:** `lib/main.dart`, `lib/app.dart`

### `lib/controllers/`

**Má»¥c Ä‘Ã­ch:** giá»¯ state UI vÃ  Ä‘iá»u phá»‘i flow  
**Chá»©a:** `home_controller.dart`, `features/auth/ui/account_auth_controller.dart`  
**Ghi chú tích hợp:** kết nối trực tiếp tới `services/*` và `features/auth/data/auth_service.dart`, còn `HomeController` được bọc bởi `NotifierProvider` để cập nhật UI qua `HomeState`

### `lib/services/`

**Má»¥c Ä‘Ã­ch:** tÃ­ch há»£p há»‡ ngoÃ i, local storage, notification vÃ  cloud sync  
**Chá»©a:** `school_api_service.dart`, `cloud_sync_service.dart`, `local_cache_service.dart`, `features/notifications/data/notification_service.dart`, `features/widget/data/widget_sync_service.dart`  
**Ghi chÃº tÃ­ch há»£p:** lÃ  giao Ä‘iá»ƒm giá»¯a app vÃ  API trÆ°á»ng/Firebase/Cloudflare

### `lib/views/home/`

**Má»¥c Ä‘Ã­ch:** shell vÃ  tab lá»‹ch/Ä‘á»“ng bá»™/tÃ i khoáº£n  
**Chá»©a:** `home_shell.dart`, `pages/`, `widgets/`  
**Entry points:** `home_shell.dart`

### `lib/features/grades/`

**Má»¥c Ä‘Ã­ch:** tab báº£ng Ä‘iá»ƒm vÃ  láº­p káº¿ hoáº¡ch GPA  
**Chá»©a:** `grades_page.dart`, `widgets/curriculum_subjects_section.dart`, `widgets/goal_planner_section.dart`

### `lib/features/attachments/`

**MÃ¡Â»Â¥c Ã„â€˜ÃƒÂ­ch:** nhÃ¡ÂºÂ­p, lÃ†Â°u, mÃ¡Â»Å¸ vÃƒÂ  chÃ¡Â»â€°nh sÃ¡Â»Â­a tÃ¡Â»â€¡p Ã„â€˜ÃƒÂ­nh kÃƒÂ¨m  
**ChÃ¡Â»Â©a:** `data/attachment_storage_service.dart`, `data/attachment_import_service.dart`, `data/attachment_opener*.dart`, `data/file_bytes_reader*.dart`, `data/image_edit_service.dart`, `ui/image_attachment_editor.dart`, `ui/attachment_editing_helpers.dart`  
**Entry points:** `ui/image_attachment_editor.dart`

### `lib/features/weather/`

**Má»¥c Ä‘Ã­ch:** láº¥y, chuyá»ƒn Ä‘á»•i vÃ  hiá»ƒn thá»‹ dá»± bÃ¡o thá»i tiáº¿t  
**Chá»©a:** `data/weather_service.dart`, `data/weather_forecast.dart`, `domain/weather_presentation.dart`, `ui/`  
**Entry points:** `data/weather_service.dart`

### `android/app/src/main/kotlin/com/example/sinhvien_app/`

**Má»¥c Ä‘Ã­ch:** cáº§u ná»‘i Android native cho widget mÃ n hÃ¬nh chÃ­nh  
**Chá»©a:** `MainActivity.kt`, `TodayScheduleWidgetProvider.kt`  
**Entry points:** `MainActivity.kt`

### `cloudflare-worker/src/`

**Má»¥c Ä‘Ã­ch:** REST API serverless  
**Chá»©a:** `index.ts`  
**Entry points:** `src/index.ts`

### `docs/`

**Má»¥c Ä‘Ã­ch:** tÃ i liá»‡u sinh ra cho AI vÃ  tÃ i liá»‡u lá»‹ch sá»­ cá»§a team  
**Chá»©a:** bá»™ docs má»›i, cÃ¹ng cÃ¡c file cÅ© nhÆ° `cloudflare_architecture.md`, `firebase_cloudflare_setup.md`, `project-structure.md`

## CÃ¢y theo part

### mobile-app

```text
./
â”œâ”€â”€ lib/
â”‚   â”œâ”€â”€ main.dart
â”‚   â”œâ”€â”€ app.dart
â”‚   â”œâ”€â”€ controllers/
â”‚   â”œâ”€â”€ models/
â”‚   â”œâ”€â”€ services/
â”‚   â”œâ”€â”€ theme/
â”‚   â”œâ”€â”€ utils/
â”‚   â””â”€â”€ views/
â”œâ”€â”€ android/
â”‚   â””â”€â”€ app/src/main/
â”‚       â”œâ”€â”€ AndroidManifest.xml
â”‚       â”œâ”€â”€ kotlin/com/example/sinhvien_app/
â”‚       â””â”€â”€ res/
â”œâ”€â”€ web/
â”‚   â”œâ”€â”€ index.html
â”‚   â””â”€â”€ manifest.json
â””â”€â”€ test/
    â””â”€â”€ widget_test.dart
```

### worker-api

```text
cloudflare-worker/
â”œâ”€â”€ package.json
â”œâ”€â”€ package-lock.json
â”œâ”€â”€ tsconfig.json
â”œâ”€â”€ wrangler.toml
â”œâ”€â”€ schema.sql
â”œâ”€â”€ README.md
â””â”€â”€ src/
    â””â”€â”€ index.ts
```

## Äiá»ƒm tÃ­ch há»£p giá»¯a cÃ¡c pháº§n

- `mobile-app` -> `worker-api`: qua `lib/features/sync/data/cloud_sync_service.dart`
- `mobile-app` -> TLU education API: qua `lib/features/sync/data/school_api_service.dart`
- `mobile-app` -> Android host widget: qua `lib/features/widget/data/widget_sync_service.dart`

## File cáº¥u hÃ¬nh cáº§n chÃº Ã½

- `pubspec.yaml`
- `firebase.json`
- `lib/firebase_options.dart`
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `cloudflare-worker/wrangler.toml`

## Ghi chÃº phÃ¡t triá»ƒn

- ThÆ° má»¥c sinh build nhÆ° `build/`, `.dart_tool/`, `android/.gradle/`, `cloudflare-worker/node_modules/` khÃ´ng nÃªn dÃ¹ng lÃ m nguá»“n tÃ i liá»‡u kiáº¿n trÃºc.
- `cloudflare-worker/README.md` vÃ  má»™t sá»‘ file trong `docs/` pháº£n Ã¡nh thiáº¿t káº¿ cÅ©, khÃ´ng cÃ²n khá»›p hoÃ n toÃ n vá»›i `src/index.ts`.
- Náº¿u backend tiáº¿p tá»¥c má»Ÿ rá»™ng, nÃªn tÃ¡ch Worker thÃ nh router/auth/storage modules thay vÃ¬ Ä‘á»ƒ toÃ n bá»™ logic trong má»™t file.

---

_Generated using BMAD Method `document-project` workflow_

