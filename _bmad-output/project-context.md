---
project_name: 'sinhvien-app'
user_name: 'Nguyen'
date: '2026-04-10T00:00:00+07:00'
sections_completed: ['technology_stack', 'language_specific_rules', 'framework_specific_rules', 'testing_rules', 'code_quality_style_rules', 'development_workflow_rules', 'critical_dont_miss_rules']
existing_patterns_found: 12
status: 'complete'
rule_count: 63
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

- Mobile app: Flutter with Dart SDK `^3.11.0`.
- App architecture: practical MVC split across `lib/views`, `lib/controllers`, `lib/models`, and `lib/services`.
- State management: no Provider/Bloc/Redux; `HomeController extends ChangeNotifier` and views listen directly.
- Localization/runtime target: primary app locale is `vi_VN`; Firebase is configured for Android and Web, while other platforms may run local-only.
- Flutter dependencies: `firebase_core ^4.6.0`, `firebase_auth ^6.3.0`, `google_sign_in ^7.2.0`, `http ^1.5.0`, `shared_preferences ^2.5.3`, `path_provider ^2.1.5`, `flutter_local_notifications ^19.4.2`, `timezone ^0.10.1`.
- Attachment/image/PDF stack: `file_picker ^10.3.2`, `image_picker ^1.1.2`, `image ^4.5.4`, `pdf ^3.11.3`, `open_filex ^4.7.0`.
- Flutter linting: `flutter_lints ^6.0.0` via `analysis_options.yaml`.
- Worker API: Cloudflare Worker in `cloudflare-worker/`, entry `src/index.ts`.
- Worker TypeScript config: `target ES2022`, `module ES2022`, `moduleResolution Bundler`, `strict: true`, Workers types enabled.
- Worker dependencies: `typescript ^5.8.3`, `wrangler ^4.11.1`, `@cloudflare/workers-types ^4.20260327.0`, `jose ^6.0.10`.
- Cloudflare runtime: `compatibility_date = 2026-04-01`; bindings are D1 `DB`, KV `CACHE`, R2 `FILES`; vars include `APP_ENV` and `FIREBASE_PROJECT_ID`.

## Critical Implementation Rules

### Language-Specific Rules

- Dart models should stay explicit and defensive: keep `toJson`, `fromJson`, and `copyWith` on model classes, and normalize decoded `Map` keys with `key.toString()` when reading dynamic JSON.
- Preserve null-safe, immutable defaults in models: use `const []` defaults for lists and nullable fields for optional remote/local data.
- Do not introduce generated serialization unless the project intentionally adopts build tooling; current model serialization is handwritten.
- Keep async controller/service work non-blocking where the UI already uses `unawaited(...)`, but ensure state mutations still call `notifyListeners()` when visible controller state changes.
- Platform-specific Dart implementations should use conditional imports, following existing patterns like `file_bytes_reader_stub.dart` with IO implementation swaps.
- School API parsing must tolerate inconsistent payload shapes: normalize lists/maps defensively and throw `SchoolApiException` only for user-visible sync failures.
- TypeScript Worker code must remain strict-compatible: avoid `any` where a narrow request/body/env type is practical, and keep Cloudflare binding types on `Env`.
- Worker route handlers should return the existing `ApiResponse` JSON shape: `{ ok: true, data?: ... }` or `{ ok: false, error: string }`.
- Worker auth must continue using Firebase Bearer token verification via Google JWKS; never reintroduce legacy `x-user-id` trust.
- Worker storage queries must always scope user data by `firebase_uid` or user-prefixed object/cache keys.

### Framework-Specific Rules

- Treat `HomeController` as the app orchestration boundary. UI callbacks should call controller methods rather than duplicating persistence, sync, notification, or widget-update logic in views.
- The app is local-first: save local state before attempting cloud sync, and allow Firebase/cloud failures without breaking offline use.
- Firebase availability is optional. App startup and account features must tolerate missing or failed Firebase initialization, especially outside Android/Web.
- Do not add Provider, Bloc, Redux, Riverpod, or another state framework for small changes; follow the existing `ChangeNotifier` plus `ListenableBuilder` pattern unless a deliberate architecture change is requested.
- Preserve the four-tab `HomeShell` pattern with `IndexedStack` and controller-owned tab state.
- Keep school data sync separate from Firebase account auth. School credentials fetch data from the TLU education API; Firebase auth only gates personal cloud sync.
- `CloudSyncService` should use `CLOUDFLARE_WORKER_URL` via `String.fromEnvironment` and retain the current default worker URL unless deployment config changes.
- The Worker is currently a small manual router. Add routes consistently with `pathname` + `method` dispatch and shared CORS/JSON helpers.
- Worker persistence layering is intentional: D1 for relational metadata, KV for dashboard snapshots, R2 for binary attachments.

### Testing Rules

- Put Flutter tests under `test/` matching the source area: `test/controllers`, `test/services`, `test/models`, `test/utils`, or widget tests when UI behavior is involved.
- Prefer constructor injection and fake in-memory services in tests, following `HomeController` tests, instead of reaching for global state or network calls.
- Controller tests should pump after initialization or async state changes so timers/listeners settle before assertions.
- Add focused tests when changing school parsing, cache serialization, event mutation, attachment import/editing, grade metrics, or cloud restore precedence.
- Do not make tests depend on real Firebase, real TLU credentials, Cloudflare bindings, local device files, notifications, or wall-clock network availability.
- Worker currently has no automated test harness; for Worker changes, at minimum keep TypeScript strict compatibility and document manual verification such as `/health` or authenticated route checks.

### Code Quality & Style Rules

- Follow `flutter_lints`; do not silence lints broadly. Use targeted ignores only when platform or framework constraints require them.
- Keep files in the existing MVC layout: views in `lib/views`, controllers in `lib/controllers`, models in `lib/models`, services/infrastructure in `lib/services`, pure helpers in `lib/utils`.
- Name Dart files in `snake_case.dart`; name classes in `PascalCase`; keep private implementation details prefixed with `_`.
- Keep views focused on rendering and user interaction. Business logic belongs in controllers/services, not deeply inside widgets.
- Keep service responsibilities narrow: school API parsing in `SchoolApiService`, local cache in `LocalCacheService`, cloud calls in `CloudSyncService`, attachment persistence in `AttachmentStorageService`, device side effects in dedicated device services.
- Comments should explain non-obvious API quirks, sync ordering, platform constraints, or data-shape normalization; avoid comments that restate simple code.
- Avoid broad refactors in `HomeController` unless the task is specifically architectural. It is high-impact and coordinates cache, sync, auth, notifications, weather, widget updates, and event mutation.
- Keep Worker code formatted consistently with the existing style: double quotes, explicit helper functions, typed request bodies, and direct Cloudflare binding access through `env`.

### Development Workflow Rules

- Mobile setup: run `flutter pub get` after dependency changes.
- Mobile verification commands: `flutter analyze` and `flutter test`.
- Android run: `flutter run -d android`; Web run: `flutter run -d chrome`.
- Worker setup and commands run inside `cloudflare-worker/`: `npm install`, `npm run dev`, and `npm run deploy`.
- Worker schema setup uses `wrangler d1 execute sinhvien-db --local --file=./schema.sql`.
- Worker health can be checked with `GET /health`; authenticated routes require a valid Firebase ID token.
- If changing the Worker API contract, update both Flutter `CloudSyncService` and the Worker route handler in the same change.
- If changing Cloudflare bindings, keep `wrangler.toml`, docs, and runtime code aligned.

### Critical Don't-Miss Rules

- Do not break offline/local-only mode. Firebase, Cloudflare, notifications, and platform-specific features must fail softly where the existing app already tolerates them.
- Do not treat school sync credentials as Firebase credentials. These are separate auth domains and flows.
- Do not clear personal events/tasks unless intentionally switching to a different linked student or following existing controller behavior.
- Do not delete or mutate synced school events as if they were personal tasks; personal events are the editable/deletable user-owned records.
- Do not trust client-provided user identity in Worker routes. Identity must come from verified Firebase token `sub`.
- Do not query D1, KV, or R2 without scoping by Firebase UID or a UID-derived key.
- Do not upload/download attachment bytes without preserving the local-first attachment flow and remote key update semantics.
- Do not assume TLU API responses are stable. Keep defensive parsing, retries where present, and user-friendly `SchoolApiException` messages.
- Do not assume Cloudflare snapshot is always newer than local state. Preserve timestamp/version comparison and warning behavior around cloud restore.
- Do not hard-code a new Worker URL in random files; use the existing `CLOUDFLARE_WORKER_URL` compile-time define path.
- Do not introduce real network calls into tests.

---

## Usage Guidelines

**For AI Agents:**

- Read this file before implementing any code.
- Follow all rules exactly as documented.
- When in doubt, prefer the more restrictive option.
- Update this file if new patterns emerge.

**For Humans:**

- Keep this file lean and focused on agent needs.
- Update when the technology stack changes.
- Review periodically for outdated rules.
- Remove rules that become obvious over time.

Last Updated: 2026-04-10T00:00:00+07:00
