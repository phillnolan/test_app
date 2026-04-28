# Feature-First Target Tree

Tai lieu nay mo ta cay thu muc muc tieu cho `sinhvien-app` sau khi chuan hoa
theo `architecture-feature-first` + `riverpod`.

## Current migration status

- `home` da split sang `lib/features/home/ui/`, `lib/features/home/domain/`
  va `lib/features/home/data/`; `HomeController` duoc cung cap qua Riverpod.
- `grades` da split sang `lib/features/grades/ui/` va
  `lib/features/grades/domain/`.
- `auth` da split sang `lib/features/auth/data/` va `lib/features/auth/ui/`.
- `sync` da split sang `lib/features/sync/data/` va `lib/features/sync/domain/`.
- `attachments` da split sang `lib/features/attachments/data/` va
  `lib/features/attachments/ui/`.
- `weather` da split sang `lib/features/weather/data/` va
  `lib/features/weather/domain/`.
- `notifications` da co `lib/features/notifications/data/` va scaffold UI.
- `widget` da co `lib/features/widget/data/` va scaffold UI.
- Shared code con lai nam o `lib/models/`, `lib/services/`, `lib/theme/` va
  `lib/utils/`.

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
    |   |-- domain/
    |   `-- ui/
    `-- widget/
        |-- data/
        `-- ui/
```

## Mapping from historical code to target path

| Historical path | Target path |
| --- | --- |
| `lib/controllers/home_controller.dart` | `lib/features/home/ui/` |
| `lib/views/home/home_shell.dart` | `lib/features/home/ui/` |
| `lib/views/home/pages/*` | `lib/features/home/ui/pages/` |
| `lib/views/home/widgets/*` | `lib/features/home/ui/widgets/` |
| `lib/controllers/grades_controller.dart` | `lib/features/grades/ui/` |
| `lib/views/grades/*` | `lib/features/grades/ui/` |
| `lib/features/auth/data/auth_service.dart` | `lib/features/auth/data/` |
| `lib/features/auth/ui/account_auth_controller.dart` | `lib/features/auth/ui/` |
| `lib/services/school_api_service.dart` | `lib/features/sync/data/` |
| `lib/services/school_sync_coordinator.dart` | `lib/features/sync/domain/` |
| `lib/services/local_cache_service.dart` | `lib/features/sync/data/` |
| `lib/services/dashboard_persistence_service.dart` | `lib/features/sync/data/` |
| `lib/services/cloud_sync_service.dart` | `lib/features/sync/data/` |
| `lib/services/event_mutation_service.dart` | `lib/features/home/data/` |
| `lib/features/attachments/data/*` | `lib/features/attachments/data/` |
| `lib/features/attachments/ui/*` | `lib/features/attachments/ui/` |
| `lib/features/weather/data/*` | `lib/features/weather/data/` |
| `lib/features/weather/domain/*` | `lib/features/weather/domain/` |
| `lib/features/notifications/data/*` | `lib/features/notifications/data/` |
| `lib/features/widget/data/*` | `lib/features/widget/data/` |
| `lib/theme/app_theme.dart` | `lib/core/theme/` |
| `lib/utils/*` | `lib/core/utils/` |
| `lib/models/*` | `lib/core/models/` or feature-local `data/` |

## Standardization rules

- Keep shared concerns in `lib/core/` when we decide to migrate them out of
  the old root folders.
- Keep feature-specific UI, data and optional domain logic together.
- Use Riverpod providers/notifiers in the target UI layer after migration.
- Preserve current runtime behavior until each slice is fully stabilized.

## Migration order

1. `home`
2. `grades`
3. `auth`
4. `sync`
5. `attachments`
6. `weather`
7. `notifications`
8. `widget`

