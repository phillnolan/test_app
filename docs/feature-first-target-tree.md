# Feature-First Target Tree

This document describes the target folder structure for standardizing
`sinhvien-app` toward the `architecture-feature-first` + `riverpod` workflow.

## Current migration status

- `home` has already been split into `lib/features/home/ui/`,
  `lib/features/home/domain/`, and `lib/features/home/data/`.
- `grades` has already been split into `lib/features/grades/ui/`,
  `lib/features/grades/domain/`, and `lib/features/grades/data/` scaffold.
- `auth` has already been split into `lib/features/auth/data/` and
  `lib/features/auth/ui/`.
- `sync` has already been split into `lib/features/sync/data/`,
  `lib/features/sync/domain/`, and `lib/features/sync/ui/` scaffold.
- The remaining legacy app code still lives under `lib/controllers/`,
  `lib/views/`, `lib/services/`, and `lib/utils/` until the next slices land.

## Target tree

```text
lib/
|-- app.dart
|-- main.dart
|-- core/
|   |-- di/
|   |-- models/
|   |-- network/
|   |-- theme/
|   |-- utils/
|   `-- widgets/
`-- features/
    |-- attachments/
    |   |-- data/
    |   |-- domain/
    |   `-- ui/
    |-- auth/
    |   |-- data/
    |   `-- ui/
    |-- grades/
    |   |-- data/
    |   |-- domain/
    |   `-- ui/
    |       `-- widgets/
    |-- home/
    |   |-- data/
    |   |-- domain/
    |   `-- ui/
    |       |-- pages/
    |       `-- widgets/
    |-- notifications/
    |   |-- data/
    |   `-- ui/
    |-- sync/
    |   |-- data/
    |   |-- domain/
    |   `-- ui/
    |-- weather/
    |   |-- data/
    |   `-- ui/
    `-- widget/
        |-- data/
        `-- ui/
```

## Mapping from current code

| Current path | Target path |
| --- | --- |
| `lib/controllers/home_controller.dart` | `lib/features/home/ui/` |
| `lib/features/auth/ui/account_auth_controller.dart` | `lib/features/auth/ui/` |
| `lib/controllers/grades_controller.dart` | `lib/features/grades/ui/` |
| `lib/views/home/home_shell.dart` | `lib/features/home/ui/` |
| `lib/views/home/pages/*` | `lib/features/home/ui/pages/` |
| `lib/views/home/widgets/*` | `lib/features/home/ui/widgets/` |
| `lib/views/grades/*` | `lib/features/grades/ui/` |
| `lib/features/auth/data/auth_service.dart` | `lib/features/auth/data/` |
| `lib/services/school_api_service.dart` | `lib/features/sync/data/` |
| `lib/services/school_sync_coordinator.dart` | `lib/features/sync/domain/` |
| `lib/services/local_cache_service.dart` | `lib/features/sync/data/` |
| `lib/services/dashboard_persistence_service.dart` | `lib/features/sync/data/` |
| `lib/services/cloud_sync_service.dart` | `lib/features/sync/data/` |
| `lib/services/event_mutation_service.dart` | `lib/features/home/data/` |
| `lib/services/attachment_storage_service.dart` | `lib/features/attachments/data/` |
| `lib/services/attachment_import_service.dart` | `lib/features/attachments/data/` |
| `lib/services/attachment_opener*.dart` | `lib/features/attachments/data/` |
| `lib/services/weather_service.dart` | `lib/features/weather/data/` |
| `lib/services/notification_service.dart` | `lib/features/notifications/data/` |
| `lib/services/widget_sync_service.dart` | `lib/features/widget/data/` |
| `lib/theme/app_theme.dart` | `lib/core/theme/` |
| `lib/utils/*` | `lib/core/utils/` |
| `lib/models/*` | `lib/core/models/` or feature-local `data/` |

## Standardization rules

- Keep shared concerns in `lib/core/`.
- Keep feature-specific UI, data, and optional domain logic together.
- Move one feature at a time; do not migrate all controllers at once.
- Use Riverpod notifiers/providers in the target UI layer after migration.
- Preserve current runtime behavior until each slice is fully migrated.

## Migration order

1. `home`
2. `grades`
3. `auth`
4. `sync`
5. `attachments`
6. `weather`
7. `notifications`
8. `widget`
