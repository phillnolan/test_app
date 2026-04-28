# sinhvien-app - Phan tich source tree

**Last updated:** 2026-04-28

## Tong quan

Repo gom 2 phan chinh:

- app Flutter o root;
- backend Cloudflare Worker trong `cloudflare-worker/`.

Code mobile da chuyen sang feature-first + Riverpod. Khong con `lib/controllers/`
hay `lib/views/` o cay nguon hien tai.

## Cay tong the

```text
sinhvien-app/
├── README.md
├── pubspec.yaml
├── firebase.json
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── firebase_options.dart
│   ├── models/
│   ├── services/
│   ├── theme/
│   ├── utils/
│   └── features/
│       ├── home/
│       │   ├── data/
│       │   ├── domain/
│       │   └── ui/
│       │       ├── pages/
│       │       └── widgets/
│       ├── grades/
│       │   ├── domain/
│       │   └── ui/
│       │       └── widgets/
│       ├── auth/
│       │   ├── data/
│       │   └── ui/
│       ├── sync/
│       │   ├── data/
│       │   └── domain/
│       ├── attachments/
│       │   ├── data/
│       │   └── ui/
│       ├── weather/
│       │   ├── data/
│       │   └── domain/
│       ├── notifications/
│       │   └── data/
│       └── widget/
│           └── data/
├── android/
├── web/
├── test/
├── cloudflare-worker/
│   ├── package.json
│   ├── package-lock.json
│   ├── tsconfig.json
│   ├── wrangler.toml
│   ├── schema.sql
│   └── src/
│       └── index.ts
└── docs/
```

## Phan tich theo khu vuc

### `lib/`

`lib/` la ma nguon mobile. Cac nhom chinh:

- `main.dart`: bootstrap Flutter, Firebase, notification, ProviderScope.
- `app.dart`: MaterialApp, theme, locale va home shell.
- `features/`: toan bo feature-specific UI, data va domain logic.
- `models/`: DTO va model dung chung giua cac feature.
- `services/`: service cross-feature va platform integration.
- `theme/`: theme app.
- `utils/`: helper/presenter tuan thu pure function.

### `lib/features/home/`

- `ui/home_controller.dart`: `Notifier<HomeState>` duoc cung cap qua
  `homeControllerProvider`.
- `ui/home_shell.dart`: shell UI, tab navigation, dialog/sheet orchestration.
- `ui/pages/`: schedule, sync, account, quiz, tuition.
- `ui/widgets/`: dialog, editor va widget dung chung cho home.
- `data/event_mutation_service.dart`: mutation cho note/task/event.
- `domain/`: calendar utils, flow models va calendar types.

### `lib/features/grades/`

- `ui/grades_controller.dart`: controller cho tab diem.
- `ui/grades_page.dart`: page chinh.
- `ui/widgets/`: GPA planner va curriculum sections.
- `domain/`: `grade_metrics.dart`, `curriculum_presenter.dart`.

### `lib/features/auth/`

- `data/auth_service.dart`: FirebaseAuth + GoogleSignIn wrapper.
- `ui/account_auth_controller.dart`: provider-backed auth controller.

### `lib/features/sync/`

- `data/`: `SchoolApiService`, `CloudSyncService`, `LocalCacheService`,
  `DashboardPersistenceService`, `StudentSyncCredentialsService`.
- `domain/school_sync_coordinator.dart`: dieu phoi sync truong.

### `lib/features/attachments/`

- `data/`: storage, import, opener, image edit va byte readers.
- `ui/`: image attachment editor va helper cho picker/camera flow.

### `lib/features/weather/`

- `data/weather_service.dart`: fetch Open-Meteo.
- `data/weather_forecast.dart`: forecast model.
- `domain/weather_presentation.dart`: presentation model cho UI.

### `lib/features/notifications/` va `lib/features/widget/`

- `notifications/data/notification_service.dart`: local notifications.
- `widget/data/widget_sync_service.dart`: Android home widget bridge.

### `lib/services/`

Shared services hien tai van nam o day va chua vao `lib/core/`:

- `device_effects_service.dart`
- `http_client_factory*.dart`
- cac adapter cross-feature va platform helper con lai cho den khi duoc
  chuan hoa vao `lib/core/` hoac feature tuong ung.

### `lib/models/`

Chua cac model dung chung hien co:

- `local_cache_payload.dart`
- `school_sync_snapshot.dart`
- `student_event.dart`
- `student_profile.dart`
- `grade_item.dart`
- `program_subject.dart`
- `event_attachment.dart`
- `home_action_result.dart`
- `current_tuition.dart`
- `student_sync_credentials.dart`

## Backend tree

`cloudflare-worker/` la backend serverless:

- `src/index.ts`: entry point REST API.
- `schema.sql`: schema D1.
- `wrangler.toml`: bindings D1/KV/R2 va env.
- `package.json`, `tsconfig.json`: runtime config.

## Integration points

- App -> TLU education API: qua `lib/features/sync/data/school_api_service.dart`
- App -> Cloudflare Worker: qua `lib/features/sync/data/cloud_sync_service.dart`
- App -> Android widget: qua `lib/features/widget/data/widget_sync_service.dart`

## Config files can chuyen

- `pubspec.yaml`
- `firebase.json`
- `lib/firebase_options.dart`
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `cloudflare-worker/wrangler.toml`

## Ghi chu source tree

- Thu muc sinh build nhu `build/`, `.dart_tool/`, `android/.gradle/` va
  `cloudflare-worker/node_modules/` khong phai source doc.
- `docs/` hien chi giu tai lieu dang dung; cac tai lieu MVC/scan cu da bi loai
  bo khoi repo.
- `HomeController` va `AccountAuthController` da duoc cung cap qua Riverpod,
  khong con la ChangeNotifier/Provider thu cong.
