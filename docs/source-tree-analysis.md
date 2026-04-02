# sinhvien-app - Phân tích source tree

**Ngày quét:** 2026-04-02T14:13:05+07:00

## Tổng quan

Repo là monorepo nhỏ với app Flutter ở thư mục gốc và một backend Cloudflare Worker ở `cloudflare-worker/`. Cấu trúc hiện nghiêng về dễ tìm entry point và mô đun nghiệp vụ hơn là chia quá nhiều lớp.

## Cấu trúc tổng thể

```text
sinhvien-app/
├── README.md                           # Tài liệu giới thiệu dự án
├── pubspec.yaml                        # Manifest Flutter/Dart
├── firebase.json                       # Cấu hình FlutterFire/Firebase
├── lib/                                # Mã nguồn app Flutter
│   ├── main.dart                       # Bootstrap Flutter + Firebase + notification
│   ├── app.dart                        # MaterialApp, locale, theme, home shell
│   ├── controllers/                    # Điều phối state và flow UI
│   ├── models/                         # Model dữ liệu dùng chung
│   ├── services/                       # Tầng hạ tầng và tích hợp ngoài
│   ├── theme/                          # Theme ứng dụng
│   ├── utils/                          # Hàm thuần hỗ trợ lịch
│   └── views/                          # Màn hình và widget UI
├── android/                            # Android host app + home widget
├── web/                                # Web shell của Flutter
├── test/                               # Widget test cơ bản
├── cloudflare-worker/                  # Backend serverless
│   ├── package.json                    # Scripts dev/deploy Worker
│   ├── wrangler.toml                   # Bindings D1/KV/R2 và vars
│   ├── schema.sql                      # Schema D1
│   └── src/index.ts                    # REST API chính
├── docs/                               # Tài liệu dự án và tài liệu cũ
└── _bmad-output/                       # Artifact của BMAD
```

## Cấu trúc nhiều phần

- **mobile-app** (`.`): app Flutter, bao trùm `lib/`, `android/`, `web/`, `test/`
- **worker-api** (`cloudflare-worker/`): Worker + persistence bindings

## Thư mục quan trọng

### `lib/`

**Mục đích:** mã nguồn nghiệp vụ và UI của ứng dụng Flutter  
**Chứa:** controllers, models, services, views  
**Entry points:** `lib/main.dart`, `lib/app.dart`

### `lib/controllers/`

**Mục đích:** giữ state UI và điều phối flow  
**Chứa:** `home_controller.dart`, `account_auth_controller.dart`  
**Ghi chú tích hợp:** kết nối trực tiếp tới `services/*` và cập nhật UI qua `ChangeNotifier`

### `lib/services/`

**Mục đích:** tích hợp hệ ngoài, local storage, notification và cloud sync  
**Chứa:** `school_api_service.dart`, `cloud_sync_service.dart`, `local_cache_service.dart`, `notification_service.dart`, `widget_sync_service.dart`  
**Ghi chú tích hợp:** là giao điểm giữa app và API trường/Firebase/Cloudflare/Open-Meteo

### `lib/views/home/`

**Mục đích:** shell và tab lịch/đồng bộ/tài khoản  
**Chứa:** `home_shell.dart`, `pages/`, `widgets/`, `image_attachment_editor.dart`  
**Entry points:** `home_shell.dart`

### `lib/views/grades/`

**Mục đích:** tab bảng điểm và lập kế hoạch GPA  
**Chứa:** `grades_page.dart`, `widgets/curriculum_subjects_section.dart`, `widgets/goal_planner_section.dart`

### `android/app/src/main/kotlin/com/example/sinhvien_app/`

**Mục đích:** cầu nối Android native cho widget màn hình chính  
**Chứa:** `MainActivity.kt`, `TodayScheduleWidgetProvider.kt`  
**Entry points:** `MainActivity.kt`

### `cloudflare-worker/src/`

**Mục đích:** REST API serverless  
**Chứa:** `index.ts`  
**Entry points:** `src/index.ts`

### `docs/`

**Mục đích:** tài liệu sinh ra cho AI và tài liệu lịch sử của team  
**Chứa:** bộ docs mới, cùng các file cũ như `cloudflare_architecture.md`, `firebase_cloudflare_setup.md`, `project-structure.md`

## Cây theo part

### mobile-app

```text
./
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── controllers/
│   ├── models/
│   ├── services/
│   ├── theme/
│   ├── utils/
│   └── views/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       ├── kotlin/com/example/sinhvien_app/
│       └── res/
├── web/
│   ├── index.html
│   └── manifest.json
└── test/
    └── widget_test.dart
```

### worker-api

```text
cloudflare-worker/
├── package.json
├── package-lock.json
├── tsconfig.json
├── wrangler.toml
├── schema.sql
├── README.md
└── src/
    └── index.ts
```

## Điểm tích hợp giữa các phần

- `mobile-app` -> `worker-api`: qua `lib/services/cloud_sync_service.dart`
- `mobile-app` -> TLU education API: qua `lib/services/school_api_service.dart`
- `mobile-app` -> Android host widget: qua `lib/services/widget_sync_service.dart`

## File cấu hình cần chú ý

- `pubspec.yaml`
- `firebase.json`
- `lib/firebase_options.dart`
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `cloudflare-worker/wrangler.toml`

## Ghi chú phát triển

- Thư mục sinh build như `build/`, `.dart_tool/`, `android/.gradle/`, `cloudflare-worker/node_modules/` không nên dùng làm nguồn tài liệu kiến trúc.
- `cloudflare-worker/README.md` và một số file trong `docs/` phản ánh thiết kế cũ, không còn khớp hoàn toàn với `src/index.ts`.
- Nếu backend tiếp tục mở rộng, nên tách Worker thành router/auth/storage modules thay vì để toàn bộ logic trong một file.

---

_Generated using BMAD Method `document-project` workflow_
