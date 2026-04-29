# Project Standardization Mindmap

Tai lieu nay la ban do chuan hoa cua `sinhvien-app` sau khi repo da chuyen
sang feature-first + Riverpod o phan mobile.

No gom 2 lop thong tin:

- hien trang hien tai cua repo;
- huong chuan hoa tiep theo theo skill `dev`:
  `architecture-feature-first` -> `riverpod` -> `dart-3-updates` ->
  `effective-dart`.

```mermaid
mindmap
  root((sinhvien-app))
    Hien trang repo
      Flutter app o repo root
      Feature-first da duoc ap dung
        lib/features/home/ui/home_controller.dart
        lib/features/home/ui/home_shell.dart
        homeControllerProvider
        lib/features/home/data/event_mutation_service.dart
        lib/features/home/domain/home_flow_models.dart
        lib/features/grades/ui/grades_controller.dart
        lib/features/grades/ui/grades_page.dart
        lib/features/grades/domain/curriculum_presenter.dart
        lib/features/grades/domain/grade_metrics.dart
        lib/features/auth/data/auth_service.dart
        lib/features/auth/ui/account_auth_controller.dart
        accountAuthControllerProvider
        lib/features/sync/data/cloud_sync_service.dart
        lib/features/sync/data/dashboard_persistence_service.dart
        lib/features/sync/data/local_cache_service.dart
        lib/features/sync/data/school_api_service.dart
        lib/features/sync/data/student_sync_credentials_service.dart
        lib/features/sync/domain/school_sync_coordinator.dart
        lib/features/attachments/data/attachment_storage_service.dart
        lib/features/attachments/data/attachment_import_service.dart
        lib/features/attachments/data/attachment_opener.dart
        lib/features/attachments/data/image_edit_service.dart
        lib/features/attachments/ui/image_attachment_editor.dart
        lib/features/weather/data/weather_service.dart
        lib/features/weather/data/weather_forecast.dart
        lib/features/weather/domain/weather_presentation.dart
        lib/features/notifications/data/notification_service.dart
        lib/features/widget/data/widget_sync_service.dart
      Shared code chua vao core
        lib/models/*
        lib/services/*
        lib/theme/app_theme.dart
        lib/utils/*
      Backend rieng
        cloudflare-worker/src/index.ts
        D1
        KV
        R2
    Feature map
      Home
        lich, quiz, sync, account, tuition
      Grades
        GPA planner, curriculum, grade summary
      Auth
        Firebase Auth, Google Sign-In
      Sync
        school API, local cache, cloud sync
      Attachments
        import, storage, open, image edit
      Weather
        forecast, presentation
      Notifications
        local notifications
      Widget
        Android home widget bridge
    Standardization target
      lib/core
        shared models
        shared networking
        shared theme/widgets
        shared utilities
      Riverpod
        ProviderScope o entrypoint
        Notifier cho state ownership
        ref.watch trong build
        ref.read trong callback
        ref.onDispose cho cleanup
      Dart 3
        sealed classes cho state/result
        switch expressions
        records cho multi-return nho
        patterns va destructuring
      Effective Dart
        ten file va ten class nhat quan
        file nho, mot trach nhiem
        const/final uu tien
        doc comment cho API cong khai
    Migration focus
      1. Giu startup on dinh
      2. Chuan hoa shared code vao core
      3. Tach cac service con no ra khoi Home
      4. Nhanh tay cap nhat test va docs sau moi thay doi
      5. Giup state/result ap dung sealed classes where it adds clarity
```

## Cach doc

- `Hien trang repo` mo ta dung gia tri that hien co trong source tree.
- `Feature map` giup gan file vao tung domain de refactor khong bi lan.
- `Standardization target` la hinh mau cho cac buoc chuan hoa tiep theo.
- `Migration focus` la thu tu uu tien an toan nhat de khong lam do startup.

## Uu tien chuan hoa

1. Giup startup deterministic: local cache khong bi cloud payload ghi de.
2. Chuan hoa shared code vao `lib/core/` thay vi de lai o `models/`,
   `services/`, `theme/`, `utils/` ma khong co quy uoc ro.
3. Giu `HomeController` va `AccountAuthController` theo Riverpod ownership.
4. Chuyen state/result sang Dart 3 khi no lam code ro hon, khong them phuc tap.
5. Dong bo tests va docs ngay khi doi shape model hoac flow sync.

## Tai lieu lien quan

- [Project Overview](./project-overview.md)

---

_Mindmap nay da duoc cap nhat de phan anh trang thai feature-first + Riverpod
hien tai cua repo._
