# sinhvien-app - Tong quan du an

**Last updated:** 2026-04-28  
**Repository type:** monorepo with 2 parts  
**Project type:** mobile client + backend serverless  
**Architecture:** feature-first Flutter app + Riverpod + Cloudflare Worker REST API

## Executive summary

`sinhvien-app` la ung dung ho tro sinh vien theo doi lich hoc, lich thi, diem,
chuong trinh dao tao, ghi chu va tep dinh kem trong mot UX local-first.

Repo co hai phan chinh:

- App Flutter o root, chiu trach nhiem UI chinh, cache cuc bo, dong bo du lieu
  truong, quan ly ghi chu va dong bo cloud.
- Cloudflare Worker o `cloudflare-worker/`, luu note, task, snapshot va file
  dinh kem bang REST API authenticated qua Firebase ID token.

## Project classification

- **Repository type:** monorepo
- **Main parts:** `mobile-app`, `worker-api`
- **Main languages:** Dart, TypeScript
- **Supporting languages:** Kotlin, SQL, JSON, TOML
- **Infrastructure:** Firebase Auth, Cloudflare Worker, D1, KV, R2, Open-Meteo,
  TLU education API

## Parts

### 1. mobile-app

- **Type:** `mobile`
- **Location:** `.`
- **Purpose:** Flutter client cho sinh vien xem lich, diem, dong bo du lieu
  truong, quan ly ghi chu, attachment va widget Android
- **Current stack:** Flutter 3, Dart 3, Riverpod, Firebase Core/Auth,
  Google Sign-In, SharedPreferences, local notifications
- **Entry point:** `lib/main.dart`

### 2. worker-api

- **Type:** `backend`
- **Location:** `cloudflare-worker/`
- **Purpose:** API serverless xac thuc Firebase token va luu du lieu ca nhan
  vao Cloudflare
- **Current stack:** Cloudflare Worker, TypeScript, `jose`, D1, KV, R2
- **Entry point:** `cloudflare-worker/src/index.ts`

## How the parts fit together

1. User dang nhap vao tab tai khoan tren app Flutter.
2. `SchoolApiService` lay profile, diem, lich hoc, lich thi va chuong trinh dao
   tao truc tiep tu TLU education API.
3. `HomeController` luu snapshot local truoc, cap nhat notification va Android
   widget, sau do phat dong cloud sync neu co Firebase user.
4. `CloudSyncService` gui Firebase ID token len Worker de luu note, task,
   attachment va dashboard snapshot.
5. Worker xac thuc token, ghi D1 cho metadata, dung KV cho snapshot nhanh va
   R2 cho file dinh kem.

## Technology snapshot

### mobile-app

| Area | Technology | Note |
| --- | --- | --- |
| UI | Flutter Material 3 | `lib/app.dart`, `lib/theme/app_theme.dart` |
| State | Riverpod Notifier + Provider | `HomeController`, `AccountAuthController` |
| Auth | Firebase Auth, Google Sign-In | Cloud sync la tuy chon |
| Local storage | SharedPreferences | Luu `LocalCachePayload` |
| Notifications | `flutter_local_notifications`, `timezone` | Android only |
| External APIs | TLU education API, Open-Meteo | Dong bo truong va weather |

### worker-api

| Area | Technology | Note |
| --- | --- | --- |
| Runtime | Cloudflare Worker | `src/index.ts` |
| Auth | `jose` + Firebase ID token verify | Dung Google JWKS |
| Database | Cloudflare D1 | users, notes, attachments, tasks, sync snapshots |
| Cache | Cloudflare KV | Dashboard snapshot theo TTL |
| File storage | Cloudflare R2 | PDF, DOC, image dinh kem |
| Infra config | Wrangler | `wrangler.toml` |

## Notable features

- Lich hoc va lich thi xep chung trong mot day strip ngay.
- Ghi chu va attachment gan vao tung event.
- Xem diem, chuong trinh dao tao va GPA planner.
- Dong bo du lieu truong ve local cache de su dung offline.
- Dong bo cloud cho note, task, attachment va dashboard snapshot.
- Notification cuc bo va Android home widget cho lich hom nay.

## Architecture highlights

- `HomeController` la orchestrator trung tam cua app, nhung lifecycle va
  ownership do Riverpod quan ly.
- `AccountAuthController` duoc cung cap qua `accountAuthControllerProvider`.
- App van local-first: loi cloud khong chan UX co ban.
- Worker tach rieng hoan toan kho luu tru cloud khoi client.
- Feature code da chuyen sang feature-first: `home`, `grades`, `auth`,
  `sync`, `attachments`, `weather`, `notifications`, `widget`.

## Documentation map

- [Project Standardization Mindmap](./project-standardization-mindmap.md)
- [Architecture - Mobile App](./architecture-mobile-app.md)
- [Architecture - Worker API](./architecture-worker-api.md)
- [Integration Architecture](./integration-architecture.md)

## Setup quick start

### mobile-app

```bash
flutter pub get
flutter run
```

### worker-api

```bash
cd cloudflare-worker
npm install
npm run dev
```

## Summary

`sinhvien-app` da chuyen sang huong feature-first + Riverpod o phan mobile,
co backend Cloudflare Worker rieng, va cac tai lieu chinh trong `docs/` da
duoc don lai de phuc vu codebase hien tai thay vi cac tai lieu MVC/scan cu.
